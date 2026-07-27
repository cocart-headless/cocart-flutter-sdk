# CoCart Flutter SDK — Developer Plan

> Based on the actual `@cocartheadless/sdk` TypeScript SDK (`cocart-headless/cocart-js`), adapted faithfully to Dart/Flutter conventions.

---

## 1. Overview

| Item | Detail |
|---|---|
| Package name | `cocart` |
| Language | Dart 3 / Flutter |
| Min Dart SDK | `>=3.0.0` |
| Min Flutter | `>=3.10.0` |
| Distribution | pub.dev |
| HTTP | `http` package (native `fetch` equivalent) |
| Storage | `flutter_secure_storage` (mirrors `EncryptedStorage`) |
| Auth | Guest (cart key), Basic Auth, JWT with auto-refresh, Consumer Keys |

---

## 2. What the TS SDK Does (That Must Be Replicated)

Before the directory structure, here is every meaningful feature found in the real SDK:

### Client construction
```typescript
// TS
const client = new CoCart('https://your-store.com', { ...options });
const client = new CoCart('https://your-store.com')
  .setTimeout(15000)
  .setMaxRetries(2)
  .addHeader('X-Custom', 'value');
```
→ Dart needs `CoCart` class with a named-options constructor **and** fluent setters that return `this`.

### Authentication modes (priority order)
1. **JWT token** → `Authorization: Bearer <token>`
2. **Basic Auth** → `Authorization: Basic base64(username:password)`
3. **Consumer Keys** → `Authorization: Basic base64(ck:cs)` (admin/Sessions API only)
4. **Guest** → no auth header; `Cart-Key` query param on cart routes

### Guest session management
- First request creates a session; server returns `Cart-Key` in response
- SDK captures it automatically from response headers/body
- Stored in `localStorage` (TS) → `flutter_secure_storage` (Dart)
- Restored via `client.restoreSession()` on app start
- Pre-seeded via `cartKey` config option
- `client.getCartKey()` exposes the active key

### Customer auth — Basic Auth
```typescript
const client = new CoCart('https://your-store.com', {
  username: 'email@example.com',
  password: 'password',
});
// or at runtime:
client.setAuth('email@example.com', 'password');
client.isAuthenticated(); // true
client.isGuest();         // false
```

### JWT auth
```typescript
await client.login('email@example.com', 'password'); // calls JWT plugin
await client.logout();
await client.jwt().refresh();
await client.jwt().validate();
client.jwt().isTokenExpired(300); // with leeway
client.jwt().getTokenExpiry();
client.jwt().setAutoRefresh(true);
client.jwt().hasTokens();
client.setJwtToken('eyJ...');
client.setRefreshToken('refresh...');
```

### Auth header name override (proxy support)
```typescript
const client = new CoCart('https://your-store.com', {
  authHeaderName: 'X-Auth-Token', // default: 'Authorization'
});
```

### Config options
```typescript
{
  cartKey, username, password, jwtToken, jwtRefreshToken,
  consumerKey, consumerSecret,
  timeout, restPrefix, namespace, mainPlugin,
  maxRetries, storage, storageKey, encryptionKey,
  authHeaderName, responseTransformer, etag, debug
}
```

### Fluent config setters
`setTimeout`, `setMaxRetries`, `setRestPrefix`, `setNamespace`, `addHeader`, `setAuthHeaderName`, `setETag`, `setMainPlugin`, `setDebug`

### Cart resource — `client.cart()`
```typescript
.create()
.get(params?)
.getFiltered(['items','totals'])   // type-safe field filtering
.addItem(id, qty, options?)
.add(id, qty)                      // alias
.addVariation(id, qty, attributes)
.addItems([...])                   // bulk
.updateItem(itemKey, qty, options?)
.updateItems({key:qty} or [...])   // bulk
.removeItem(itemKey)
.removeItems([...])                // bulk
.restoreItem(itemKey)
.getRemovedItems()
.clear() / .empty()
.calculate()
.update(data)
.getTotals(formatted?)
.getItemCount()
.getItems()
.getItem(itemKey)
.applyCoupon(code)                 // CoCart Plus
.removeCoupon(code)                // CoCart Plus
.getCoupons()                      // CoCart Plus
.checkCoupons()                    // CoCart Plus
.updateCustomer(billing, shipping?)
.getCustomer()
.getShippingMethods()
.setShippingMethod(method)         // CoCart Plus
.calculateShipping(address)
.getFees()                         // CoCart Plus
.addFee(name, amount, taxable?)    // CoCart Plus
.removeFees()                      // CoCart Plus
.getCrossSells()
```

