import 'dart:convert';

import '../cocart_options.dart';
import '../storage/storage_interface.dart';

/// Authentication modes in priority order (mirrors TS SDK).
enum AuthMode { guest, basicAuth, jwt, consumerKeys }

/// Manages authentication state and header building.
///
/// Implements the TS SDK's priority: JWT > Basic > Consumer Keys > Guest.
class AuthManager {
  AuthMode _mode = AuthMode.guest;
  String? _cartKey;

  String? _username;
  String? _password;
  String? _jwtToken;
  String? _refreshToken;
  String? _consumerKey;
  String? _consumerSecret;

  final CoCartOptions _options;
  final CoCartStorage _storage;

  AuthManager(this._options, this._storage) {
    _cartKey = _options.cartKey;
    _consumerKey = _options.consumerKey;
    _consumerSecret = _options.consumerSecret;

    if (_options.jwtToken != null) {
      _jwtToken = _options.jwtToken;
      _refreshToken = _options.jwtRefreshToken;
      _mode = AuthMode.jwt;
    } else if (_options.username != null) {
      _username = _options.username;
      _password = _options.password;
      _mode = AuthMode.basicAuth;
    } else if (_options.consumerKey != null) {
      _mode = AuthMode.consumerKeys;
    }
  }

  bool get isAuthenticated => _mode != AuthMode.guest;
  bool get isGuest => _mode == AuthMode.guest;
  AuthMode get mode => _mode;

  /// Returns the cart key only for guest sessions.
  String? get cartKey => _mode == AuthMode.guest ? _cartKey : null;

  String? get jwtToken => _jwtToken;
  String? get refreshToken => _refreshToken;

  /// Builds the auth header value for the current mode.
  String? buildAuthHeader() {
    switch (_mode) {
      case AuthMode.jwt:
        return 'Bearer $_jwtToken';
      case AuthMode.basicAuth:
        final encoded = base64Encode(utf8.encode('$_username:$_password'));
        return 'Basic $encoded';
      case AuthMode.consumerKeys:
        final encoded =
            base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'));
        return 'Basic $encoded';
      case AuthMode.guest:
        return null;
    }
  }

  /// Sets Basic Auth credentials and clears JWT (mirrors TS runtime switching).
  void setBasicAuth(String identifier, String password) {
    _username = identifier;
    _password = password;
    _jwtToken = null;
    _refreshToken = null;
    _mode = AuthMode.basicAuth;
  }

  /// Sets JWT token and clears Basic Auth (mirrors TS runtime switching).
  void setJwtToken(String token) {
    _jwtToken = token;
    _username = null;
    _password = null;
    _mode = AuthMode.jwt;
  }

  void setRefreshToken(String token) => _refreshToken = token;

  /// Called by HttpClient after every cart response to capture the cart key.
  void captureCartKey(
      Map<String, dynamic> body, Map<String, String> headers) {
    if (_mode != AuthMode.guest) return;

    final key = body['cart_key'] as String? ??
        headers['cart-key'] ??
        headers['x-cocart-api'];

    if (key != null && key != _cartKey) {
      _cartKey = key;
      final storageKey = _options.storageKey;
      if (storageKey != null) {
        _storage.write(storageKey, key);
      }
    }
  }

  /// Restores a previous guest session from storage.
  Future<void> restoreSession() async {
    if (_cartKey == null) {
      final storageKey = _options.storageKey;
      if (storageKey != null) {
        _cartKey = await _storage.read(storageKey);
      }
    }
  }

  /// Clears all auth state and stored session data.
  Future<void> clearSession() async {
    _cartKey = null;
    _jwtToken = null;
    _refreshToken = null;
    _username = null;
    _password = null;
    _mode = AuthMode.guest;
    final storageKey = _options.storageKey;
    if (storageKey != null) {
      await _storage.delete(storageKey);
    }
  }
}
