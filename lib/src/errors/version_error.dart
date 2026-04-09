import 'cocart_exception.dart';

/// Thrown when a method requires CoCart Basic but the client is in legacy mode.
class VersionError extends CoCartException {
  const VersionError(super.message);

  @override
  String toString() => 'VersionError: $message';
}