### Products resource — `client.products()`
```typescript
.all(filters?)
.find(id)
.findBySlug(slug)      // CoCart Basic only
.variation(id, varId)
.category(slug)
.tag(slug)
.brands() / .brand(slug) / .byBrand(slug)
.myReviews()
// + attribute methods
```

### Sessions resource — `client.sessions()` (admin/consumer keys)
```typescript
.all()
```

### JWT resource — `client.jwt()`
```typescript
.login(username, password)
.refresh()
.validate()
.isTokenExpired(leeway?)
.getTokenExpiry()
.setAutoRefresh(bool)
.isAutoRefreshEnabled()
.hasTokens()
.restoreTokensFromStorage()
.withAutoRefresh(callback)
```

### Response object
Every method returns a `Response` wrapping the raw JSON with:
```typescript
.get('totals.total')       // dot-notation access
.has('totals.discount')    // key existence check
.getItems()
.getTotals()
.getItemCount()
.getCartKey()              // from response headers
.getCartHash()
.getNotices()
.getCurrency()
.getCacheStatus()          // 'HIT' | 'MISS' | 'SKIP'
.isNotModified()           // ETag 304
.toObject()
.toJson()
```

### Validation
```typescript
validateProductId(id)   // throws ValidationError if invalid
validateQuantity(qty)
validateEmail(email)
// SDK throws before making any network request
```

### Client-side input validation (pre-request)
Caught before HTTP — `addItem(-1, 0)` throws `ValidationError` immediately.

### ETag / conditional requests
- Enabled by default
- Sends `If-None-Match` automatically on repeat requests
- `client.setETag(false)` to disable
- `client.clearETagCache()`

### Event system
```typescript
client.on('request', handler)
client.on('response', handler)
client.on('error', handler)
```

### Legacy plugin mode
`mainPlugin: 'legacy'` — Basic-only methods throw `VersionError`; field filter param switches from `_fields` to `fields`.

### Currency formatter
```typescript
const fmt = new CurrencyFormatter();
fmt.format(4599, currency);        // "$45.99"
fmt.formatDecimal(4599, currency);
```

### Clear / switch session
```typescript
client.clearSession()   // clears cart key + tokens
client.setAuth(u, p)    // clears JWT
client.setJwtToken(t)   // clears Basic Auth
```

---

## 3. Directory Structure

