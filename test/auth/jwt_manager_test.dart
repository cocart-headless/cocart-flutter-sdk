import 'dart:convert';

import 'package:cocart/cocart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JwtResource', () {
    /// Creates a JWT token with the given expiry timestamp.
    String makeJwt(int exp) {
      final header = base64Url.encode(utf8.encode('{"alg":"HS256"}'));
      final payload = base64Url.encode(utf8.encode('{"exp":$exp}'));
      return '$header.$payload.signature';
    }

    test('isTokenExpired returns true when no token', () {
      final auth = AuthManager(CoCartOptions(), MemoryStorage());
      final jwt = JwtResource(
        CoCartHttpClient('https://example.com', CoCartOptions(), auth),
        auth,
      );
      expect(jwt.isTokenExpired(), isTrue);
    });

    test('isTokenExpired returns false for future token', () {
      final futureExp =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600;
      final token = makeJwt(futureExp);
      final auth = AuthManager(
        CoCartOptions(jwtToken: token),
        MemoryStorage(),
      );
      final jwt = JwtResource(
        CoCartHttpClient('https://example.com', CoCartOptions(), auth),
        auth,
      );
      expect(jwt.isTokenExpired(), isFalse);
    });

    test('isTokenExpired returns true for expired token', () {
      final pastExp =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 3600;
      final token = makeJwt(pastExp);
      final auth = AuthManager(
        CoCartOptions(jwtToken: token),
        MemoryStorage(),
      );
      final jwt = JwtResource(
        CoCartHttpClient('https://example.com', CoCartOptions(), auth),
        auth,
      );
      expect(jwt.isTokenExpired(), isTrue);
    });

    test('isTokenExpired respects leeway', () {
      // Token expires in 20 seconds — within default 30s leeway
      final soonExp =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 20;
      final token = makeJwt(soonExp);
      final auth = AuthManager(
        CoCartOptions(jwtToken: token),
        MemoryStorage(),
      );
      final jwt = JwtResource(
        CoCartHttpClient('https://example.com', CoCartOptions(), auth),
        auth,
      );
      expect(jwt.isTokenExpired(30), isTrue);
      expect(jwt.isTokenExpired(10), isFalse);
    });

    test('getTokenExpiry extracts exp claim', () {
      final exp = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600;
      final token = makeJwt(exp);
      final auth = AuthManager(
        CoCartOptions(jwtToken: token),
        MemoryStorage(),
      );
      final jwt = JwtResource(
        CoCartHttpClient('https://example.com', CoCartOptions(), auth),
        auth,
      );
      expect(jwt.getTokenExpiry(), exp);
    });

    test('hasTokens() reflects auth state', () {
      final auth = AuthManager(CoCartOptions(), MemoryStorage());
      final jwt = JwtResource(
        CoCartHttpClient('https://example.com', CoCartOptions(), auth),
        auth,
      );
      expect(jwt.hasTokens(), isFalse);

      auth.setJwtToken('token');
      expect(jwt.hasTokens(), isTrue);
    });

    test('auto-refresh flag', () {
      final auth = AuthManager(CoCartOptions(), MemoryStorage());
      final jwt = JwtResource(
        CoCartHttpClient('https://example.com', CoCartOptions(), auth),
        auth,
      );
      expect(jwt.isAutoRefreshEnabled(), isFalse);
      jwt.setAutoRefresh(true);
      expect(jwt.isAutoRefreshEnabled(), isTrue);
    });
  });
}
