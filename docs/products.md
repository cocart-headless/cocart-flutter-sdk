# Products API

The Products API is public and requires no authentication. Access it via `client.products()`.

## List Products

```dart
// All products
final products = await client.products().all();

// With parameters
final products = await client.products().all({
  'per_page': '12',
  'page': '2',
  'orderby': 'popularity',
});
```

## Parameters Reference

| Parameter | Type | Description |
|---|---|---|
| `page` | `String` | Page number (default: `'1'`) |
| `per_page` | `String` | Items per page (default: `'10'`, max: `'100'`) |
| `search` | `String` | Search term |
| `category` | `String` | Filter by category slug |
| `tag` | `String` | Filter by tag slug |
| `status` | `String` | Filter by status (`'publish'`, `'draft'`, etc.) |
| `featured` | `String` | Filter featured products (`'true'` / `'false'`) |
| `on_sale` | `String` | Filter on-sale products (`'true'` / `'false'`) |
| `min_price` | `String` | Minimum price |
| `max_price` | `String` | Maximum price |
| `stock_status` | `String` | `'instock'`, `'outofstock'`, `'onbackorder'` |
| `orderby` | `String` | Sort field (`'date'`, `'price'`, `'popularity'`, `'rating'`) |
| `order` | `String` | Sort direction (`'asc'` or `'desc'`) |

## Filtering

### By Category

```dart
final products = await client.products().category('clothing');
```

### By Tag

```dart
final products = await client.products().tag('summer');
```

### By Brand

```dart
// All products by brand
final products = await client.products().byBrand('nike');
```

### Combining Filters

```dart
final products = await client.products().all({
  'category': 'clothing',
  'min_price': '10',
  'max_price': '50',
  'orderby': 'price',
  'order': 'asc',
  'per_page': '20',
});
```

### By Stock Status

```dart
final products = await client.products().all({
  'stock_status': 'instock',
});
```

## Single Product

### By ID

```dart
final product = await client.products().find(42);
```

### By Slug

> CoCart Basic only — throws `VersionError` in legacy mode.

```dart
final product = await client.products().findBySlug('blue-t-shirt');
```

## Variations

Variable products have variations (e.g. different sizes or colors).

### Get a Specific Variation

```dart
final variation = await client.products().variation(42, 101);
```

## Categories

### List All Categories

```dart
final categories = await client.products().attributes();
```

## Tags

Products can be organized with tags for cross-cutting concerns.

## Attributes

Attributes define variable product options (e.g. Color, Size).

### List All Attributes

```dart
final attrs = await client.products().attributes();
```

### Get a Single Attribute

```dart
final attr = await client.products().attribute(1);
```

### Get Attribute Terms

```dart
// List terms for attribute ID 1 (e.g. "Red", "Blue", "Green")
final terms = await client.products().attributeTerms(1);
```

## Brands

### List All Brands

```dart
final brands = await client.products().brands();
```

### Get a Single Brand

```dart
final brand = await client.products().brand('nike');
```

### Filter Products by Brand

```dart
final products = await client.products().byBrand('nike');
```

## Reviews

### List All Reviews

```dart
final reviews = await client.products().myReviews();
```

## Working with Responses

```dart
final products = await client.products().all({'per_page': '12'});

// Dot-notation access
print(products.get('0.name'));
print(products.get('0.price'));

// Serialize
final data = products.toObject();
final json = products.toJson();
```