```
cocart/
├── lib/
│   ├── cocart.dart                         # Barrel export
│   └── src/
│       ├── cocart_client.dart              # CoCart — main entry point
│       ├── cocart_options.dart             # CoCartOptions (config object)
│       ├── auth/
│       │   ├── auth_manager.dart           # Priority logic, header building
│       │   ├── guest_session.dart          # Cart key capture + secure storage
│       │   └── jwt_manager.dart            # JWT login, refresh, validate, auto-refresh
│       ├── http/
│       │   ├── http_client.dart            # fetch wrapper, retries, ETag, events
│       │   └── response.dart               # Response wrapper + dot-notation .get()
│       ├── models/
│       │   ├── cart.dart
│       │   ├── cart_item.dart
│       │   ├── cart_totals.dart
│       │   ├── currency.dart
│       │   ├── product.dart
│       │   ├── product_variation.dart
│       │   └── jwt_token.dart
│       ├── resources/
│       │   ├── cart_resource.dart          # client.cart()
│       │   ├── products_resource.dart      # client.products()
│       │   ├── sessions_resource.dart      # client.sessions()
│       │   └── jwt_resource.dart           # client.jwt()
│       ├── storage/
│       │   ├── storage_interface.dart      # Abstract CoCartStorage
│       │   ├── secure_storage.dart         # flutter_secure_storage (default)
│       │   └── memory_storage.dart         # In-memory (tests / server-side)
│       ├── validation/
│       │   └── validators.dart             # validateProductId, validateQuantity, validateEmail
│       ├── utilities/
│       │   └── currency_formatter.dart     # CurrencyFormatter
│       └── errors/
│           ├── cocart_exception.dart       # Base
│           ├── auth_exception.dart
│           ├── validation_error.dart
│           ├── version_error.dart
│           ├── network_exception.dart
│           └── rate_limit_exception.dart
├── test/
│   ├── auth/
│   │   ├── guest_session_test.dart
│   │   └── jwt_manager_test.dart
│   ├── resources/
│   │   ├── cart_resource_test.dart
│   │   └── products_resource_test.dart
│   ├── http/
│   │   └── response_test.dart
│   ├── validation/
│   │   └── validators_test.dart
│   └── mocks/
│       └── mock_http_client.dart
├── example/
│   └── lib/main.dart
├── pubspec.yaml
├── CHANGELOG.md
└── README.md
```

---

## 4. pubspec.yaml

```yaml
name: cocart
description: Official CoCart REST API SDK for Flutter and Dart.
version: 1.0.0
homepage: https://cocartapi.com
repository: https://github.com/cocart-headless/cocart-dart-sdk

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.10.0"

dependencies:
  http: ^1.2.0
  flutter_secure_storage: ^9.0.0
  meta: ^1.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
  lints: ^3.0.0
```

---

## 5. Client (`src/cocart_client.dart`)

```dart
class CoCart {
  final String siteUrl;
  final CoCartOptions _options;
  late final CoCartHttpClient _http;
  late final AuthManager _auth;

  // Resources (lazy via getters, mirrors TS client.cart(), client.products() pattern)
  CartResource cart() => CartResource(_http, _auth, _options);
  ProductsResource products() => ProductsResource(_http, _options);
  SessionsResource sessions() => SessionsResource(_http, _auth);
  JwtResource jwt() => JwtResource(_http, _auth);

  CoCart(this.siteUrl, [CoCartOptions? options])
      : _options = options ?? const CoCartOptions() {
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
  CoCart setTimeout(int ms) { _options.timeout = Duration(milliseconds: ms); return this; }
  CoCart setMaxRetries(int n) { _options.maxRetries = n; return this; }
  CoCart setRestPrefix(String p) { _options.restPrefix = p; return this; }
  CoCart setNamespace(String n) { _options.namespace = n; return this; }
  CoCart addHeader(String key, String value) { _options.extraHeaders[key] = value; return this; }
  CoCart setAuthHeaderName(String name) { _options.authHeaderName = name; return this; }
  CoCart setETag(bool enabled) { _options.etag = enabled; return this; }
  CoCart setMainPlugin(String plugin) { _options.mainPlugin = plugin; return this; }
  CoCart setDebug(bool enabled) { _options.debug = enabled; return this; }

  // --- Events (mirrors client.on()) ---
  void on(String event, Function handler) => _http.on(event, handler);

  // --- Shorthand login/logout (mirrors TS) ---
  Future<CoCartResponse> login(String identifier, String password) =>
      jwt().login(identifier, password);
  Future<void> logout() => jwt().logout();

  // --- Factory constructor (mirrors CoCart.create()) ---
  static CoCart create(String siteUrl, [CoCartOptions? options]) =>
      CoCart(siteUrl, options);

  CoCartStorage _buildStorage() {
    if (_options.encryptionKey != null) return SecureStorage(_options.encryptionKey!);
    return _options.storage ?? SecureStorage();
  }
}
```

---

## 6. Options (`src/cocart_options.dart`)

```dart
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
  String restPrefix;   // default: 'wp-json'
  String namespace;    // default: 'cocart'

  // Plugin version target
  String mainPlugin;   // 'basic' (default) or 'legacy'

  // Auth header override
  String authHeaderName; // default: 'Authorization'

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
```

