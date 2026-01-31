
import 'package:flutter_test/flutter_test.dart';
import 'package:automata_pos/utils/validators.dart';

void main() {
  group('Validators', () {
    test('email validation', () {
      expect(Validators.email('test@example.com'), null);
      expect(Validators.email('invalid-email'), 'Invalid email address');
      expect(Validators.email(''), null); // Optional unless required
      expect(Validators.email(null), null);
    });

    test('phone validation', () {
      expect(Validators.phone('1234567890'), null);
      expect(Validators.phone('123'), 'Phone number must be 10 digits');
      expect(Validators.phone('abcdefghij'), 'Phone number must be 10 digits');
    });

    test('positiveNumber validation', () {
      expect(Validators.positiveNumber('10'), null);
      expect(Validators.positiveNumber('0'), 'Must be positive');
      expect(Validators.positiveNumber('-5'), 'Must be positive');
      expect(Validators.positiveNumber('abc'), 'Invalid number');
    });

    test('nonNegativeNumber validation', () {
      expect(Validators.nonNegativeNumber('10'), null);
      expect(Validators.nonNegativeNumber('0'), null);
      expect(Validators.nonNegativeNumber('-5'), 'Must be non-negative');
    });

    test('username validation', () {
      expect(Validators.username('user1'), null);
      expect(Validators.username('usr'), 'Min 4 characters');
      expect(Validators.username('user name'), 'Alphanumeric only (dot/underscore allowed)');
    });
  });
}
