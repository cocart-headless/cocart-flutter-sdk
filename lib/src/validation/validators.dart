import '../errors/validation_error.dart';

/// Validates that a product ID is a positive integer.
///
/// Throws [ValidationError] before any network request if invalid.
void validateProductId(int id) {
  if (id <= 0) {
    throw const ValidationError('Product ID must be a positive integer');
  }
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
