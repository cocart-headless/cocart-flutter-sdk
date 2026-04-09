import '../auth/auth_manager.dart';
import '../cocart_options.dart';
import '../http/http_client.dart';
import '../http/response.dart';
import '../validation/validators.dart';

/// Cart resource — accessed via `client.cart()`.
///
/// Mirrors every cart method from the TS SDK.
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

  Future<CoCartResponse> updateItems(dynamic items) =>
      _http.post('cart/update-items', body: {'items': items});

  Future<CoCartResponse> removeItem(String itemKey) =>
      _http.delete('cart/item/$itemKey');

  Future<CoCartResponse> removeItems(List<String> itemKeys) =>
      _http.post('cart/remove-items', body: {'items': itemKeys});

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

  Future<CoCartResponse> updateCustomer(Map<String, dynamic> billing,
      [Map<String, dynamic>? shipping]) =>
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
