import 'cocart_exception.dart';

/// Thrown for network-level failures (timeouts, connection errors).
class NetworkException extends CoCartException {
  const NetworkException(super.message, {super.statusCode, super.data});

  @override
  String toString() => 'NetworkException: $message';
}
