# Configuration & Setup

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  cocart: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Configuration Options

```dart
final client = CoCart('https://your-store.com', CoCartOptions(
  // Guest session
  cartKey: null,                    // Pre-seed a known cart key
  storageKey: 'cocart_cart_key',    // Key used in secure storage

  // Basic Auth
  username: null,                   // WordPress username or email
  password: null,                   // WordPress password

  // JWT Auth
  jwtToken: null,                   // Pre-set JWT token
  jwtRefreshToken: null,            // Pre-set refresh token

  // Consumer Keys (admin / Sessions API)
  consumerKey: null,                // WooCommerce consumer key (ck_...)
  consumerSecret: null,             // WooCommerce consumer secret (cs_...)

  // HTTP
  timeout: Duration(seconds: 30),   // Request timeout
  maxRetries: 2,                    // Retry count on network failure

  // REST prefix / namespace
  restPrefix: 'wp-json',            // WordPress REST prefix
  namespace: 'cocart',              // CoCart namespace

  // Plugin version target
  mainPlugin: 'basic',              // 'basic' (default) or 'legacy'

  // Auth header override (proxy support)
  authHeaderName: 'Authorization',  // Custom auth header name

  // Storage
  storage: null,                    // Custom CoCartStorage implementation
  encryptionKey: null,              // Encryption key for secure storage

  // Misc
  extraHeaders: {},                 // Additional HTTP headers
  responseTransformer: null,        // Transform responses before returning
  etag: true,                       // Enable ETag conditional requests
  debug: false,                     // Print debug logs
));
```

## Fluent Configuration

All config options can also be set at runtime using fluent setters that return `this` for chaining:

```dart
final client = CoCart.create('https://your-store.com')
    .setTimeout(15000)
    .setMaxRetries(3)
    .setRestPrefix('wp-json')
    .setNamespace('cocart')
    .addHeader('X-Custom', 'value')
    .setAuthHeaderName('X-Auth-Token')
    .setETag(true)
    .setMainPlugin('basic')
    .setDebug(true);
```

### Available Setters

| Method | Description |
|---|---|
| `setTimeout(int ms)` | Set request timeout in milliseconds |
| `setMaxRetries(int n)` | Set retry count on network failure |
| `setRestPrefix(String prefix)` | Set WordPress REST prefix |
| `setNamespace(String ns)` | Set CoCart namespace |
| `addHeader(String key, String value)` | Add a custom HTTP header |
| `setAuthHeaderName(String name)` | Override the auth header name |
| `setETag(bool enabled)` | Enable or disable ETag caching |
| `setMainPlugin(String plugin)` | Set target plugin version |
| `setDebug(bool enabled)` | Enable or disable debug logging |

## White-Labelling / Custom REST Prefix

If your store uses a custom REST prefix or white-labelled namespace:

```dart
// Custom REST prefix
final client = CoCart('https://your-store.com',
    CoCartOptions(restPrefix: 'api'));

// White-labelled namespace
final client = CoCart('https://your-store.com',
    CoCartOptions(namespace: 'my-brand'));

// Both together — requests go to: /api/my-brand/v2/...
final client = CoCart('https://your-store.com',
    CoCartOptions(restPrefix: 'api', namespace: 'my-brand'));
```

## Legacy Plugin Support

If your store runs the older CoCart plugin (before CoCart Basic):

```dart
final client = CoCart('https://your-store.com',
    CoCartOptions(mainPlugin: 'legacy'));
```

### Behavior differences in legacy mode

- Methods that require CoCart Basic (e.g. `products().findBySlug()`) throw a `VersionError`
- Field filtering uses `fields` instead of `_fields`

```dart
// Throws VersionError in legacy mode
try {
  await client.products().findBySlug('my-product');
} on VersionError catch (e) {
  print(e); // "findBySlug requires CoCart Basic — not available in legacy mode"
}
```

## Custom Storage

By default, the SDK uses `flutter_secure_storage` for persisting cart keys and tokens. You can provide a custom storage implementation:

```dart
class MyCustomStorage implements CoCartStorage {
  @override
  Future<String?> read(String key) async { /* ... */ }

  @override
  Future<void> write(String key, String value) async { /* ... */ }

  @override
  Future<void> delete(String key) async { /* ... */ }
}

final client = CoCart('https://your-store.com',
    CoCartOptions(storage: MyCustomStorage()));
```

For testing, use the built-in `MemoryStorage`:

```dart
final client = CoCart('https://your-store.com',
    CoCartOptions(storage: MemoryStorage()));
```
