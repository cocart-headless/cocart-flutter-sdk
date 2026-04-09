import 'dart:convert';

import 'package:cocart/cocart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../mocks/mock_http_client.dart';

void main() {
  group('CartResource', () {
    late MockHttpClient mockClient;
    late CoCart client;

    setUp(() {
      mockClient = MockHttpClient();
      final options = CoCartOptions(storage: MemoryStorage());
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
        'https://example.com',
        options,
        auth,
        mockClient,
      );
      // We build the client manually to inject the mock
      client = CoCart('https://example.com', options);
      // Override the internal http client via reflection-free approach:
      // We test CartResource directly instead.
    });

    test('addItem validates product ID', () {
      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
        'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, auth, options);

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
      final cart = CartResource(httpClient, auth, options);

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
      final cart = CartResource(httpClient, auth, options);

      final response = await cart.addItem(42, 2);
      expect(response.getItemCount(), 1);

      final request = mockClient.requests.first;
      expect(request.method, 'POST');
      expect(request.url.path, contains('cart/add-item'));

      final body = jsonDecode(
          await (request as http.Request).body) as Map<String, dynamic>;
      expect(body['id'], '42');
      expect(body['quantity'], '2');
    });

    test('getFiltered uses _fields for basic mode', () async {
      mockClient.enqueueJson({'items': [], 'totals': {}});

      final options = CoCartOptions(mainPlugin: 'basic');
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
        'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, auth, options);

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
      final cart = CartResource(httpClient, auth, options);

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
      final cart = CartResource(httpClient, auth, options);

      await cart.add(42, 1);
      expect(mockClient.requests.first.url.path, contains('cart/add-item'));
    });

    test('empty is alias for clear', () async {
      mockClient.enqueueJson({});

      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
        'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, auth, options);

      await cart.empty();
      expect(mockClient.requests.first.url.path, contains('cart/clear'));
    });

    test('updateItem validates quantity', () {
      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
        'https://example.com', options, auth, mockClient);
      final cart = CartResource(httpClient, auth, options);

      expect(
        () => cart.updateItem('key123', -1),
        throwsA(isA<ValidationError>()),
      );
    });
  });
}
