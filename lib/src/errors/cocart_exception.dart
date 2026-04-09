/// Base exception for all CoCart SDK errors.
class CoCartException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;

  const CoCartException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'CoCartException: $message';
}
