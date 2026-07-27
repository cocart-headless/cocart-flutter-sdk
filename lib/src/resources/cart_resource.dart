import '../cocart_options.dart';
import '../errors/validation_error.dart';
import '../http/http_client.dart';
import '../http/response.dart';
import '../validation/validators.dart';

/// Cart resource — accessed via `client.cart()`.
///
/// Mirrors every cart method from the TS SDK.
class CartResource {
  final CoCartHttpClient _http;
  final CoCartOptions _options;

  CartResource(this._http, this._options);

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

  /// Alias for [addItem].
  Future<CoCartResponse> add(int productId, num quantity,
      [Map<String, dynamic>? options]) =>
      addItem(productId, quantity, options);

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

  /// Add multiple children of a WooCommerce Grouped Product to the cart in a
  /// single request, via the dedicated `cart/add-items` endpoint.
  ///
  /// This is NOT a generic "add several unrelated products" call — the
  /// server requires a single grouped product ID plus a map of that group's
  /// child product IDs to quantities. For adding unrelated products in one
  /// request, use [CoCartHttpClient.batch] instead.
  ///
  /// [items] may be a `Map<String, int>` of `childId => quantity` (shorthand)
  /// or a `List` of `{id, quantity}` entries.
  Future<CoCartResponse> addItems(int groupedProductId, Object items) {
    validateProductId(groupedProductId);

    final quantity = <String, String>{};
    if (items is Map) {
      items.forEach((key, value) {
        quantity[key.toString()] = value.toString();
      });
    } else if (items is List) {
      for (final entry in items) {
        final map = entry as Map;
        quantity[map['id'].toString()] = map['quantity'].toString();
      }
    } else {
      throw const ValidationError(
          'addItems() items must be a Map<String, int> or a List of '
          '{id, quantity} entries.');
    }

    if (quantity.isEmpty) {
      throw const ValidationError('addItems() requires at least one item.');
    }

    return _http.post('cart/add-items', body: {
      'id': groupedProductId.toString(),
      'quantity': quantity,
    });
  }

  Future<CoCartResponse> updateItem(String itemKey, num quantity,
      [Map<String, dynamic>? options]) {
    validateQuantity(quantity);
    return _http.post('cart/item/$itemKey', body: {
      'quantity': quantity.toString(),
      ...?options,
    });
  }

  /// Update multiple items' quantities, one request per item, sequentially
  /// (there is no real bulk-update endpoint). Returns the response from the
  /// last update, which reflects the fully-updated cart.
  ///
  /// [items] may be a `Map<String, num>` of `itemKey => quantity` (shorthand)
  /// or a `List` of `{item_key, quantity}` entries.
  ///
  /// For a true single round trip, use [batchUpdateItems] instead (requires
  /// CoCart Plus).
  Future<CoCartResponse> updateItems(Object items) async {
    final entries = _normalizeItemEntries(items);
    if (entries.isEmpty) {
      throw const ValidationError('updateItems() requires at least one item.');
    }

    CoCartResponse? response;
    for (final entry in entries) {
      response = await updateItem(entry.key, entry.value);
    }
    return response!;
  }

  Future<CoCartResponse> removeItem(String itemKey) =>
      _http.delete('cart/item/$itemKey');

  /// Remove multiple items from the cart, one request per item, sequentially
  /// (there is no real bulk-remove endpoint). Returns the response from the
  /// last removal, which reflects the fully-updated cart.
  ///
  /// For a true single round trip, use [batchRemoveItems] instead (requires
  /// CoCart Plus).
  Future<CoCartResponse> removeItems(List<String> itemKeys) async {
    if (itemKeys.isEmpty) {
      throw const ValidationError(
          'removeItems() requires at least one item key.');
    }

    CoCartResponse? response;
    for (final itemKey in itemKeys) {
      response = await removeItem(itemKey);
    }
    return response!;
  }

  /// Update multiple items' quantities in a single request via the
  /// `{namespace}/batch` endpoint (requires CoCart Plus) — a true single
  /// round trip instead of [updateItems]'s sequential loop.
  ///
  /// Accepts the same shorthand/full formats as [updateItems].
  Future<CoCartResponse> batchUpdateItems(Object items) {
    final entries = _normalizeItemEntries(items);
    if (entries.isEmpty) {
      throw const ValidationError(
          'batchUpdateItems() requires at least one item.');
    }

    final requests = entries
        .map((entry) => {
              'method': 'POST',
              'path': _versionedPath('cart/item/${entry.key}'),
              'body': {'quantity': entry.value.toString()},
            })
        .toList();

    return _http.batch(requests);
  }

