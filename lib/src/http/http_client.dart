import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../auth/auth_manager.dart';
import '../cocart_options.dart';
import '../errors/auth_exception.dart';
import '../errors/cocart_exception.dart';
import '../errors/network_exception.dart';
import '../errors/rate_limit_exception.dart';
import '../errors/two_factor_auth_required_exception.dart';
import '../errors/validation_error.dart';
import 'response.dart';

/// A cached GET response: the ETag that produced it, plus the body/headers
/// to serve back whenever the server later responds `304 Not Modified`.
class _CachedETagEntry {
  final String etag;
  final Map<String, dynamic> body;
  final Map<String, String> headers;

  const _CachedETagEntry(this.etag, this.body, this.headers);
}

/// HTTP client wrapping the `http` package with retries, ETag, and events.
///
/// Mirrors the TS SDK's fetch wrapper.
class CoCartHttpClient {
  final String _siteUrl;
  final CoCartOptions _options;
  final AuthManager _auth;
  final http.Client _client;

  final Map<String, List<Function>> _listeners = {};
  final Map<String, _CachedETagEntry> _etagCache = {};
  final Map<String, Future<CoCartResponse>> _inFlightGetRequests = {};
  final math.Random _random = math.Random();

  CoCartHttpClient(this._siteUrl, this._options, this._auth,
      [http.Client? client])
      : _client = client ?? http.Client();

  /// Registers an event listener. Events: `request`, `response`, `error`.
  void on(String event, Function handler) {
    _listeners.putIfAbsent(event, () => []).add(handler);
  }

  void _emit(String event, Map<String, dynamic> data) {
    final handlers = _listeners[event];
    if (handlers != null) {
      for (final handler in handlers) {
        handler(data);
      }
    }
  }

  /// Builds the full URL for a namespaced endpoint.
  Uri _buildUrl(String endpoint, {Map<String, String>? queryParams}) {
    final base = _siteUrl.replaceAll(RegExp(r'/+$'), '');
    final prefix = _options.restPrefix;
    final ns = _options.namespace;
    final path = '$base/$prefix/$ns/v2/$endpoint';

    final params = <String, String>{};
    if (queryParams != null) params.addAll(queryParams);

    // Append cart key for guest sessions
    final cartKey = _auth.cartKey;
    if (cartKey != null) {
      params['cart_key'] = cartKey;
    }

    return Uri.parse(path)
        .replace(queryParameters: params.isNotEmpty ? params : null);
  }

  /// Builds a URL for raw (non-namespaced) endpoints like JWT routes.
  Uri _buildRawUrl(String endpoint, {Map<String, String>? queryParams}) {
    final base = _siteUrl.replaceAll(RegExp(r'/+$'), '');
    final prefix = _options.restPrefix;
    final path = '$base/$prefix/$endpoint';
    return Uri.parse(path).replace(
        queryParameters:
            queryParams?.isNotEmpty == true ? queryParams : null);
  }

