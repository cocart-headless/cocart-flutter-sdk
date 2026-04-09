import 'package:cocart/cocart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GuestSession', () {
    late MemoryStorage storage;

    test('cart key persists across AuthManager instances', () async {
      storage = MemoryStorage();

      // First session — capture a key
      final auth1 = AuthManager(CoCartOptions(), storage);
      auth1.captureCartKey({'cart_key': 'guest_123'}, {});
      expect(auth1.cartKey, 'guest_123');

      // Second session — restore
      final auth2 = AuthManager(CoCartOptions(), storage);
      await auth2.restoreSession();
      expect(auth2.cartKey, 'guest_123');
    });

    test('pre-seeded cartKey is used immediately', () {
      storage = MemoryStorage();
      final auth = AuthManager(
        CoCartOptions(cartKey: 'preset_key'),
        storage,
      );
      expect(auth.cartKey, 'preset_key');
    });

    test('clearSession removes stored key', () async {
      storage = MemoryStorage();
      await storage.write('cocart_cart_key', 'saved_key');

      final auth = AuthManager(CoCartOptions(), storage);
      await auth.restoreSession();
      expect(auth.cartKey, 'saved_key');

      await auth.clearSession();
      expect(auth.cartKey, isNull);

      final stored = await storage.read('cocart_cart_key');
      expect(stored, isNull);
    });
  });
}
