# Cart API

Cart sessions work differently depending on the customer type:

- **Guest customers** — identified by a `Cart-Key`, captured automatically by the SDK
- **Authenticated customers** — identified by their account credentials

Access the cart API via `client.cart()`.

## Create Cart

Create a new guest cart without adding any items:

```dart
final response = await client.cart().create();
print(response.get('cart_key'));
```

## Get Cart

```dart
// Full cart
final cart = await client.cart().get();

// With parameters
final cart = await client.cart().get({
  'thumb': 'true',
  'default': 'true',
});
```

### Type-Safe Field Filtering

Only fetch the fields you need to reduce payload size:

```dart
final cart = await client.cart().getFiltered(['items', 'totals']);
```

> In legacy mode, this sends `fields` instead of `_fields`.

## Client-Side Validation

The SDK validates input **before** making any network request. Invalid input throws a `ValidationError` immediately:

```dart
// Throws ValidationError: "Product ID must be a positive integer"
await client.cart().addItem(-1, 1);

// Throws ValidationError: "Quantity must be a positive number"
await client.cart().addItem(42, 0);
```

You can also use the validators directly:

```dart
validateProductId(42);          // OK
validateQuantity(2);            // OK
validateEmail('user@test.com'); // OK

validateProductId(-1);          // throws ValidationError
```

## Adding Items

### Add a Simple Product

```dart
final response = await client.cart().addItem(123, 2);

// Shorthand alias
final response = await client.cart().add(123, 2);
```

### Add with Options

```dart
final response = await client.cart().addItem(123, 1, {
  'email': 'customer@example.com',
  'return_item': 'true',
});
```

### Add a Variable Product

```dart
// Using addVariation with explicit attributes
final response = await client.cart().addVariation(456, 1, {
  'attribute_pa_color': 'blue',
  'attribute_pa_size': 'large',
});

// Or using addItem with variation option
final response = await client.cart().addItem(456, 1, {
  'variation': {
    'attribute_pa_color': 'blue',
    'attribute_pa_size': 'large',
  },
});
```

### Add Multiple Items at Once

```dart
final response = await client.cart().addItems([
  {'id': '123', 'quantity': '2'},
  {'id': '456', 'quantity': '1'},
]);
```

## Updating Items

Each item in the cart has a unique **item key** (returned when the item is added or when fetching the cart).

```dart
// Update quantity
final response = await client.cart().updateItem('item_key_abc', 3);

// Update with additional options
final response = await client.cart().updateItem('item_key_abc', 3, {
  'return_item': 'true',
});
```

### Update Multiple Items at Once

```dart
final response = await client.cart().updateItems([
  {'key': 'item_key_abc', 'quantity': 3},
  {'key': 'item_key_def', 'quantity': 1},
]);
```

## Removing & Restoring Items

```dart
// Remove a single item
await client.cart().removeItem('item_key_abc');

// Remove multiple items
await client.cart().removeItems(['item_key_abc', 'item_key_def']);

// Restore a previously removed item
await client.cart().restoreItem('item_key_abc');

// Get all removed items
final removed = await client.cart().getRemovedItems();
```

## Cart Management

```dart
// Clear all items from the cart
await client.cart().clear();
await client.cart().empty(); // alias for clear()

// Recalculate totals
await client.cart().calculate();

// Update cart data (e.g. customer note)
await client.cart().update({'customer_note': 'Please gift wrap'});
```

## Totals & Counts

```dart
// Get cart totals
final totals = await client.cart().getTotals();

// Get formatted totals (HTML)
final formatted = await client.cart().getTotals(true);

// Get item count
final count = await client.cart().getItemCount();

// Get all items
final items = await client.cart().getItems();

// Get a specific item
final item = await client.cart().getItem('item_key_abc');
```

## Coupons

> Requires the **CoCart Plus** plugin.

```dart
// Apply a coupon
await client.cart().applyCoupon('SAVE10');

// Remove a coupon
await client.cart().removeCoupon('SAVE10');

// Get applied coupons
final coupons = await client.cart().getCoupons();

// Check if coupons are valid
final check = await client.cart().checkCoupons();
```

## Customer Details

### Update Customer

```dart
// Billing address only
await client.cart().updateCustomer({
  'first_name': 'John',
  'last_name': 'Doe',
  'email': 'john@example.com',
});

// Billing and shipping
await client.cart().updateCustomer(
  {'first_name': 'John', 'email': 'john@example.com'},
  {'first_name': 'John', 'address_1': '123 Main St', 'city': 'Anytown'},
);
```

### Get Customer Details

```dart
final customer = await client.cart().getCustomer();
```

## Shipping

### Get Available Shipping Methods

```dart
final methods = await client.cart().getShippingMethods();
```

### Set Shipping Method

> Requires the **CoCart Plus** plugin.

```dart
await client.cart().setShippingMethod('flat_rate:1');
```

### Calculate Shipping

```dart
await client.cart().calculateShipping({
  'country': 'US',
  'state': 'NY',
  'city': 'New York',
  'postcode': '10001',
});
```

## Fees

> Requires the **CoCart Plus** plugin.

```dart
// Get fees
final fees = await client.cart().getFees();

// Add a fee
await client.cart().addFee('Gift Wrapping', 5.99, true);

// Remove all fees
await client.cart().removeFees();
```

## Cross-Sells

```dart
final crossSells = await client.cart().getCrossSells();
```

## ETag / Conditional Requests

The SDK automatically uses ETags to avoid re-downloading unchanged data. When the server returns a `304 Not Modified`, the response has no body and `isNotModified()` returns `true`.

```dart
final cart1 = await client.cart().get(); // Full response
final cart2 = await client.cart().get(); // 304 if unchanged

if (cart2.isNotModified()) {
  print('Cart unchanged, use cached data');
}
```

### Disable ETag

```dart
// Via constructor
final client = CoCart('https://your-store.com',
    CoCartOptions(etag: false));

// Or at runtime
client.setETag(false);
```

### Clear ETag Cache

```dart
client.clearETagCache();
```

### Cache Status

```dart
final status = cart.getCacheStatus(); // 'HIT', 'MISS', or 'SKIP'
```

## Working with Responses

Every cart method returns a `CoCartResponse` with these helpers:

```dart
final cart = await client.cart().get();

// Convenience getters
cart.getItems();      // List<dynamic>
cart.getTotals();     // Map<String, dynamic>
cart.getItemCount();  // int
cart.getCartKey();    // String?
cart.getCartHash();   // String?
cart.getNotices();    // List<dynamic>
cart.getCurrency();   // Map<String, dynamic>?

// Dot-notation access
cart.get('totals.total');       // dynamic
cart.get('items.0.name');       // dynamic
cart.has('totals.discount');    // bool

// Serialization
cart.toObject();  // Map<String, dynamic> (unmodifiable)
cart.toJson();    // String (JSON)
```