  /// Remove multiple items in a single request via the `{namespace}/batch`
  /// endpoint (requires CoCart Plus) — a true single round trip instead of
  /// [removeItems]'s sequential loop.
  Future<CoCartResponse> batchRemoveItems(List<String> itemKeys) {
    if (itemKeys.isEmpty) {
      throw const ValidationError(
          'batchRemoveItems() requires at least one item key.');
    }

    final requests = itemKeys
        .map((itemKey) => {
              'method': 'DELETE',
              'path': _versionedPath('cart/item/$itemKey'),
            })
        .toList();

    return _http.batch(requests);
  }

  /// Convert the shorthand (`itemKey => quantity`) or full array format into
  /// entry tuples.
  List<MapEntry<String, num>> _normalizeItemEntries(Object items) {
    if (items is Map) {
      return items.entries
          .map((e) => MapEntry(e.key.toString(), e.value as num))
          .toList();
    } else if (items is List) {
      return items.map((entry) {
        final map = entry as Map;
        return MapEntry(map['item_key'].toString(), map['quantity'] as num);
      }).toList();
    }
    throw const ValidationError(
        'items must be a Map<String, num> or a List of '
        '{item_key, quantity} entries.');
  }

  /// Builds a fully-versioned `/{namespace}/v2/{endpoint}` path for use as a
  /// batch sub-request path.
  String _versionedPath(String endpoint) => '/${_options.namespace}/v2/$endpoint';

  Future<CoCartResponse> restoreItem(String itemKey) =>
      _http.post('cart/item/$itemKey/restore');

  Future<CoCartResponse> getRemovedItems() => _http.get('cart/items/removed');

  Future<CoCartResponse> clear() => _http.post('cart/clear');

  /// Alias for [clear].
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

  // --- CoCart Plus ---

  Future<CoCartResponse> applyCoupon(String code) =>
      _http.post('cart/coupon', body: {'coupon': code});

  Future<CoCartResponse> removeCoupon(String code) =>
      _http.delete('cart/coupon/$code');

  Future<CoCartResponse> getCoupons() => _http.get('cart/coupons');

  Future<CoCartResponse> checkCoupons() => _http.get('cart/check-coupons');

  /// Update customer billing (and optionally shipping) address on the cart.
  ///
  /// Posts to the `update-customer` callback via `POST cart/update` — billing
  /// fields are sent unprefixed (`first_name`, `address_1`, ...) and shipping
  /// fields are sent `s_`-prefixed (`s_first_name`, `s_address_1`, ...). If
  /// [shipping] is omitted or empty, billing is mirrored into the `s_` fields
  /// so the shipping address matches billing (same as leaving "ship to a
  /// different address" unchecked at a normal WooCommerce checkout).
  /// `ship_to_different_address` is only sent as `true` when a distinct
  /// [shipping] is actually provided.
  Future<CoCartResponse> updateCustomer(Map<String, dynamic> billing,
      [Map<String, dynamic>? shipping]) {
    final hasDistinctShipping = shipping != null && shipping.isNotEmpty;
    // Written as an inline null-check (rather than reusing the bool above)
    // so the analyzer can promote `shipping` to non-nullable in this branch.
    final Map<String, dynamic> shipTo =
        shipping != null && shipping.isNotEmpty ? shipping : billing;

    final data = <String, dynamic>{'namespace': 'update-customer'};
    billing.forEach((key, value) => data[key] = value);
    shipTo.forEach((key, value) => data['s_$key'] = value);
    if (hasDistinctShipping) {
      data['ship_to_different_address'] = true;
    }

    return _http.post('cart/update', body: data);
  }

  Future<CoCartResponse> getCustomer() => _http.get('cart/customer');

  Future<CoCartResponse> getShippingMethods() =>
      _http.get('cart/shipping-methods');

  /// This endpoint does not exist in the CoCart REST API. Call
  /// [updateCustomer] with the destination address to trigger server-side
  /// shipping recalculation, or call [calculate] directly. [address] is
  /// ignored — this now just delegates to [calculate].
  @Deprecated(
      'There is no address-taking shipping-calculation endpoint in the '
      'CoCart REST API. Use updateCustomer() with the destination address, '
      'or call calculate() directly. This now ignores [address] and '
      'delegates to calculate().')
  Future<CoCartResponse> calculateShipping([Map<String, String>? address]) =>
      calculate();

  /// Select a shipping rate for a package (CoCart Plus).
  ///
  /// Posts `rate_id` (and optional `package_id`) to
  /// `POST cart/set-shipping-method`. Omit [packageId] to apply the rate to
  /// every package.
  Future<CoCartResponse> setShippingMethod(String rateId,
      [String? packageId]) =>
      _http.post('cart/set-shipping-method', body: {
        'rate_id': rateId,
        if (packageId != null) 'package_id': packageId,
      });

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
