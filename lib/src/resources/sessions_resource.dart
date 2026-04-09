import '../auth/auth_manager.dart';
import '../http/http_client.dart';
import '../http/response.dart';

/// Sessions resource — accessed via `client.sessions()`.
///
/// Requires admin/consumer key authentication.
class SessionsResource {
  final CoCartHttpClient _http;
  final AuthManager _auth;

  SessionsResource(this._http, this._auth);

  Future<CoCartResponse> all() => _http.get('sessions');
}
