import 'cocart_exception.dart';

/// Thrown when the server returns a 429 Too Many Requests response.
class RateLimitException extends CoCartException {
  final Duration? retryAfter;

  const RateLimitException(super.message, {this.retryAfter, super.statusCode, super.data});

  @override
  String toString() => 'RateLimitException: $message';
}
