import '../cocart_options.dart';
import '../errors/version_error.dart';
import '../http/http_client.dart';
import '../http/response.dart';

/// Products resource — accessed via `client.products()`.
///
/// Mirrors the TS SDK's products resource. Methods marked "CoCart Starter only"
/// throw [VersionError] when `mainPlugin` is `'legacy'`.
class ProductsResource {
  final CoCartHttpClient _http;
  final CoCartOptions _options;

  ProductsResource(this._http, this._options);

  void _requireBasic(String method) {
    if (_options.mainPlugin == 'legacy') {
      throw VersionError(
          '$method requires CoCart Starter — not available in legacy mode');
    }
  }

  Future<CoCartResponse> all([Map<String, String>? filters]) =>
      _http.get('products', queryParams: filters);

  /// Get a single product by ID or SKU. `GET products/{id}` accepts either
  /// the numeric product/variation ID or the product's SKU in the same path
  /// segment (documented in both the CoCart Starter and CoCart Community v2
  /// OpenAPI specs as "Unique identifier for the product (ID or SKU)").
  Future<CoCartResponse> find(Object id) => _http.get('products/$id');

  /// CoCart Starter only.
  Future<CoCartResponse> findBySlug(String slug) {
    _requireBasic('findBySlug');
    return _http.get('products', queryParams: {'slug': slug});
  }

  Future<CoCartResponse> variation(int productId, int variationId) =>
      _http.get('products/$productId/variations/$variationId');

  Future<CoCartResponse> category(String slug) =>
      _http.get('products', queryParams: {'category': slug});

  Future<CoCartResponse> tag(String slug) =>
      _http.get('products', queryParams: {'tag': slug});

  Future<CoCartResponse> brands() => _http.get('products/brands');

  Future<CoCartResponse> brand(String slug) =>
      _http.get('products/brands/$slug');

  Future<CoCartResponse> byBrand(String slug) =>
      _http.get('products', queryParams: {'brand': slug});

  Future<CoCartResponse> myReviews() => _http.get('products/reviews');

  Future<CoCartResponse> attributes() => _http.get('products/attributes');

  Future<CoCartResponse> attribute(int id) =>
      _http.get('products/attributes/$id');

  Future<CoCartResponse> attributeTerms(int attributeId) =>
      _http.get('products/attributes/$attributeId/terms');
}
