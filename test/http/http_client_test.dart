import 'package:cocart/cocart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/mock_http_client.dart';

void main() {
  group('CoCartHttpClient', () {
    late MockHttpClient mockClient;

    setUp(() {
      mockClient = MockHttpClient();
    });

    test('sends only Cart-Key header for basic (default) plugin mode',
        () async {
      mockClient.enqueueJson({'items_count': 0});

      final options = CoCartOptions(cartKey: 'guest_abc');
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);

      await httpClient.get('cart');

      final headers = mockClient.requests.first.headers;
      expect(headers['Cart-Key'], 'guest_abc');
      expect(headers.containsKey('CoCart-API-Cart-Key'), isFalse);
    });

    test('sends only CoCart-API-Cart-Key header for legacy plugin mode',
        () async {
      mockClient.enqueueJson({'items_count': 0});

      final options =
          CoCartOptions(cartKey: 'guest_abc', mainPlugin: 'legacy');
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);

      await httpClient.get('cart');

      final headers = mockClient.requests.first.headers;
      expect(headers['CoCart-API-Cart-Key'], 'guest_abc');
      expect(headers.containsKey('Cart-Key'), isFalse);
    });

    test('caches body/headers from a fresh 2xx GET and serves them back '
        'on a subsequent 304', () async {
      mockClient.enqueueJson(
        {'items_count': 3},
        headers: {'etag': 'W/"abc123"'},
      );
      mockClient.enqueue(const MockResponse(statusCode: 304, body: ''));

      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);

      final first = await httpClient.get('cart');
      expect(first.getItemCount(), 3);

      final second = await httpClient.get('cart');
      expect(second.isNotModified(), isTrue);
      expect(second.getItemCount(), 3);
      expect(second.toObject(), first.toObject());

      // The second request should have sent If-None-Match with the cached ETag.
      final secondRequestHeaders = mockClient.requests[1].headers;
      expect(secondRequestHeaders['If-None-Match'], 'W/"abc123"');
    });

    test('coalesces concurrent identical GET requests into one round trip',
        () async {
      mockClient.enqueueJson({'items_count': 5});

      final options = CoCartOptions();
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);

      final future1 = httpClient.get('cart/items');
      final future2 = httpClient.get('cart/items');

      final results = await Future.wait([future1, future2]);

      expect(mockClient.requests.length, 1);
      expect(results[0].getItemCount(), 5);
      expect(results[1].getItemCount(), 5);
    });

    test('retries a transient failure after a real delay and succeeds',
        () async {
      mockClient.enqueueException(Exception('simulated network error'));
      mockClient.enqueueJson({'items_count': 1});

      final options = CoCartOptions(maxRetries: 1);
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);

      final stopwatch = Stopwatch()..start();
      final response = await httpClient.get('cart');
      stopwatch.stop();

      expect(response.getItemCount(), 1);
      expect(mockClient.requests.length, 2);
      // Base backoff for the first retry is min(2^0, 30) = 1s, with jitter
      // in [0.8, 1.2]. A near-zero delay here would indicate the retry
      // bug (no delay at all) has regressed.
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(700));
    });

    test('throws NetworkException after exhausting retries', () async {
      mockClient.enqueueException(Exception('simulated network error'));
      mockClient.enqueueException(Exception('simulated network error'));

      final options = CoCartOptions(maxRetries: 1);
      final auth = AuthManager(options, MemoryStorage());
      final httpClient = CoCartHttpClient(
          'https://example.com', options, auth, mockClient);

      await expectLater(
        httpClient.get('cart'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
