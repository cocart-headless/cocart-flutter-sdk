import '../errors/cocart_exception.dart';
import '../http/http_client.dart';
import '../http/response.dart';

/// Account resource — accessed via `client.account()`.
///
/// All methods call raw (non-namespaced) routes under cocart/v2/my-account.
class AccountResource {
  final CoCartHttpClient _http;

  AccountResource(this._http);

  static const _base = 'cocart/v2/my-account';

  String _path([String sub = '']) =>
      sub.isEmpty ? _base : '$_base/${sub.replaceAll(RegExp(r'^/+'), '')}';

  CoCartException _pluginRequired() => const CoCartException(
        'This method is only available with another CoCart plugin. '
        'Please ask support for assistance!',
        statusCode: 404,
      );

  Future<CoCartResponse> _getRaw(String sub,
      [Map<String, String>? params]) async {
    try {
      return await _http.getRaw(_path(sub), queryParams: params);
    } on CoCartException catch (e) {
      if (e.data?['code'] == 'rest_no_route') throw _pluginRequired();
      rethrow;
    }
  }

  Future<CoCartResponse> _postRaw(String sub,
      [Map<String, dynamic>? body]) async {
    try {
      return await _http.postRaw(_path(sub), body: body);
    } on CoCartException catch (e) {
      if (e.data?['code'] == 'rest_no_route') throw _pluginRequired();
      rethrow;
    }
  }

  // MARK: - Profile

  /// Return the authenticated user's account profile.
  Future<CoCartResponse> getProfile() => _getRaw('');

  /// Update the authenticated user's profile fields.
  Future<CoCartResponse> updateProfile(Map<String, dynamic> data) =>
      _postRaw('', data);

  /// Change the authenticated user's password.
  ///
  /// Fields are remapped to the wire format:
  /// current → password_current, password → password_1, confirm → password_2.
  Future<CoCartResponse> changePassword({
    required String current,
    required String password,
    required String confirm,
  }) =>
      _postRaw('change-password', {
        'password_current': current,
        'password_1': password,
        'password_2': confirm,
      });

  // MARK: - Orders

  /// Return a paginated list of the user's orders.
  Future<CoCartResponse> getOrders([Map<String, String>? params]) =>
      _getRaw('orders', params);

  /// Return a single order by ID.
  Future<CoCartResponse> getOrder(int id) => _getRaw('orders/$id');

  /// Return a single guest order by ID and billing email.
  Future<CoCartResponse> getGuestOrder(int id, String email) =>
      _getRaw('orders/$id', {'email': email});

  // MARK: - Downloads

  /// Return downloadable files for a specific order.
  Future<CoCartResponse> getOrderDownloads(int id) =>
      _getRaw('orders/$id/downloads');

  /// Return downloadable files for a specific guest order.
  Future<CoCartResponse> getGuestOrderDownloads(int id, String email) =>
      _getRaw('orders/$id/downloads', {'email': email});

  /// Return all downloadable files available to the authenticated user.
  Future<CoCartResponse> getDownloads() => _getRaw('downloads');

  // MARK: - Reviews

  /// Return the authenticated user's product reviews.
  Future<CoCartResponse> getReviews() => _getRaw('reviews');
}
