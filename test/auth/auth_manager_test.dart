import 'package:cocart/cocart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthManager', () {
    late MemoryStorage storage;

    setUp(() {
      storage = MemoryStorage();
    });

    test('defaults to guest mode', () {
      final auth = AuthManager(CoCartOptions(), storage);
      expect(auth.isGuest, isTrue);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.buildAuthHeader(), isNull);
    });

    test('initializes with Basic Auth from options', () {
      final auth = AuthManager(
        CoCartOptions(username: 'user', password: 'pass'),
        storage,
      );
      expect(auth.isAuthenticated, isTrue);
      expect(auth.isGuest, isFalse);
      expect(auth.mode, AuthMode.basicAuth);
      expect(auth.buildAuthHeader(), startsWith('Basic '));
    });

    test('initializes with JWT from options', () {
      final auth = AuthManager(
        CoCartOptions(jwtToken: 'eyJ...', jwtRefreshToken: 'refresh...'),
        storage,
      );
      expect(auth.mode, AuthMode.jwt);
      expect(auth.buildAuthHeader(), 'Bearer eyJ...');
      expect(auth.jwtToken, 'eyJ...');
      expect(auth.refreshToken, 'refresh...');
    });

    test('initializes with consumer keys from options', () {
      final auth = AuthManager(
        CoCartOptions(consumerKey: 'ck_123', consumerSecret: 'cs_456'),
        storage,
      );
      expect(auth.mode, AuthMode.consumerKeys);
      expect(auth.buildAuthHeader(), startsWith('Basic '));
    });

    test('JWT takes priority over Basic Auth', () {
      final auth = AuthManager(
        CoCartOptions(
          jwtToken: 'eyJ...',
          username: 'user',
          password: 'pass',
        ),
        storage,
      );
      expect(auth.mode, AuthMode.jwt);
    });

    test('setBasicAuth clears JWT', () {
      final auth = AuthManager(
        CoCartOptions(jwtToken: 'eyJ...'),
        storage,
      );
      auth.setBasicAuth('user', 'pass');
      expect(auth.mode, AuthMode.basicAuth);
      expect(auth.jwtToken, isNull);
    });

    test('setJwtToken clears Basic Auth', () {
      final auth = AuthManager(
        CoCartOptions(username: 'user', password: 'pass'),
        storage,
      );
      auth.setJwtToken('new_token');
      expect(auth.mode, AuthMode.jwt);
      expect(auth.buildAuthHeader(), 'Bearer new_token');
    });

    test('captureCartKey stores key for guest sessions', () async {
      final auth = AuthManager(CoCartOptions(), storage);
      auth.captureCartKey(
          {'cart_key': 'guest_abc'}, {});
      expect(auth.cartKey, 'guest_abc');

      final stored = await storage.read('cocart_cart_key');
      expect(stored, 'guest_abc');
    });

    test('captureCartKey ignores key for authenticated sessions', () {
      final auth = AuthManager(
        CoCartOptions(username: 'user', password: 'pass'),
        storage,
      );
      auth.captureCartKey({'cart_key': 'guest_abc'}, {});
      expect(auth.cartKey, isNull);
    });

    test('captureCartKey reads from headers', () {
      final auth = AuthManager(CoCartOptions(), storage);
      auth.captureCartKey({}, {'cart-key': 'header_key'});
      expect(auth.cartKey, 'header_key');
    });

    test('restoreSession loads from storage', () async {
      await storage.write('cocart_cart_key', 'saved_key');
      final auth = AuthManager(CoCartOptions(), storage);
      await auth.restoreSession();
      expect(auth.cartKey, 'saved_key');
    });

    test('clearSession resets everything', () async {
      final auth = AuthManager(
        CoCartOptions(jwtToken: 'eyJ...'),
        storage,
      );
      await auth.clearSession();
      expect(auth.isGuest, isTrue);
      expect(auth.jwtToken, isNull);
      expect(auth.refreshToken, isNull);
    });
  });
}
