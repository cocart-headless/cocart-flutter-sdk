import 'http/response.dart';
import 'storage/storage_interface.dart';

/// Callback type for transforming API responses.
typedef ResponseTransformer = CoCartResponse Function(CoCartResponse response);

/// Configuration options for the [CoCart] client.
///
/// Mirrors every config key from the TS SDK's constructor options.
class CoCartOptions {
  // Guest
  String? cartKey;
  String? storageKey;

  // Basic Auth
  String? username;
  String? password;

  // JWT
  String? jwtToken;
  String? jwtRefreshToken;

  // Consumer Keys (Sessions API)
  String? consumerKey;
  String? consumerSecret;

  // HTTP
  Duration timeout;
  int maxRetries;

  // REST prefix / namespace
  String restPrefix;
  String namespace;

  // Plugin version target
  String mainPlugin;

  // Auth header override (proxy support)
  String authHeaderName;

  // Storage
  CoCartStorage? storage;
  String? encryptionKey;

  // Misc
  Map<String, String> extraHeaders;
  ResponseTransformer? responseTransformer;
  bool etag;
  bool debug;

  CoCartOptions({
    this.cartKey,
    this.storageKey = 'cocart_cart_key',
    this.username,
    this.password,
    this.jwtToken,
    this.jwtRefreshToken,
    this.consumerKey,
    this.consumerSecret,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 2,
    this.restPrefix = 'wp-json',
    this.namespace = 'cocart',
    this.mainPlugin = 'basic',
    this.authHeaderName = 'Authorization',
    this.storage,
    this.encryptionKey,
    Map<String, String>? extraHeaders,
    this.responseTransformer,
    this.etag = true,
    this.debug = false,
  }) : extraHeaders = extraHeaders ?? {};
}
