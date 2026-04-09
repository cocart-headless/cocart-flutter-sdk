import 'cocart_exception.dart';

/// Thrown when authentication fails or tokens are missing/invalid.
class AuthException extends CoCartException {
  const AuthException(super.message, {super.statusCode, super.data});

  @override
  String toString() => 'AuthException: $message';
}
