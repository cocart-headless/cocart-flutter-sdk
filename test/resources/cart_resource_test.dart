import 'dart:convert';

import 'package:cocart/cocart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../mocks/mock_http_client.dart';

void main() {
  group('CartResource', () {
    late MockHttpClient mockClient;

    setUp(() {
      mockClient = MockHttpClient();
    });

    test('addItem validates product ID', () {
      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, options);

      expect(
        () => cart.addItem(-1, 1),
        throwsA(isA<ValidationError>()),
      );
    });

    test('addItem validates quantity', () {
      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, options);

      expect(
        () => cart.addItem(1, 0),
        throwsA(isA<ValidationError>()),
      );
    });

    test('addItem sends correct request', () async {
      mockClient.enqueueJson({'items_count': 1});

      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, options);

      final response = await cart.addItem(42, 2);
      expect(response.getItemCount(), 1);

      final request = mockClient.requests.first;
      expect(request.method, 'POST');
      expect(request.url.path, contains('cart/add-item'));

      final body = jsonDecode(
          (request as http.Request).body) as Map<String, dynamic>;
      expect(body['id'], '42');
      expect(body['quantity'], '2');
    });

    test('getFiltered uses _fields for basic mode', () async {
      mockClient.enqueueJson({'items': [], 'totals': {}});

      final options = CoCartOptions(mainPlugin: 'basic');
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, options);

      await cart.getFiltered(['items', 'totals']);
      final url = mockClient.requests.first.url;
      expect(url.queryParameters['_fields'], 'items,totals');
    });

    test('getFiltered uses fields for legacy mode', () async {
      mockClient.enqueueJson({'items': [], 'totals': {}});

      final options = CoCartOptions(mainPlugin: 'legacy');
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, options);

      await cart.getFiltered(['items', 'totals']);
      final url = mockClient.requests.first.url;
      expect(url.queryParameters['fields'], 'items,totals');
    });

    test('add is alias for addItem', () async {
      mockClient.enqueueJson({'items_count': 1});

      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, options);

      await cart.add(42, 1);
      expect(mockClient.requests.first.url.path, contains('cart/add-item'));
    });

    test('empty is alias for clear', () async {
      mockClient.enqueueJson({});

      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, options);

      await cart.empty();
      expect(mockClient.requests.first.url.path, contains('cart/clear'));
    });

    test('updateItem validates quantity', () {
      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, options);

      expect(
        () => cart.updateItem('key123', -1),
        throwsA(isA<ValidationError>()),
      );
    });

    test('addItems posts grouped-product id + child quantity map (Map form)',
        () async {
      mockClient.enqueueJson({'items_count': 3});

      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, options);

      await cart.addItems(100, {'10': 2, '11': 1});

      final request = mockClient.requests.first;
      expect(request.method, 'POST');
      expect(request.url.path, contains('cart/add-items'));

      final body = jsonDecode((request as http.Request).body)
          as Map<String, dynamic>;
      expect(body['id'], '100');
      expect(body['quantity'], {'10': '2', '11': '1'});
    });

    test('addItems posts grouped-product id + child quantity map (List form)',
        () async {
      mockClient.enqueueJson({'items_count': 3});

      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, options);

      await cart.addItems(100, [
        {'id': 10, 'quantity': 2},
        {'id': 11, 'quantity': 1},
      ]);

      final request = mockClient.requests.first;
      final body = jsonDecode((request as http.Request).body)
          as Map<String, dynamic>;
      expect(body['id'], '100');
      expect(body['quantity'], {'10': '2', '11': '1'});
    });

    test('addItems throws ValidationError when items is empty', () {
      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, options);

      expect(
        () => cart.addItems(100, <String, int>{}),
        throwsA(isA<ValidationError>()),
      );
    });

    test('updateItems sends one sequential request per item, returns last',
        () async {
      mockClient.enqueueJson({'item': 'a'});
      mockClient.enqueueJson({'item': 'b'});

      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, options);

      final response = await cart.updateItems({'key-a': 2, 'key-b': 3});

      expect(mockClient.requests.length, 2);
      expect(mockClient.requests[0].url.path, contains('cart/item/key-a'));
      expect(mockClient.requests[1].url.path, contains('cart/item/key-b'));
      expect(response.get('item'), 'b');
    });

    test('removeItems sends one sequential request per item, returns last',
        () async {
      mockClient.enqueueJson({});
      mockClient.enqueueJson({});

      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, options);

      await cart.removeItems(['key-a', 'key-b']);

      expect(mockClient.requests.length, 2);
      expect(mockClient.requests[0].method, 'DELETE');
      expect(mockClient.requests[0].url.path, contains('cart/item/key-a'));
      expect(mockClient.requests[1].url.path, contains('cart/item/key-b'));
    });

    test('batchUpdateItems posts a single batch request with per-item bodies',
        () async {
      mockClient.enqueueJson({'requests': []});

      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, options);

      await cart.batchUpdateItems({'key-a': 2});

      expect(mockClient.requests.length, 1);
      final request = mockClient.requests.first;
      expect(request.url.path, contains('cocart/batch'));

      final body = jsonDecode((request as http.Request).body)
          as Map<String, dynamic>;
      final requests = body['requests'] as List;
      expect(requests, hasLength(1));
      expect(requests[0]['method'], 'POST');
      expect(requests[0]['path'], '/cocart/v2/cart/item/key-a');
      expect(requests[0]['body'], {'quantity': '2'});
    });

    test('batchRemoveItems posts a single batch request per item key',
        () async {
      mockClient.enqueueJson({'requests': []});

      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, options);

      await cart.batchRemoveItems(['key-a']);

      final request = mockClient.requests.first;
      final body = jsonDecode((request as http.Request).body)
          as Map<String, dynamic>;
      final requests = body['requests'] as List;
      expect(requests[0]['method'], 'DELETE');
      expect(requests[0]['path'], '/cocart/v2/cart/item/key-a');
      expect(requests[0].containsKey('body'), isFalse);
    });

    test('updateCustomer sends unprefixed billing + s_-prefixed shipping '
        'mirrored from billing when shipping omitted', () async {
      mockClient.enqueueJson({});

      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, options);

      await cart.updateCustomer({'first_name': 'Jane', 'city': 'Perth'});

      final request = mockClient.requests.first;
      expect(request.url.path, contains('cart/update'));

      final body = jsonDecode((request as http.Request).body)
          as Map<String, dynamic>;
      expect(body['namespace'], 'update-customer');
      expect(body['first_name'], 'Jane');
      expect(body['city'], 'Perth');
      expect(body['s_first_name'], 'Jane');
      expect(body['s_city'], 'Perth');
      expect(body.containsKey('ship_to_different_address'), isFalse);
    });

    test('updateCustomer sends distinct s_-prefixed shipping and sets '
        'ship_to_different_address when shipping provided', () async {
      mockClient.enqueueJson({});

      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, options);

      await cart.updateCustomer(
        {'first_name': 'Jane'},
        {'first_name': 'John'},
      );

      final request = mockClient.requests.first;
      final body = jsonDecode((request as http.Request).body)
          as Map<String, dynamic>;
      expect(body['first_name'], 'Jane');
      expect(body['s_first_name'], 'John');
      expect(body['ship_to_different_address'], isTrue);
    });

    test('setShippingMethod posts rate_id and optional package_id', () async {
      mockClient.enqueueJson({});

      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, options);

      await cart.setShippingMethod('flat_rate:2', 'package-1');

      final request = mockClient.requests.first;
      expect(request.url.path, contains('cart/set-shipping-method'));

      final body = jsonDecode((request as http.Request).body)
          as Map<String, dynamic>;
      expect(body['rate_id'], 'flat_rate:2');
      expect(body['package_id'], 'package-1');
    });

    test('setShippingMethod omits package_id when not provided', () async {
      mockClient.enqueueJson({});

      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, options);

      await cart.setShippingMethod('flat_rate:2');

      final body = jsonDecode(
          (mockClient.requests.first as http.Request).body) as Map<String, dynamic>;
      expect(body.containsKey('package_id'), isFalse);
    });

    test('calculateShipping ignores address and delegates to calculate()',
        () async {
      mockClient.enqueueJson({'totals': {}});

      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, options);

      // ignore: deprecated_member_use_from_same_package
      await cart.calculateShipping({'country': 'US'});

      final request = mockClient.requests.first;
      expect(request.method, 'POST');
      expect(request.url.path, contains('cart/calculate'));
      expect(request.url.path, isNot(contains('shipping')));
    });
  });
}
