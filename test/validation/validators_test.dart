import 'package:cocart/cocart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateProductId', () {
    test('accepts positive integers', () {
      expect(() => validateProductId(1), returnsNormally);
      expect(() => validateProductId(999), returnsNormally);
    });

    test('rejects zero', () {
      expect(() => validateProductId(0), throwsA(isA<ValidationError>()));
    });

    test('rejects negative', () {
      expect(() => validateProductId(-1), throwsA(isA<ValidationError>()));
    });
  });

  group('validateQuantity', () {
    test('accepts positive numbers', () {
      expect(() => validateQuantity(1), returnsNormally);
      expect(() => validateQuantity(0.5), returnsNormally);
    });

    test('rejects zero', () {
      expect(() => validateQuantity(0), throwsA(isA<ValidationError>()));
    });

    test('rejects negative', () {
      expect(() => validateQuantity(-1), throwsA(isA<ValidationError>()));
    });
  });

  group('validateEmail', () {
    test('accepts valid emails', () {
      expect(() => validateEmail('test@example.com'), returnsNormally);
      expect(() => validateEmail('user@domain.co.uk'), returnsNormally);
    });

    test('rejects invalid emails', () {
      expect(() => validateEmail('notanemail'), throwsA(isA<ValidationError>()));
      expect(() => validateEmail('@no-user.com'), throwsA(isA<ValidationError>()));
      expect(() => validateEmail('no@'), throwsA(isA<ValidationError>()));
    });
  });
}
