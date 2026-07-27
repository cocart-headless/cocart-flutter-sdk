import 'dart:convert';

/// Wraps every API response with convenience accessors.
///
/// Mirrors the TS SDK's `Response` class including dot-notation `.get()`.
class CoCartResponse {
  final Map<String, dynamic> _data;
  final Map<String, String> _headers;
  final int statusCode;

  CoCartResponse(this._data, this._headers, this.statusCode);

  /// Dot-notation access: `response.get('totals.total')`,
  /// `response.get('items.0.name')`.
  dynamic get(String path) {
    final parts = path.split('.');
    dynamic current = _data;
    for (final part in parts) {
      if (current is Map) {
        current = current[part];
      } else if (current is List) {
        final idx = int.tryParse(part);
        if (idx == null || idx >= current.length) return null;
        current = current[idx];
      } else {
        return null;
      }
      if (current == null) return null;
    }
    return current;
  }

  /// Returns `true` if the dot-notation path resolves to a non-null value.
  bool has(String path) => get(path) != null;

  List<dynamic> getItems() => (_data['items'] as List?) ?? [];

  Map<String, dynamic> getTotals() =>
      (_data['totals'] as Map<String, dynamic>?) ?? {};

  int getItemCount() => (_data['items_count'] as int?) ?? 0;

  String? getCartKey() =>
      _headers['cart-key'] ?? _headers['cocart-api-cart-key'] ?? _data['cart_key'] as String?;

  String? getCartHash() => _data['cart_hash'] as String?;

  List<dynamic> getNotices() => (_data['notices'] as List?) ?? [];

  Map<String, dynamic>? getCurrency() =>
      _data['currency'] as Map<String, dynamic>?;

  /// Get cart tax lines, normalized to a flat list — one entry per tax rate.
  ///
  /// CoCart Starter 5.0+ already returns `taxes` as an array. The community
  /// CoCart plugin (and older Starter versions) instead return an object
  /// keyed by the tax rate code, e.g. `{ "US-US-1": { name, price } }` —
  /// that legacy shape is detected and converted here so callers never need
  /// to branch on which plugin/version they're talking to.
  List<Map<String, dynamic>> getTaxes() {
    final raw = _data['taxes'];

    if (raw is List) {
      return raw.map((e) => e as Map<String, dynamic>).toList();
    }

    if (raw is Map) {
      return raw.entries.map((entry) {
        final tax = entry.value as Map<String, dynamic>;
        return {
          'key': entry.key,
          'name': tax['name'],
          'price': tax['price'],
        };
      }).toList();
    }

    return [];
  }

  /// Returns `true` if the cart has any tax lines.
  bool hasTaxes() => getTaxes().isNotEmpty;

  String? getCacheStatus() => _headers['cocart-cache'];

  bool isNotModified() => statusCode == 304;

  Map<String, dynamic> toObject() => Map.unmodifiable(_data);

  String toJson() => jsonEncode(_data);
}