---

## 7. Auth Manager (`src/auth/auth_manager.dart`)

Implements the TS priority: JWT > Basic > Consumer Keys > Guest.

```dart
enum AuthMode { guest, basicAuth, jwt, consumerKeys }

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
  String? get cartKey => _mode == AuthMode.guest ? _cartKey : null;
  String? get jwtToken => _jwtToken;
  String? get refreshToken => _refreshToken;

  // Build the auth header value (used by HttpClient)
  String? buildAuthHeader() {
    switch (_mode) {
      case AuthMode.jwt:
        return 'Bearer $_jwtToken';
      case AuthMode.basicAuth:
        final encoded = base64Encode(utf8.encode('$_username:$_password'));
        return 'Basic $encoded';
      case AuthMode.consumerKeys:
        final encoded = base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'));
        return 'Basic $encoded';
      case AuthMode.guest:
        return null;
    }
  }

  void setBasicAuth(String identifier, String password) {
    _username = identifier;
    _password = password;
    _jwtToken = null; // clear JWT (mirrors TS)
    _refreshToken = null;
    _mode = AuthMode.basicAuth;
  }

  void setJwtToken(String token) {
    _jwtToken = token;
    _username = null; // clear Basic Auth (mirrors TS)
    _password = null;
    _mode = AuthMode.jwt;
  }

  void setRefreshToken(String token) => _refreshToken = token;

  // Called by HttpClient after every cart response
  void captureCartKey(Map<String, dynamic> body, Map<String, String> headers) {
    if (_mode != AuthMode.guest) return;
    final key = body['cart_key'] as String?
        ?? headers['cart-key']
        ?? headers['x-cocart-api'];
    if (key != null && key != _cartKey) {
      _cartKey = key;
      _storage.write(_options.storageKey!, key);
    }
  }

  Future<void> restoreSession() async {
    if (_cartKey == null) {
      _cartKey = await _storage.read(_options.storageKey!);
    }
  }

  Future<void> clearSession() async {
    _cartKey = null;
    _jwtToken = null;
    _refreshToken = null;
    _username = null;
    _password = null;
    _mode = AuthMode.guest;
    await _storage.delete(_options.storageKey!);
  }
}
```

---

## 8. Response Object (`src/http/response.dart`)

Mirrors the TS `Response` class with dot-notation `.get()`.

```dart
class CoCartResponse {
  final Map<String, dynamic> _data;
  final Map<String, String> _headers;
  final int statusCode;

  CoCartResponse(this._data, this._headers, this.statusCode);

  /// Dot-notation access: response.get('totals.total'), response.get('items.0.name')
  dynamic get(String path) {
    final parts = path.split('.');
    dynamic current = _data;
    for (final part in parts) {
      if (current is Map) {
        current = current[part];
      } else if (current is List) {
        final idx = int.tryParse(part);
        if (idx == null || idx >= current.length) return null;
        current = current[idx];
      } else {
        return null;
      }
      if (current == null) return null;
    }
    return current;
  }

  bool has(String path) => get(path) != null;

  List<dynamic> getItems() => (_data['items'] as List?) ?? [];
  Map<String, dynamic> getTotals() =>
      (_data['totals'] as Map<String, dynamic>?) ?? {};
  int getItemCount() => (_data['items_count'] as int?) ?? 0;
  String? getCartKey() => _headers['cart-key'] ?? _data['cart_key'] as String?;
  String? getCartHash() => _data['cart_hash'] as String?;
  List<dynamic> getNotices() => (_data['notices'] as List?) ?? [];
  Map<String, dynamic>? getCurrency() =>
      _data['currency'] as Map<String, dynamic>?;
  String? getCacheStatus() => _headers['cocart-cache'];
  bool isNotModified() => statusCode == 304;

  Map<String, dynamic> toObject() => Map.unmodifiable(_data);
  String toJson() => jsonEncode(_data);
}
```

---

## 9. Cart Resource (`src/resources/cart_resource.dart`)

