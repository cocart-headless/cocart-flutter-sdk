# CoCart Flutter SDK

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?logo=Flutter&logoColor=white)](https://flutter.dev)
[![pub package](https://img.shields.io/pub/v/cocart.svg)](https://pub.dev/packages/cocart)
[![Tests](https://github.com/cocart-headless/cocart-flutter-sdk/actions/workflows/tests.yml/badge.svg)](https://github.com/cocart-headless/cocart-flutter-sdk/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

Official Flutter SDK for the [CoCart](https://cocartapi.com) REST API. Build headless WooCommerce storefronts with Flutter.

> ![IMPORTANT]
> This SDK is still in development and not yet ready for production use. Provide feedback if you experience a bug.

## TODO to complete the SDK

- Add SDK docs to documentation site
- Add support for Cart API extras
- Add Checkout API support
- Add Customers Account API support

## Requirements

- Flutter 3.10+
- Dart 3.0+
- CoCart plugin installed on your WooCommerce store
- CoCart JWT Authentication plugin (optional, for JWT auth)

## Support Policy

See [SUPPORT.md](SUPPORT.md)

## Features

- Fluent, chainable API
- Typed responses with dot-notation access
- Client-side input validation (before any network request)
- Currency formatting utility
- Event system for request/response lifecycle hooks
- Response transformer for custom processing
- Configurable auth header name (proxy support)
- Secure session storage via `flutter_secure_storage`
- JWT authentication with auto-refresh
- ETag / conditional requests for bandwidth optimization
- Legacy CoCart plugin support
- Guest session management with automatic cart key capture

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

## Quick Start

```dart
import 'package:cocart/cocart.dart';

void main() async {
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
}
```

> All API methods return `Future<CoCartResponse>`, so use `async`/`await`.

## Documentation

### Guides

| Guide | Description |
|---|---|
| [Configuration & Setup](docs/installation.md) | All config options, fluent setters, custom prefixes, legacy mode |
| [Authentication](docs/authentication.md) | Guest, Basic Auth, JWT, Consumer Keys, auth switching |
| [Cart API](docs/cart.md) | Add/update/remove items, coupons, shipping, fees, cross-sells |
| [Products API](docs/products.md) | Browse, filter, search products, categories, brands, reviews |
| [Sessions API](docs/sessions.md) | Admin session management, storage adapters |
| [Error Handling](docs/error-handling.md) | Error hierarchy, HTTP status mapping, validation errors |
| [Utilities](docs/utilities.md) | Currency formatting, response transformer |

## Features

### Fluent API

```dart
final client = CoCart.create('https://your-store.com')
    .setTimeout(15000)
    .setMaxRetries(2)
    .setAuthHeaderName('X-Auth-Token')
    .addHeader('X-Custom', 'value');
```

### Dot-Notation Response Access

```dart
final cart = await client.cart().get();

// Nested access with dot notation
print(cart.get('totals.total'));
print(cart.get('items.0.name'));
print(cart.has('totals.discount')); // true or false
```

### Type-Safe Field Filtering

```dart
// Only fetch items and totals (reduces payload)
final cart = await client.cart().getFiltered(['items', 'totals']);
```

### Currency Formatting

```dart
final fmt = CurrencyFormatter();
final cart = await client.cart().get();
final currency = cart.getCurrency()!;

print(fmt.format(4599, currency));    // "$45.99"
print(fmt.formatDecimal(4599, currency)); // "45.99"
```

### Client-Side Validation

```dart
// Throws ValidationError before any network request
await client.cart().addItem(-1, 0); // ValidationError: Product ID must be a positive integer
```

### Event System

```dart
client.on('request', (e) => print('${e['method']} ${e['url']}'));
client.on('response', (e) => print('${e['status']} in ${e['duration']}ms'));
client.on('error', (e) => print(e['error']));
```

### Secure Session Storage

Guest cart keys are persisted securely using `flutter_secure_storage`, surviving app restarts:

```dart
final client = CoCart('https://your-store.com');
await client.restoreSession(); // Restores cart key from secure storage
```

### JWT with Auto-Refresh

```dart
// Login
await client.login('email@example.com', 'password');

// Auto-refresh wraps any operation with token refresh on expiry
await client.jwt().withAutoRefresh(() async {
  return client.cart().get();
});
```

## CoCart Channels

- **Documentation** — [https://cocartapi.com/docs](https://cocartapi.com/docs)
- **Community** — [https://cocartapi.com/community](https://cocartapi.com/community)
- **GitHub** — [https://github.com/cocart-headless](https://github.com/cocart-headless)
- **X** — [@cocartheadless](https://twitter.com/cocartheadless)

## Credits

CoCart is developed and maintained by [CoCart Headless, LLC](https://cocartapi.com).

- [https://github.com/cocart-headless](https://github.com/cocart-headless)
- [https://twitter.com/cocartheadless](https://twitter.com/cocartheadless)

## License

Released under the [MIT License](LICENSE).