  Map<String, String> _buildHeaders({bool isJson = true}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      ..._options.extraHeaders,
    };

    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }

    final authHeader = _auth.buildAuthHeader();
    if (authHeader != null) {
      headers[_options.authHeaderName] = authHeader;
    }

    // Cart key header — send only the header name the configured plugin
    // actually recognizes, not both.
    final cartKey = _auth.cartKey;
    if (cartKey != null) {
      final cartKeyHeader =
          _options.mainPlugin == 'legacy' ? 'CoCart-API-Cart-Key' : 'Cart-Key';
      headers[cartKeyHeader] = cartKey;
    }

    return headers;
  }

  Future<CoCartResponse> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    final url = _buildUrl(endpoint, queryParams: queryParams);
    return _request('GET', url);
  }

  Future<CoCartResponse> post(String endpoint,
      {Map<String, dynamic>? body, Map<String, String>? queryParams}) async {
    final url = _buildUrl(endpoint, queryParams: queryParams);
    return _request('POST', url, body: body);
  }

  Future<CoCartResponse> delete(String endpoint,
      {Map<String, String>? queryParams}) async {
    final url = _buildUrl(endpoint, queryParams: queryParams);
    return _request('DELETE', url);
  }

  /// GET from a raw (non-namespaced) endpoint (e.g. account routes).
  Future<CoCartResponse> getRaw(String endpoint,
      {Map<String, String>? queryParams}) async {
    final url = _buildRawUrl(endpoint, queryParams: queryParams);
    return _request('GET', url);
  }

  /// POST to a raw (non-namespaced) endpoint (e.g. JWT routes).
  Future<CoCartResponse> postRaw(String endpoint,
      {Map<String, dynamic>? body}) async {
    final url = _buildRawUrl(endpoint);
    return _request('POST', url, body: body);
  }

  /// Dispatch multiple sub-requests in a single call via `{namespace}/batch`
  /// (requires CoCart Plus). Each request is `{method, path, body?}`.
  Future<CoCartResponse> batch(List<Map<String, dynamic>> requests) async {
    if (requests.isEmpty) {
      throw const ValidationError('batch() requires at least one request.');
    }

    try {
      return await postRaw('${_options.namespace}/batch',
          body: {'requests': requests});
    } on CoCartException catch (e) {
      if (e.data?['code'] == 'rest_no_route') {
        throw const CoCartException(
          'This method is only available with another CoCart plugin. '
          'Please ask support for assistance!',
          statusCode: 404,
        );
      }
      rethrow;
    }
  }

  /// Coalesces concurrent identical GET requests (same built URL) into a
  /// single shared in-flight future so simultaneous callers share one
  /// network round trip.
  Future<CoCartResponse> _request(String method, Uri url,
      {Map<String, dynamic>? body}) {
    if (method != 'GET') {
      return _performRequest(method, url, body: body);
    }

    final key = url.toString();
    final inFlight = _inFlightGetRequests[key];
    if (inFlight != null) {
      return inFlight;
    }

    final future = _performRequest(method, url, body: body);
    _inFlightGetRequests[key] = future;
    // whenComplete() returns a *new* derived future; the caller only ever
    // awaits `future` itself, so if the request fails this derived future's
    // rejection would otherwise go unobserved and surface as an unrelated
    // top-level unhandled error. ignore() marks that intentional.
    future
        .whenComplete(() => _inFlightGetRequests.remove(key))
        .ignore();
    return future;
  }

  Future<CoCartResponse> _performRequest(String method, Uri url,
      {Map<String, dynamic>? body}) async {
    final headers = _buildHeaders();

    // ETag support
    if (_options.etag && method == 'GET') {
      final cached = _etagCache[url.toString()];
      if (cached != null) {
        headers['If-None-Match'] = cached.etag;
      }
    }

    _emit('request', {'method': method, 'url': url.toString()});

    final stopwatch = Stopwatch()..start();
    int attempt = 0;
    final maxAttempts = _options.maxRetries + 1;

    while (attempt < maxAttempts) {
      attempt++;
      try {
        final http.Response response;

        switch (method) {
          case 'GET':
            response = await _client
                .get(url, headers: headers)
                .timeout(_options.timeout);
          case 'POST':
            response = await _client
                .post(url,
                    headers: headers,
                    body: body != null ? jsonEncode(body) : null)
                .timeout(_options.timeout);
          case 'DELETE':
            response = await _client
                .delete(url, headers: headers)
                .timeout(_options.timeout);
          default:
            throw CoCartException('Unsupported HTTP method: $method');
        }

        stopwatch.stop();

        // Handle 304 Not Modified — serve back the body/headers cached
        // alongside the ETag that produced the match, since a 304 has no
        // body of its own. Falls back to an empty response if we somehow
        // have no cache entry for this URL.
        if (response.statusCode == 304) {
          final cached = _etagCache[url.toString()];
          final result = CoCartResponse(
              cached?.body ?? {}, cached?.headers ?? response.headers, 304);
          _emit('response', {
            'status': 304,
            'duration': stopwatch.elapsedMilliseconds,
          });
          return result;
        }

        // Handle rate limiting
        if (response.statusCode == 429) {
          final retryAfterStr = response.headers['retry-after'];
          final retryAfter = retryAfterStr != null
              ? Duration(seconds: int.tryParse(retryAfterStr) ?? 60)
              : null;
          throw RateLimitException(
            'Rate limit exceeded',
            retryAfter: retryAfter,
            statusCode: 429,
          );
        }

        final Map<String, dynamic> data;
        if (response.body.isNotEmpty) {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } else {
          data = {};
        }

        // Handle error responses
        if (response.statusCode >= 400) {
          final message = data['message'] as String? ?? 'Request failed';
          final code = data['code'] as String?;

          if (response.statusCode == 401 && code == 'cocart_2fa_required') {
            final inner = (data['data'] is Map<String, dynamic>
                    ? data['data'] as Map<String, dynamic>
                    : data);
            final providers = (inner['available_providers'] as List?)
                    ?.cast<String>() ??
                [];
            throw TwoFactorAuthRequiredException(
              message,
              statusCode: 401,
              data: data,
              availableProviders: providers,
              defaultProvider: inner['default_provider'] as String?,
              emailSent: inner['email_sent'] as bool? ?? false,
            );
          }

          if (response.statusCode == 401 || response.statusCode == 403) {
            throw AuthException(message, statusCode: response.statusCode, data: data);
          }

          throw CoCartException(
            message,
            statusCode: response.statusCode,
            data: data,
          );
        }

        // Cache the ETag + body together from a fresh (non-304) GET so a
        // later 304 can be resolved to real data instead of an empty body.
        if (_options.etag && method == 'GET') {
          final etag = response.headers['etag'];
          if (etag != null) {
            _etagCache[url.toString()] =
                _CachedETagEntry(etag, data, response.headers);
          }
        }

        // Capture cart key from response
        _auth.captureCartKey(data, response.headers);

        final result = CoCartResponse(
            data, response.headers, response.statusCode);

        // Apply response transformer if configured
        final transformed = _options.responseTransformer != null
            ? _options.responseTransformer!(result)
            : result;

        _emit('response', {
          'status': response.statusCode,
          'duration': stopwatch.elapsedMilliseconds,
        });

        if (_options.debug) {
          // ignore: avoid_print
          print('[CoCart] $method ${url.toString()} → ${response.statusCode} '
              '(${stopwatch.elapsedMilliseconds}ms)');
        }

        return transformed;
      } on CoCartException {
        rethrow;
      } catch (e) {
        if (attempt >= maxAttempts) {
          _emit('error', {'error': e.toString()});
          throw NetworkException(
              'Request failed after $maxAttempts attempts: $e');
        }
        // Retry after an exponential backoff delay (with jitter), honoring
        // a Retry-After header when one is available.
        final delay = _retryDelay(attempt);
        if (_options.debug) {
          // ignore: avoid_print
          print('[CoCart] Retry $attempt/$maxAttempts '
              'for $method ${url.toString()} after ${delay.inMilliseconds}ms');
        }
        await Future.delayed(delay);
      }
    }

    throw const NetworkException('Request failed');
  }

  /// Computes the delay before the next retry attempt: exponential backoff
  /// (`min(2^(attempt-1), 30)` seconds, or the `Retry-After` value when
  /// present) with ±20% jitter applied on top, so many clients retrying at
  /// once don't re-collide on the same schedule.
  Duration _retryDelay(int attempt, [http.Response? response]) {
    double baseMs;

    final retryAfterStr = response?.headers['retry-after'];
    final retryAfterSeconds =
        retryAfterStr != null ? int.tryParse(retryAfterStr) : null;
    if (retryAfterSeconds != null) {
      baseMs = math.min(retryAfterSeconds, 60).toDouble() * 1000;
    } else {
      baseMs = math.min(math.pow(2, attempt - 1).toDouble(), 30.0) * 1000;
    }

    final jitter = 0.8 + _random.nextDouble() * 0.4;
    return Duration(milliseconds: (baseMs * jitter).round());
  }

  /// Clears the ETag cache.
  void clearETagCache() => _etagCache.clear();

  /// Closes the underlying HTTP client.
  void close() => _client.close();
}
