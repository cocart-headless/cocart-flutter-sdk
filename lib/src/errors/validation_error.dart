/// Thrown for client-side input validation failures (before any HTTP request).
class ValidationError implements Exception {
  final String message;

  const ValidationError(this.message);

  @override
  String toString() => 'ValidationError: $message';
}
