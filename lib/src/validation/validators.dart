import '../errors/validation_error.dart';

final _numericStringPattern = RegExp(r'^\s*-?\d+(\.\d+)?\s*$');

/// Validates a product ID, mirroring the server's own resolution rules.
///
/// A numeric value (an [int], or a [String] containing only a number) must
/// be a positive integer. A non-numeric string is treated as a potential
/// SKU and passed through untouched — the server resolves a non-numeric ID
/// via `wc_get_product_id_by_sku()` before falling back to a 404. This SDK
/// can't verify a SKU exists without a network request, so it only rejects
/// input that's certain to be invalid: empty, or numeric but not a
/// positive integer.
///
/// Throws [ValidationError] before any network request if invalid.
void validateProductId(Object id) {
  if (id is String) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      throw const ValidationError('Product ID must be a positive integer');
    }
    if (!_numericStringPattern.hasMatch(id)) {
      return; // Non-numeric string — treat as a SKU; the server resolves it.
    }
    final value = double.tryParse(trimmed);
    if (value == null || value < 1 || value != value.truncateToDouble()) {
      throw const ValidationError('Product ID must be a positive integer');
    }
    return;
  }
  if (id is num) {
    if (id < 1 || id != id.truncate()) {
      throw const ValidationError('Product ID must be a positive integer');
    }
    return;
  }
  throw const ValidationError('Product ID must be a positive integer');
}

/// Validates that a quantity is a positive number.
///
/// Throws [ValidationError] before any network request if invalid.
void validateQuantity(num quantity) {
  if (quantity <= 0) {
    throw const ValidationError('Quantity must be a positive number');
  }
}

/// Validates that an email address has a basic valid format.
///
/// Throws [ValidationError] before any network request if invalid.
void validateEmail(String email) {
  final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  if (!re.hasMatch(email)) {
    throw const ValidationError('Invalid email address');
  }
}
