import 'dart:convert';

import '../auth/auth_manager.dart';
import '../errors/auth_exception.dart';
import '../http/http_client.dart';
import '../http/response.dart';

/// JWT resource — accessed via `client.jwt()`.
///
/// Handles JWT login, refresh, validate, and auto-refresh logic.
class JwtResource {
  final CoCartHttpClient _http;
  final AuthManager _auth;
  bool _autoRefresh = false;

  JwtResource(this._http, this._auth);

  Future<CoCartResponse> login(String identifier, String password) async {
    final response = await _http.postRaw('cocart/jwt/token', body: {
      'username': identifier,
      'password': password,
    });
    final token = response.get('token') as String?;
    final refresh = response.get('refresh_token') as String?;
    if (token == null) {
      throw const AuthException('JWT login failed — no token returned');
    }
    _auth.setJwtToken(token);
    if (refresh != null) _auth.setRefreshToken(refresh);
    return response;
  }

  Future<void> logout() async {
    await _http.postRaw('cocart/jwt/logout');
    await _auth.clearSession();
  }

  Future<CoCartResponse> refresh() async {
    final rt = _auth.refreshToken;
    if (rt == null) {
      throw const AuthException('No refresh token available');
    }
    final response = await _http.postRaw('cocart/jwt/refresh-token',
        body: {'refresh_token': rt});
    final token = response.get('token') as String?;
    if (token != null) _auth.setJwtToken(token);
    return response;
  }

  Future<bool> validate() async {
    try {
      final response = await _http.postRaw('cocart/jwt/validate-token');
      return response.get('data.status') == 200;
    } catch (_) {
      return false;
    }
  }

  bool isTokenExpired([int leewaySeconds = 30]) {
    final expiry = getTokenExpiry();
    if (expiry == null) return true;
    return DateTime.now().millisecondsSinceEpoch / 1000 >
        expiry - leewaySeconds;
  }

  int? getTokenExpiry() {
    final token = _auth.jwtToken;
    if (token == null) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
    return payload['exp'] as int?;
  }

  bool hasTokens() => _auth.jwtToken != null;

  void setAutoRefresh(bool enabled) => _autoRefresh = enabled;

  bool isAutoRefreshEnabled() => _autoRefresh;

  /// Wraps an operation with automatic token refresh on expiry.
  Future<T> withAutoRefresh<T>(
      Future<T> Function() callback) async {
    if (isTokenExpired()) await refresh();
    return callback();
  }

  /// Restores JWT tokens from storage (if stored).
  Future<void> restoreTokensFromStorage() async {
    await _auth.restoreSession();
  }
}
