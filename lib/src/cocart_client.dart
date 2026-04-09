import 'auth/auth_manager.dart';
import 'cocart_options.dart';
import 'http/http_client.dart';
import 'http/response.dart';
import 'resources/cart_resource.dart';
import 'resources/jwt_resource.dart';
import 'resources/products_resource.dart';
import 'resources/sessions_resource.dart';
import 'storage/memory_storage.dart';
import 'storage/secure_storage.dart';
import 'storage/storage_interface.dart';

/// Main entry point for the CoCart SDK.
///
/// ```dart
/// final client = CoCart('https://your-store.com');
/// await client.restoreSession();
/// final cart = await client.cart().get();
/// ```
class CoCart {
  final String siteUrl;
  final CoCartOptions _options;
  late final CoCartHttpClient _http;
  late final AuthManager _auth;

  // --- Resources (mirrors TS client.cart(), client.products() pattern) ---

  CartResource cart() => CartResource(_http, _auth, _options);
  ProductsResource products() => ProductsResource(_http, _options);
  SessionsResource sessions() => SessionsResource(_http, _auth);
  JwtResource jwt() => JwtResource(_http, _auth);

  CoCart(this.siteUrl, [CoCartOptions? options])
      : _options = options ?? CoCartOptions() {
    _auth = AuthManager(_options, _buildStorage());
    _http = CoCartHttpClient(siteUrl, _options, _auth);
  }

  // --- Guest session ---

  String? getCartKey() => _auth.cartKey;
  Future<void> restoreSession() => _auth.restoreSession();
  Future<void> clearSession() => _auth.clearSession();

  // --- Auth setters (mirror TS runtime switching) ---

  CoCart setAuth(String identifier, String password) {
    _auth.setBasicAuth(identifier, password);
    return this;
  }

  CoCart setJwtToken(String token) {
    _auth.setJwtToken(token);
    return this;
  }

  CoCart setRefreshToken(String token) {
    _auth.setRefreshToken(token);
    return this;
  }

  bool isAuthenticated() => _auth.isAuthenticated;
  bool isGuest() => _auth.isGuest;

  // --- Fluent config setters ---

  CoCart setTimeout(int ms) {
    _options.timeout = Duration(milliseconds: ms);
    return this;
  }

  CoCart setMaxRetries(int n) {
    _options.maxRetries = n;
    return this;
  }

  CoCart setRestPrefix(String p) {
    _options.restPrefix = p;
    return this;
  }

  CoCart setNamespace(String n) {
    _options.namespace = n;
    return this;
  }

  CoCart addHeader(String key, String value) {
    _options.extraHeaders[key] = value;
    return this;
  }

  CoCart setAuthHeaderName(String name) {
    _options.authHeaderName = name;
    return this;
  }

  CoCart setETag(bool enabled) {
    _options.etag = enabled;
    return this;
  }

  CoCart setMainPlugin(String plugin) {
    _options.mainPlugin = plugin;
    return this;
  }

  CoCart setDebug(bool enabled) {
    _options.debug = enabled;
    return this;
  }

  // --- Events (mirrors client.on()) ---

  void on(String event, Function handler) => _http.on(event, handler);

  // --- ETag cache ---

  void clearETagCache() => _http.clearETagCache();

  // --- Shorthand login/logout (mirrors TS) ---

  Future<CoCartResponse> login(String identifier, String password) =>
      jwt().login(identifier, password);

  Future<void> logout() => jwt().logout();

  // --- Factory constructor (mirrors CoCart.create()) ---

  static CoCart create(String siteUrl, [CoCartOptions? options]) =>
      CoCart(siteUrl, options);

  // --- Cleanup ---

  void close() => _http.close();

  CoCartStorage _buildStorage() {
    if (_options.storage != null) return _options.storage!;
    try {
      return SecureStorage(_options.encryptionKey);
    } catch (_) {
      // Fallback for non-Flutter environments (e.g. pure Dart, tests)
      return MemoryStorage();
    }
  }
}
