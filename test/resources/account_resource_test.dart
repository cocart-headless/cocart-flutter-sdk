import 'dart:convert';

import 'package:cocart/cocart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../mocks/mock_http_client.dart';

AccountResource makeResource(MockHttpClient mockClient) {
  final options = CoCartOptions();
  final auth = AuthManager(options, MemoryStorage());
  final httpClient =
      CoCartHttpClient('https://example.com', options, auth, mockClient);
  return AccountResource(httpClient);
}

void main() {
  group('AccountResource', () {
    late MockHttpClient mockClient;

    setUp(() {
      mockClient = MockHttpClient();
    });

    // --- getProfile ---

    test('getProfile sends GET to cocart/v2/my-account', () async {
      mockClient.enqueueJson({'user': <String, dynamic>{}});

      final resource = makeResource(mockClient);
      await resource.getProfile();

      final request = mockClient.requests.first;
      expect(request.method, 'GET');
      expect(request.url.toString(), contains('cocart/v2/my-account'));
    });

    // --- updateProfile ---

    test('updateProfile sends POST to cocart/v2/my-account', () async {
      mockClient.enqueueJson({'user': <String, dynamic>{}});

      final resource = makeResource(mockClient);
      await resource.updateProfile({'account_email': 'new@example.com'});

      final request = mockClient.requests.first;
      expect(request.method, 'POST');
      expect(request.url.toString(), contains('cocart/v2/my-account'));
    });

    // --- changePassword ---

    test('changePassword remaps field names', () async {
      mockClient.enqueueJson(<String, dynamic>{});

      final resource = makeResource(mockClient);
      await resource.changePassword(
          current: 'oldpass', password: 'newpass', confirm: 'newpass');

      final request = mockClient.requests.first as http.Request;
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['password_current'], 'oldpass');
      expect(body['password_1'], 'newpass');
      expect(body['password_2'], 'newpass');
    });

    test('changePassword calls change-password path', () async {
      mockClient.enqueueJson(<String, dynamic>{});

      final resource = makeResource(mockClient);
      await resource.changePassword(
          current: 'old', password: 'new', confirm: 'new');

      expect(mockClient.requests.first.url.toString(),
          contains('change-password'));
    });

    // --- getOrders ---

    test('getOrders sends GET to orders route with params', () async {
      mockClient.enqueueJson({'orders': <dynamic>[]});

      final resource = makeResource(mockClient);
      await resource.getOrders({'per_page': '5'});

      final request = mockClient.requests.first;
      expect(request.method, 'GET');
      expect(request.url.toString(), contains('my-account/orders'));
      expect(request.url.toString(), contains('per_page=5'));
    });

    // --- getOrder ---

    test('getOrder sends correct path', () async {
      mockClient.enqueueJson({'order_id': 42});

      final resource = makeResource(mockClient);
      await resource.getOrder(42);

      expect(mockClient.requests.first.url.toString(),
          contains('my-account/orders/42'));
    });

    // --- getGuestOrder ---

    test('getGuestOrder includes email query param', () async {
      mockClient.enqueueJson({'order_id': 7});

      final resource = makeResource(mockClient);
      await resource.getGuestOrder(7, 'guest@example.com');

      final url = mockClient.requests.first.url.toString();
      expect(url, contains('orders/7'));
      expect(url, contains('email='));
    });

    // --- getOrderDownloads ---

    test('getOrderDownloads calls correct path', () async {
      mockClient.enqueueJson(<String, dynamic>{});

      final resource = makeResource(mockClient);
      await resource.getOrderDownloads(3);

      expect(mockClient.requests.first.url.toString(),
          contains('orders/3/downloads'));
    });

    // --- getGuestOrderDownloads ---

    test('getGuestOrderDownloads includes email param', () async {
      mockClient.enqueueJson(<String, dynamic>{});

      final resource = makeResource(mockClient);
      await resource.getGuestOrderDownloads(3, 'g@x.com');

      final url = mockClient.requests.first.url.toString();
      expect(url, contains('orders/3/downloads'));
      expect(url, contains('email='));
    });

    // --- getDownloads ---

    test('getDownloads calls correct path', () async {
      mockClient.enqueueJson(<String, dynamic>{});

      final resource = makeResource(mockClient);
      await resource.getDownloads();

      expect(mockClient.requests.first.url.toString(),
          contains('my-account/downloads'));
    });

    // --- getReviews ---

    test('getReviews calls correct path', () async {
      mockClient.enqueueJson(<String, dynamic>{});

      final resource = makeResource(mockClient);
      await resource.getReviews();

      expect(mockClient.requests.first.url.toString(),
          contains('my-account/reviews'));
    });

    // --- rest_no_route ---

    test('rest_no_route becomes plugin_required error', () async {
      mockClient.enqueue(MockResponse(
        statusCode: 404,
        body: jsonEncode({
          'code': 'rest_no_route',
          'message': 'No route found.',
          'data': {'status': 404},
        }),
      ));

      final resource = makeResource(mockClient);
      await expectLater(
        resource.getProfile(),
        throwsA(predicate<CoCartException>(
            (e) => e.statusCode == 404 && e.message.contains('plugin'))),
      );
    });
  });
}
