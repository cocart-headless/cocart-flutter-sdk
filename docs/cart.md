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

### Add Children of a Grouped Product

`addItems()` is **not** a generic "add several unrelated products" call — it maps to the dedicated `cart/add-items` endpoint, which only accepts children of a single WooCommerce Grouped Product: a grouped product ID plus a map of that group's child product IDs to quantities.

```dart
// Shorthand: childId => quantity
final response = await client.cart().addItems(100, {
  '123': 2,
  '456': 1,
});

// Or a list of {id, quantity} entries
final response = await client.cart().addItems(100, [
  {'id': '123', 'quantity': 2},
  {'id': '456', 'quantity': 1},
]);
```

To add several unrelated products in one request, use [`batch()`](#batch-requests) instead.

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

There is no bulk-update endpoint on the server, so `updateItems()` sends one `updateItem()` request per entry, sequentially, and returns the response from the last one:

```dart
// Shorthand: itemKey => quantity
final response = await client.cart().updateItems({
  'item_key_abc': 3,
  'item_key_def': 1,
});

// Or a list of {item_key, quantity} entries
final response = await client.cart().updateItems([
  {'item_key': 'item_key_abc', 'quantity': 3},
  {'item_key': 'item_key_def', 'quantity': 1},
]);
```

For a true single round trip, use `batchUpdateItems()` instead — see [Batch Requests](#batch-requests) below.

## Removing & Restoring Items

```dart
// Remove a single item
await client.cart().removeItem('item_key_abc');

// Remove multiple items — one request per item key, sequentially, returning
// the response from the last removal. For a true single round trip, use
// batchRemoveItems() instead — see Batch Requests below.
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

Billing fields are sent unprefixed (`first_name`, `address_1`, ...) and shipping fields `s_`-prefixed (`s_first_name`, `s_address_1`, ...). If `shipping` is omitted or empty, billing is mirrored into the `s_` fields so the shipping address matches billing — same as leaving "ship to a different address" unchecked at a normal WooCommerce checkout. `ship_to_different_address` is only sent as `true` when a distinct `shipping` address is actually provided.

```dart
// Billing address only — shipping mirrors billing
await client.cart().updateCustomer({
  'first_name': 'John',
  'last_name': 'Doe',
  'email': 'john@example.com',
});

// Billing and a distinct shipping address
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

Select a shipping rate for a package. Omit `packageId` to apply the rate to every package.

```dart
// Select a rate for every package
await client.cart().setShippingMethod('flat_rate:1');

// Select a rate for a specific package
await client.cart().setShippingMethod('flat_rate:1', 'package-0');
```

### Calculate Shipping

> **Deprecated:** there is no address-taking shipping-calculation endpoint in the CoCart REST API. `calculateShipping()` now ignores its argument and just delegates to `calculate()`. Call `updateCustomer()` with the destination address to trigger server-side shipping recalculation, or call `calculate()` directly.

```dart
// Recalculates cart totals (including shipping) based on the customer
// address already set via updateCustomer()
await client.cart().calculate();
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

## Batch Requests

> Requires the **CoCart Plus** plugin.

Dispatch multiple sub-requests in a single call via `POST {namespace}/batch` — a true single round trip instead of making several separate requests. Each sub-request is `{method, path, body?}`.

```dart
final response = await client.batch([
  {
    'method': 'POST',
    'path': '/cocart/v2/cart/item/item_key_abc',
    'body': {'quantity': '3'},
  },
  {
    'method': 'DELETE',
    'path': '/cocart/v2/cart/item/item_key_def',
  },
]);
```

`CartResource` provides typed convenience wrappers over `batch()` for updating and removing multiple items in one round trip:

```dart
// Shorthand: itemKey => quantity
await client.cart().batchUpdateItems({
  'item_key_abc': 3,
  'item_key_def': 1,
});

// Remove multiple items in one request
await client.cart().batchRemoveItems(['item_key_abc', 'item_key_def']);
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
cart.getTaxes();      // List<Map<String, dynamic>> — normalized {key, name, price} entries
cart.hasTaxes();      // bool

// Dot-notation access
cart.get('totals.total');       // dynamic
cart.get('items.0.name');       // dynamic
cart.has('totals.discount');    // bool

// Serialization
cart.toObject();  // Map<String, dynamic> (unmodifiable)
cart.toJson();    // String (JSON)
```
