# Error Handling

All SDK methods can throw exceptions. Use `try`/`catch` to handle them:

```dart
try {
  await client.cart().addItem(123, 1);
} on CoCartException catch (e) {
  print('Error: ${e.message}');
  print('Status: ${e.statusCode}');
  print('Data: ${e.data}');
}
```

## Error Hierarchy

```
CoCartException (base)
├── AuthException
├── NetworkException
├── RateLimitException
└── VersionError

ValidationError (separate — thrown before any HTTP request)
```

## Catching Errors

Use Dart's typed `on` clauses to handle specific error types:

```dart
try {
  await client.cart().addItem(123, 1);
} on ValidationError catch (e) {
  // Client-side validation failed — no network request was made
  print('Validation: ${e.message}');
} on AuthException catch (e) {
  // Authentication failed (401, 403)
  print('Auth: ${e.message}');
} on RateLimitException catch (e) {
  // Too many requests (429)
  print('Rate limited. Retry after: ${e.retryAfter}');
} on NetworkException catch (e) {
  // Network failure (timeout, connection error)
  print('Network: ${e.message}');
} on CoCartException catch (e) {
  // Any other API error (400, 404, 500, etc.)
  print('API error: ${e.message} (${e.statusCode})');
}
```

## Error Properties

### CoCartException

| Property | Type | Description |
|---|---|---|
| `message` | `String` | Human-readable error message |
| `statusCode` | `int?` | HTTP status code (if from a response) |
| `data` | `Map<String, dynamic>?` | Full response body for inspection |

### RateLimitException

Extends `CoCartException` with:

| Property | Type | Description |
|---|---|---|
| `retryAfter` | `Duration?` | How long to wait before retrying |

### ValidationError

| Property | Type | Description |
|---|---|---|
| `message` | `String` | What validation rule was violated |

## HTTP Status Code Mapping

| HTTP Status | Error Thrown | Typical Causes |
|---|---|---|
| 400 | `CoCartException` | Invalid input, out of stock |
| 401 | `CoCartException` | Missing or invalid credentials |
| 403 | `CoCartException` | Expired token, insufficient permissions |
| 404 | `CoCartException` | Endpoint not found, product not found |
| 429 | `RateLimitException` | Too many requests |
| 500 | `CoCartException` | Server error |
| Network failure | `NetworkException` | Timeout, no connection |

## Client-Side Validation Errors

The SDK validates input **before** making any network request. These throw `ValidationError` immediately, with no HTTP call:

```dart
// Product ID must be positive
try {
  await client.cart().addItem(-1, 1);
} on ValidationError catch (e) {
  print(e); // "ValidationError: Product ID must be a positive integer"
}

// Quantity must be positive
try {
  await client.cart().addItem(42, 0);
} on ValidationError catch (e) {
  print(e); // "ValidationError: Quantity must be a positive number"
}
```

### Standalone Validators

```dart
validateProductId(42);            // OK — no exception
validateQuantity(2);              // OK
validateEmail('user@test.com');   // OK

validateProductId(-1);            // throws ValidationError
validateQuantity(0);              // throws ValidationError
validateEmail('not-an-email');    // throws ValidationError
```

## JWT Token Expiry

Check token expiry proactively instead of waiting for a 401:

```dart
if (client.jwt().isTokenExpired()) {
  await client.jwt().refresh();
}

// Or use withAutoRefresh to handle it automatically
final cart = await client.jwt().withAutoRefresh(() async {
  return client.cart().get();
});
```

## Legacy Plugin Version Guard

Methods that require CoCart Basic throw `VersionError` in legacy mode:

```dart
final client = CoCart('https://your-store.com',
    CoCartOptions(mainPlugin: 'legacy'));

try {
  await client.products().findBySlug('my-product');
} on VersionError catch (e) {
  print(e); // "VersionError: findBySlug requires CoCart Basic..."
}
```

## Common Error Scenarios

### Product Not Found

```dart
try {
  await client.products().find(99999);
} on CoCartException catch (e) {
  print(e.statusCode); // 404
  print(e.data?['code']); // 'cocart_product_not_found'
}
```

### Out of Stock

```dart
try {
  await client.cart().addItem(42, 100);
} on CoCartException catch (e) {
  print(e.statusCode); // 400
  print(e.data?['code']); // 'cocart_not_enough_in_stock'
}
```

### Network / Timeout Errors

```dart
final client = CoCart('https://your-store.com')
    .setTimeout(5000); // 5 second timeout

try {
  await client.cart().get();
} on NetworkException catch (e) {
  print('Network error: ${e.message}');
}
```
