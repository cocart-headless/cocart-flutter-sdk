import 'dart:convert';

import 'package:cocart/cocart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoCartResponse', () {
    late CoCartResponse response;

    setUp(() {
      response = CoCartResponse(
        {
          'items': [
            {'name': 'T-Shirt', 'price': '1999'},
            {'name': 'Hat', 'price': '999'},
          ],
          'items_count': 2,
          'totals': {
            'total': '2998',
            'discount': '0',
          },
          'cart_key': 'guest_abc123',
          'cart_hash': 'hash_xyz',
          'notices': ['Item added'],
          'currency': {
            'currency_symbol': '\$',
            'currency_minor_unit': 2,
          },
        },
        {'cart-key': 'guest_abc123', 'cocart-cache': 'HIT'},
        200,
      );
    });

    test('get() with dot notation', () {
      expect(response.get('totals.total'), '2998');
      expect(response.get('totals.discount'), '0');
      expect(response.get('items.0.name'), 'T-Shirt');
      expect(response.get('items.1.price'), '999');
    });

    test('get() returns null for missing paths', () {
      expect(response.get('nonexistent'), isNull);
      expect(response.get('totals.missing'), isNull);
      expect(response.get('items.99.name'), isNull);
    });

    test('has() checks path existence', () {
      expect(response.has('totals.total'), isTrue);
      expect(response.has('nonexistent'), isFalse);
    });

    test('getItems()', () {
      final items = response.getItems();
      expect(items.length, 2);
      expect(items[0]['name'], 'T-Shirt');
    });

    test('getTotals()', () {
      final totals = response.getTotals();
      expect(totals['total'], '2998');
    });

    test('getItemCount()', () {
      expect(response.getItemCount(), 2);
    });

    test('getCartKey() from headers', () {
      expect(response.getCartKey(), 'guest_abc123');
    });

    test('getCartHash()', () {
      expect(response.getCartHash(), 'hash_xyz');
    });

    test('getNotices()', () {
      expect(response.getNotices(), ['Item added']);
    });

    test('getCurrency()', () {
      expect(response.getCurrency()?['currency_symbol'], '\$');
    });

    test('getCacheStatus()', () {
      expect(response.getCacheStatus(), 'HIT');
    });

    test('isNotModified()', () {
      expect(response.isNotModified(), isFalse);
      final notMod = CoCartResponse({}, {}, 304);
      expect(notMod.isNotModified(), isTrue);
    });

    test('toObject() returns unmodifiable map', () {
      final obj = response.toObject();
      expect(obj['items_count'], 2);
      expect(() => obj['items_count'] = 3, throwsA(isA<UnsupportedError>()));
    });

    test('toJson() returns valid JSON', () {
      final json = response.toJson();
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['items_count'], 2);
    });
  });
}