```dart
class CartResource {
  final CoCartHttpClient _http;
  final AuthManager _auth;
  final CoCartOptions _options;

  CartResource(this._http, this._auth, this._options);

  Future<CoCartResponse> create() => _http.post('cart');

  Future<CoCartResponse> get([Map<String, String>? params]) =>
      _http.get('cart', queryParams: params);

  Future<CoCartResponse> getFiltered(List<String> fields) {
    final param = _options.mainPlugin == 'legacy' ? 'fields' : '_fields';
    return _http.get('cart', queryParams: {param: fields.join(',')});
  }

  Future<CoCartResponse> addItem(int productId, num quantity,
      [Map<String, dynamic>? options]) {
    validateProductId(productId);
    validateQuantity(quantity);
    return _http.post('cart/add-item', body: {
      'id': productId.toString(),
      'quantity': quantity.toString(),
      ...?options,
    });
  }

  // Alias
  Future<CoCartResponse> add(int productId, num quantity,
      [Map<String, dynamic>? options]) => addItem(productId, quantity, options);

  Future<CoCartResponse> addVariation(
      int productId, num quantity, Map<String, String> attributes) {
    validateProductId(productId);
    validateQuantity(quantity);
    return _http.post('cart/add-item', body: {
      'id': productId.toString(),
      'quantity': quantity.toString(),
      'variation': attributes,
    });
  }

  Future<CoCartResponse> addItems(List<Map<String, dynamic>> items) =>
      _http.post('cart/add-items', body: {'items': items});

  Future<CoCartResponse> updateItem(String itemKey, num quantity,
      [Map<String, dynamic>? options]) {
    validateQuantity(quantity);
    return _http.post('cart/item/$itemKey', body: {
      'quantity': quantity.toString(),
      ...?options,
    });
  }

  Future<CoCartResponse> removeItem(String itemKey) =>
      _http.delete('cart/item/$itemKey');

  Future<CoCartResponse> removeItems(List<String> itemKeys) =>
      _http.post('cart/remove-items', body: {'items': itemKeys});

  Future<CoCartResponse> restoreItem(String itemKey) =>
      _http.post('cart/item/$itemKey/restore');

  Future<CoCartResponse> getRemovedItems() => _http.get('cart/items/removed');

  Future<CoCartResponse> clear() => _http.post('cart/clear');
  Future<CoCartResponse> empty() => clear();

  Future<CoCartResponse> calculate() => _http.post('cart/calculate');

  Future<CoCartResponse> update(Map<String, dynamic> data) =>
      _http.post('cart/update', body: data);

  Future<CoCartResponse> getTotals([bool formatted = false]) =>
      _http.get('cart/totals',
          queryParams: formatted ? {'html': 'true'} : null);

  Future<CoCartResponse> getItemCount() => _http.get('cart/items/count');

  Future<CoCartResponse> getItems() => _http.get('cart/items');

  Future<CoCartResponse> getItem(String itemKey) =>
      _http.get('cart/item/$itemKey');

  // CoCart Plus
  Future<CoCartResponse> applyCoupon(String code) =>
      _http.post('cart/coupon', body: {'coupon': code});

  Future<CoCartResponse> removeCoupon(String code) =>
      _http.delete('cart/coupon/$code');

  Future<CoCartResponse> getCoupons() => _http.get('cart/coupons');

  Future<CoCartResponse> checkCoupons() => _http.get('cart/check-coupons');

  Future<CoCartResponse> updateCustomer(
      Map<String, dynamic> billing, [Map<String, dynamic>? shipping]) =>
      _http.post('cart/customer', body: {
        'billing_address': billing,
        if (shipping != null) 'shipping_address': shipping,
      });

  Future<CoCartResponse> getCustomer() => _http.get('cart/customer');

  Future<CoCartResponse> getShippingMethods() =>
      _http.get('cart/shipping-methods');

  Future<CoCartResponse> calculateShipping(Map<String, String> address) =>
      _http.post('cart/shipping-methods', body: address);

  Future<CoCartResponse> setShippingMethod(String method) =>
      _http.post('cart/shipping-method', body: {'key': method});

  Future<CoCartResponse> getFees() => _http.get('cart/fees');

  Future<CoCartResponse> addFee(String name, double amount,
      [bool taxable = false]) =>
      _http.post('cart/fees', body: {
        'name': name,
        'amount': amount.toString(),
        'taxable': taxable.toString(),
      });

  Future<CoCartResponse> removeFees() => _http.delete('cart/fees');

  Future<CoCartResponse> getCrossSells() => _http.get('cart/cross-sells');
}
```

