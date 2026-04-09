# Authentication

The SDK supports four authentication modes, applied in priority order: **JWT > Basic Auth > Consumer Keys > Guest**.

## Guest Customers

The simplest mode — no credentials needed. The SDK automatically captures the cart key from the first API response and includes it in subsequent requests.

```dart
final client = CoCart('https://your-store.com');

// First request — server creates a session and returns a cart key
await client.cart().addItem(123, 1);

// SDK captured it automatically
print(client.getCartKey()); // 'guest_abc123...'
```

### Restoring a Session

Cart keys are persisted in `flutter_secure_storage`. On app start, call `restoreSession()` to resume where the user left off:

```dart
final client = CoCart('https://your-store.com');
await client.restoreSession(); // Loads cart key from secure storage

// Continue shopping — the previous cart is still there
final cart = await client.cart().get();
```

### Resuming with a Known Cart Key

If you already have a cart key (e.g. from a deep link or push notification):

```dart
final client = CoCart('https://your-store.com',
    CoCartOptions(cartKey: 'guest_abc123'));
```

## Basic Auth

For authenticated customers using their WordPress username/email and password:

```dart
// Via constructor
final client = CoCart('https://your-store.com',
    CoCartOptions(username: 'email@example.com', password: 'password'));

// Or at runtime
final client = CoCart('https://your-store.com');
client.setAuth('email@example.com', 'password');

// Check status
print(client.isAuthenticated()); // true
print(client.isGuest());         // false
```

## JWT Authentication

More secure than Basic Auth. Requires the [CoCart JWT Authentication](https://cocartapi.com) plugin.

### Login

```dart
final client = CoCart('https://your-store.com');
final response = await client.login('email@example.com', 'password');

// Access user info from the response
print(response.get('display_name'));
print(response.get('user_id'));
```

### Logout

```dart
await client.logout(); // Clears tokens and session
```

### Refresh an Expired Token

```dart
await client.jwt().refresh();
```

### Validate a Token

```dart
final isValid = await client.jwt().validate(); // true or false
```

### Check Token Expiry

```dart
// Check if token expires within 5 minutes (300 seconds)
if (client.jwt().isTokenExpired(300)) {
  await client.jwt().refresh();
}

// Get the raw expiry timestamp
final expiry = client.jwt().getTokenExpiry(); // Unix timestamp or null
```

### Auto-Refresh

Wrap any operation with automatic token refresh on expiry:

```dart
client.jwt().setAutoRefresh(true);

// Or use withAutoRefresh for a single operation
final cart = await client.jwt().withAutoRefresh(() async {
  return client.cart().get();
});
```

### JWT Utility Methods

| Method | Returns | Description |
|---|---|---|
| `hasTokens()` | `bool` | Whether a JWT token is set |
| `isTokenExpired([leeway])` | `bool` | Whether token is expired (with optional leeway in seconds) |
| `getTokenExpiry()` | `int?` | Unix timestamp of token expiry |
| `isAutoRefreshEnabled()` | `bool` | Whether auto-refresh is enabled |
| `setAutoRefresh(bool)` | `void` | Enable or disable auto-refresh |

### Pre-Setting Tokens

If you already have tokens (e.g. from another service):

```dart
// Via constructor
final client = CoCart('https://your-store.com',
    CoCartOptions(jwtToken: 'eyJ...', jwtRefreshToken: 'refresh...'));

// Or at runtime
client.setJwtToken('eyJ...');
client.setRefreshToken('refresh...');
```

## Consumer Keys (Admin)

For admin operations like the Sessions API. Uses WooCommerce REST API consumer keys:

```dart
final client = CoCart('https://your-store.com',
    CoCartOptions(consumerKey: 'ck_123...', consumerSecret: 'cs_456...'));

final sessions = await client.sessions().all();
```

## Custom Auth Header Name

Some proxies or hosting providers strip the `Authorization` header. Use a custom header name:

```dart
// Via constructor
final client = CoCart('https://your-store.com',
    CoCartOptions(
      authHeaderName: 'X-Auth-Token',
      username: 'email@example.com',
      password: 'password',
    ));

// Or at runtime
client.setAuthHeaderName('X-Auth-Token');
```

## Authentication Priority

When multiple credentials are provided, the SDK uses this priority:

1. **JWT Token** — `Authorization: Bearer <token>`
2. **Basic Auth** — `Authorization: Basic base64(username:password)`
3. **Consumer Keys** — `Authorization: Basic base64(ck:cs)`
4. **Guest** — No auth header; `cart_key` query param on cart routes

### Switching Auth at Runtime

```dart
final client = CoCart('https://your-store.com');

// Start with JWT
await client.login('email@example.com', 'password');

// Switch to Basic Auth — clears JWT automatically
client.setAuth('email@example.com', 'password');

// Switch to JWT — clears Basic Auth automatically
client.setJwtToken('eyJ...');

// Clear everything
await client.clearSession();
print(client.isGuest()); // true
```
