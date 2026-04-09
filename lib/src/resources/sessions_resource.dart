import '../http/http_client.dart';
import '../http/response.dart';

/// Sessions resource — accessed via `client.sessions()`.
///
/// Requires admin/consumer key authentication.
class SessionsResource {
  final CoCartHttpClient _http;

  SessionsResource(this._http);

  Future<CoCartResponse> all() => _http.get('sessions');
}
