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

    test('accepts numeric strings', () {
      expect(() => validateProductId('1'), returnsNormally);
      expect(() => validateProductId('999'), returnsNormally);
    });

    test('accepts non-numeric strings as potential SKUs', () {
      expect(() => validateProductId('abc'), returnsNormally);
      expect(() => validateProductId('BLUE-SHIRT-L'), returnsNormally);
      expect(() => validateProductId('123ABC'), returnsNormally);
    });

    test('rejects empty string', () {
      expect(() => validateProductId(''), throwsA(isA<ValidationError>()));
      expect(() => validateProductId('   '), throwsA(isA<ValidationError>()));
    });

    test('rejects numeric strings that are not positive integers', () {
      expect(() => validateProductId('0'), throwsA(isA<ValidationError>()));
      expect(() => validateProductId('-1'), throwsA(isA<ValidationError>()));
      expect(() => validateProductId('1.5'), throwsA(isA<ValidationError>()));
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
      expect(() => validateEmail('notanemail'),
          throwsA(isA<ValidationError>()));
      expect(() => validateEmail('@no-user.com'),
          throwsA(isA<ValidationError>()));
      expect(() => validateEmail('no@'), throwsA(isA<ValidationError>()));
    });
  });
}