---

## 10. JWT Resource (`src/resources/jwt_resource.dart`)

```dart
class JwtResource {
  final CoCartHttpClient _http;
  final AuthManager _auth;

  JwtResource(this._http, this._auth);

  Future<CoCartResponse> login(String identifier, String password) async {
    final response = await _http.postRaw('cocart/jwt/token', body: {
      'username': identifier,
      'password': password,
    });
    final token = response.get('token') as String?;
    final refresh = response.get('refresh_token') as String?;
    if (token == null) throw AuthException('JWT login failed — no token returned');
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
    if (rt == null) throw AuthException('No refresh token available');
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
    // Decode the payload section of the JWT (middle segment)
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
    return payload['exp'] as int?;
  }

  bool hasTokens() => _auth.jwtToken != null;

  void setAutoRefresh(bool enabled) => _autoRefresh = enabled;
  bool isAutoRefreshEnabled() => _autoRefresh;
  bool _autoRefresh = false;

  /// Wrap any operation with automatic token refresh on expiry
  Future<T> withAutoRefresh<T>(Future<T> Function(CoCart client) callback,
      CoCart client) async {
    if (isTokenExpired()) await refresh();
    return callback(client);
  }
}
```

---

## 11. Validation (`src/validation/validators.dart`)

```dart
class ValidationError implements Exception {
  final String message;
  const ValidationError(this.message);
  @override
  String toString() => 'ValidationError: $message';
}

void validateProductId(int id) {
  if (id <= 0) throw const ValidationError('Product ID must be a positive integer');
}

void validateQuantity(num quantity) {
  if (quantity <= 0) throw const ValidationError('Quantity must be a positive number');
}

void validateEmail(String email) {
  final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  if (!re.hasMatch(email)) throw const ValidationError('Invalid email address');
}
```

---

## 12. Currency Formatter (`src/utilities/currency_formatter.dart`)

```dart
class CurrencyFormatter {
  /// Formats a raw integer amount (e.g. 4599) into a currency string ("$45.99")
  /// using the currency object returned from the API.
  String format(int amount, Map<String, dynamic> currency) {
    final decimals = (currency['currency_minor_unit'] as int?) ?? 2;
    final symbol = (currency['currency_symbol'] as String?) ?? '';
    final position = (currency['currency_symbol_position'] as String?) ?? 'left';
    final decimalSep = (currency['currency_decimal_separator'] as String?) ?? '.';
    final thousandSep = (currency['currency_thousand_separator'] as String?) ?? ',';

    final value = amount / pow(10, decimals);
    final formatted = _formatNumber(value, decimals, decimalSep, thousandSep);

    return position == 'left' ? '$symbol$formatted' : '$formatted$symbol';
  }

  String formatDecimal(int amount, Map<String, dynamic> currency) {
    final decimals = (currency['currency_minor_unit'] as int?) ?? 2;
    final value = amount / pow(10, decimals);
    return value.toStringAsFixed(decimals);
  }

  String _formatNumber(double value, int decimals, String decSep, String thouSep) {
    final parts = value.toStringAsFixed(decimals).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => thouSep,
    );
    return decimals > 0 ? '$intPart$decSep${parts[1]}' : intPart;
  }
}
```

---

## 13. Storage (`src/storage/`)

