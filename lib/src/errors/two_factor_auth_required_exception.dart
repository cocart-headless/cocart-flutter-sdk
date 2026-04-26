import 'auth_exception.dart';

/// Thrown by [JwtResource.login] when the server requires a 2FA code to complete login.
///
/// Catch this exception, read [availableProviders] / [defaultProvider] / [emailSent],
/// prompt the user for their code, then call [JwtResource.verifyTwoFactor].
class TwoFactorAuthRequiredException extends AuthException {
  /// Providers available for verification (e.g. `'totp'`, `'email'`, `'backup'`).
  final List<String> availableProviders;

  /// The default provider the server will use if none is specified.
  final String? defaultProvider;

  /// Whether the server has already sent a code via email.
  final bool emailSent;

  TwoFactorAuthRequiredException(
    super.message, {
    super.statusCode,
    super.data,
    List<String>? availableProviders,
    this.defaultProvider,
    this.emailSent = false,
  }) : availableProviders = availableProviders ?? [];

  @override
  String toString() => 'TwoFactorAuthRequiredException: $message';
}
