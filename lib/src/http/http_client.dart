import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_manager.dart';
import '../cocart_options.dart';
import '../errors/cocart_exception.dart';
import '../errors/network_exception.dart';
import '../errors/rate_limit_exception.dart';
import 'response.dart';

/// HTTP client wrapping the `http` package with retries, ETag, and events.
///
/// Mirrors the TS SDK's fetch wrapper.
class CoCartHttpClient {
  final String _siteUrl;
  final CoCartOptions _options;
  final AuthManager _auth;
  final http.Client _client;

  final Map<String, List<Function>> _listeners = {};
  final Map<String, String> _etagCache = {};

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

    return Uri.parse(path).replace(queryParameters: params.isNotEmpty ? params : null);
  }

  /// Builds a URL for raw (non-namespaced) endpoints like JWT routes.
  Uri _buildRawUrl(String endpoint, {Map<String, String>? queryParams}) {
    final base = _siteUrl.replaceAll(RegExp(r'/+$'), '');
    final prefix = _options.restPrefix;
    final path = '$base/$prefix/$endpoint';
    return Uri.parse(path)
        .replace(queryParameters: queryParams?.isNotEmpty == true ? queryParams : null);
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

  /// POST to a raw (non-namespaced) endpoint (e.g. JWT routes).
  Future<CoCartResponse> postRaw(String endpoint,
      {Map<String, dynamic>? body}) async {
    final url = _buildRawUrl(endpoint);
    return _request('POST', url, body: body);
  }

  Future<CoCartResponse> _request(String method, Uri url,
      {Map<String, dynamic>? body}) async {
    final headers = _buildHeaders();

    // ETag support
    if (_options.etag && method == 'GET') {
      final cached = _etagCache[url.toString()];
      if (cached != null) {
        headers['If-None-Match'] = cached;
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

        // Store ETag from response
        if (_options.etag) {
          final etag = response.headers['etag'];
          if (etag != null) {
            _etagCache[url.toString()] = etag;
          }
        }

        // Handle 304 Not Modified
        if (response.statusCode == 304) {
          final result = CoCartResponse({}, response.headers, 304);
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
          final message =
              data['message'] as String? ?? 'Request failed';
          throw CoCartException(
            message,
            statusCode: response.statusCode,
            data: data,
          );
        }

        // Capture cart key from response
        _auth.captureCartKey(data, response.headers);

        final result = CoCartResponse(data, response.headers, response.statusCode);

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
          throw NetworkException('Request failed after $maxAttempts attempts: $e');
        }
        // Retry
        if (_options.debug) {
          // ignore: avoid_print
          print('[CoCart] Retry $attempt/$maxAttempts for $method ${url.toString()}');
        }
      }
    }

    throw const NetworkException('Request failed');
  }

  /// Clears the ETag cache.
  void clearETagCache() => _etagCache.clear();

  /// Closes the underlying HTTP client.
  void close() => _client.close();
}
