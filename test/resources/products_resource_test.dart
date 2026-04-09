import 'package:cocart/cocart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/mock_http_client.dart';

void main() {
  group('ProductsResource', () {
    late MockHttpClient mockClient;

    setUp(() {
      mockClient = MockHttpClient();
    });

    test('findBySlug throws VersionError in legacy mode', () {
      final options = CoCartOptions(mainPlugin: 'legacy');
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
        'https://example.com', options, auth, mockClient);
      final products = ProductsResource(httpClient, options);

      expect(
        () => products.findBySlug('test-product'),
        throwsA(isA<VersionError>()),
      );
    });

    test('findBySlug works in basic mode', () async {
      mockClient.enqueueJson({'id': 1, 'slug': 'test-product'});

      final options = CoCartOptions(mainPlugin: 'basic');
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
        'https://example.com', options, auth, mockClient);
      final products = ProductsResource(httpClient, options);

      await products.findBySlug('test-product');
      final url = mockClient.requests.first.url;
      expect(url.queryParameters['slug'], 'test-product');
    });

    test('all passes filters as query params', () async {
      mockClient.enqueueJson({});

      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
        'https://example.com', options, auth, mockClient);
      final products = ProductsResource(httpClient, options);

      await products.all({'per_page': '12', 'page': '2'});
      final url = mockClient.requests.first.url;
      expect(url.queryParameters['per_page'], '12');
      expect(url.queryParameters['page'], '2');
    });

    test('category passes slug as query param', () async {
      mockClient.enqueueJson({});

      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
        'https://example.com', options, auth, mockClient);
      final products = ProductsResource(httpClient, options);

      await products.category('clothing');
      final url = mockClient.requests.first.url;
      expect(url.queryParameters['category'], 'clothing');
    });
  });
}
