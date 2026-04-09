# Utilities

Optional utility classes for common tasks.

## Currency Formatter

The CoCart API returns prices as **smallest-unit integers** (e.g. `4599` for $45.99). The `CurrencyFormatter` converts these into formatted strings using the currency object from the API response.

### Formatting Prices

```dart
final fmt = CurrencyFormatter();

final cart = await client.cart().get();
final currency = cart.getCurrency()!;

// Full formatted string with symbol
print(fmt.format(4599, currency));        // "$45.99"

// Plain decimal string (no symbol)
print(fmt.formatDecimal(4599, currency)); // "45.99"
```

### Different Currencies

The formatter respects the currency configuration returned by the API:

```dart
// Euro (2 decimals, comma separator, symbol right)
final eur = {
  'currency_symbol': '\u20AC',
  'currency_minor_unit': 2,
  'currency_decimal_separator': ',',
  'currency_thousand_separator': '.',
  'currency_symbol_position': 'right',
};
print(fmt.format(4599, eur)); // "45,99\u20AC"

// Japanese Yen (0 decimals)
final jpy = {
  'currency_symbol': '\u00A5',
  'currency_minor_unit': 0,
  'currency_decimal_separator': '.',
  'currency_thousand_separator': ',',
  'currency_symbol_position': 'left',
};
print(fmt.format(4599, jpy)); // "\u00A54,599"
```

### Currency Object Properties

The currency object is returned by `cart.getCurrency()` and contains:

| Key | Type | Description |
|---|---|---|
| `currency_symbol` | `String` | Symbol (e.g. `$`, `\u20AC`, `\u00A5`) |
| `currency_minor_unit` | `int` | Decimal places (e.g. `2` for dollars, `0` for yen) |
| `currency_decimal_separator` | `String` | Decimal separator (`.` or `,`) |
| `currency_thousand_separator` | `String` | Thousands separator (`,` or `.`) |
| `currency_symbol_position` | `String` | `'left'` or `'right'` |

---

## Response Transformer

A response transformer is a function that runs on every API response before it is returned to your code. Useful for logging, metrics, or data enrichment.

### Via Constructor

```dart
final client = CoCart('https://your-store.com', CoCartOptions(
  responseTransformer: (response) {
    print('Status: ${response.statusCode}');
    print('Items: ${response.getItemCount()}');
    return response;
  },
));
```

### Removing the Transformer

Set it to `null` in options to disable:

```dart
final client = CoCart('https://your-store.com', CoCartOptions(
  responseTransformer: null,
));
```

### Example: Logging All Responses

```dart
CoCartResponse logResponses(CoCartResponse response) {
  print('[CoCart] ${response.statusCode} — '
      '${response.getItemCount()} items, '
      'total: ${response.get('totals.total')}');
  return response;
}

final client = CoCart('https://your-store.com',
    CoCartOptions(responseTransformer: logResponses));
```

---

## Event System

The SDK emits events during the request lifecycle. Register listeners with `client.on()`:

```dart
// Log every outgoing request
client.on('request', (e) {
  print('${e['method']} ${e['url']}');
});

// Log every response
client.on('response', (e) {
  print('${e['status']} in ${e['duration']}ms');
});

// Log errors
client.on('error', (e) {
  print('Error: ${e['error']}');
});
```

### Available Events

| Event | Data | When |
|---|---|---|
| `request` | `{'method': 'GET', 'url': '...'}` | Before each HTTP request |
| `response` | `{'status': 200, 'duration': 123}` | After a successful response |
| `error` | `{'error': '...'}` | After a failed request (all retries exhausted) |

---

## Debug Mode

Enable debug logging to see all HTTP traffic in the console:

```dart
final client = CoCart('https://your-store.com')
    .setDebug(true);

// Prints: [CoCart] GET https://your-store.com/wp-json/cocart/v2/cart → 200 (142ms)
```