```dart
// storage_interface.dart
abstract class CoCartStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

// secure_storage.dart
class SecureStorage implements CoCartStorage {
  final FlutterSecureStorage _storage;
  SecureStorage([String? encryptionKey])
      : _storage = const FlutterSecureStorage();

  @override Future<String?> read(String key) => _storage.read(key: key);
  @override Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  @override Future<void> delete(String key) => _storage.delete(key: key);
}

// memory_storage.dart (for tests / Node-equivalent)
class MemoryStorage implements CoCartStorage {
  final _store = <String, String>{};
  @override Future<String?> read(String key) async => _store[key];
  @override Future<void> write(String key, String value) async => _store[key] = value;
  @override Future<void> delete(String key) async => _store.remove(key);
}
```

---

## 14. Quick Start (mirrors TS README)

```dart
import 'package:cocart/cocart.dart';

// Guest — simplest setup
final client = CoCart('https://your-store.com');

// Restore previous session (call once on app start)
await client.restoreSession();

// Browse products
final products = await client.products().all({'per_page': '12'});

// Add to cart — cart key captured automatically
await client.cart().addItem(123, 2);
print(client.getCartKey()); // 'guest_abc123...'

// Dot-notation response access
final cart = await client.cart().get();
print(cart.get('totals.total'));
print(cart.get('items.0.name'));

// Authenticated customer (Basic Auth)
final authClient = CoCart('https://your-store.com',
    CoCartOptions(username: 'email@example.com', password: 'pass'));

// JWT Auth
final jwtClient = CoCart('https://your-store.com');
await jwtClient.login('email@example.com', 'password');
await jwtClient.cart().get();

// Fluent config
final client2 = CoCart.create('https://your-store.com')
    .setTimeout(15000)
    .setMaxRetries(2)
    .setAuthHeaderName('X-Auth-Token')
    .addHeader('X-Custom', 'value');

// Currency formatting
final fmt = CurrencyFormatter();
final cart2 = await client.cart().get();
final currency = cart2.getCurrency()!;
print(fmt.format(4599, currency)); // "$45.99"

// Events
client.on('request', (e) => print('${e['method']} ${e['url']}'));
client.on('response', (e) => print('${e['status']} in ${e['duration']}ms'));
client.on('error', (e) => print(e['error']));
```

---

## 15. Build Phases

| Phase | Scope | Output |
|---|---|---|
| **1 — Core** | `CoCart`, `CoCartOptions`, `AuthManager`, `CoCartHttpClient`, `CoCartResponse` | Client can make authenticated/guest requests |
| **2 — Guest Session** | `GuestSession`, `SecureStorage`, `MemoryStorage`, `restoreSession()` | Cart key persists across app restarts |
| **3 — Cart Resource** | All `cart()` methods, validation, dot-notation | Full cart workflow works |
| **4 — JWT** | `JwtManager`, `JwtResource`, auto-refresh, token expiry | JWT login/refresh/logout |
| **5 — Products** | `products()` resource, `VersionError` for Basic-only methods | Product browsing + legacy mode |
| **6 — Utilities** | `CurrencyFormatter`, event system, ETag | Parity with TS feature set |
| **7 — Tests** | Unit tests for all resources + auth + validation | 90%+ coverage |
| **8 — pub.dev** | README, CHANGELOG, example app, `dart doc` | Published |

---

## 16. Key TS → Dart Mapping

| TypeScript | Dart |
|---|---|
| `new CoCart(url, opts)` | `CoCart(url, opts)` |
| `CoCart.create(url)` | `CoCart.create(url)` (factory) |
| `client.cart()` | `client.cart()` — returns `CartResource` |
| `Promise<T>` | `Future<T>` |
| `localStorage` (EncryptedStorage) | `flutter_secure_storage` |
| `MemoryStorage` (Node/SSR) | `MemoryStorage` (tests) |
| `new CurrencyFormatter()` | `CurrencyFormatter()` |
| `response.get('a.b.c')` | `response.get('a.b.c')` — identical API |
| `ValidationError` | `ValidationError` |
| `VersionError` | `VersionError` |
| `client.on('request', fn)` | `client.on('request', fn)` |
| Method chaining returns `this` | Fluent setters return `CoCart` |