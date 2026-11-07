import 'package:campus_incident/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.aluEmail', () {
    test('accepts student and staff ALU domains', () {
      expect(Validators.aluEmail('amina@alustudent.com'), isNull);
      expect(Validators.aluEmail('j.doe@alueducation.com'), isNull);
    });

    test('is case- and whitespace-insensitive', () {
      expect(Validators.aluEmail('  Amina@ALUStudent.com '), isNull);
    });

    test('rejects non-ALU domains', () {
      expect(Validators.aluEmail('amina@gmail.com'), contains('ALU email'));
      // Look-alike domain must not pass.
      expect(Validators.aluEmail('amina@alustudent.com.evil.io'), isNotNull);
    });

    test('rejects empty and malformed input', () {
      expect(Validators.aluEmail(''), 'Email is required');
      expect(
        Validators.aluEmail('not-an-email'),
        'Enter a valid email address',
      );
    });
  });

  group('Validators.password', () {
    test('requires 8+ chars with a letter and a number', () {
      expect(Validators.password('short1'), isNotNull);
      expect(Validators.password('allletters'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
      expect(Validators.password('campus2026'), isNull);
    });

    test('confirmPassword must match', () {
      expect(
        Validators.confirmPassword('abc', 'abd'),
        'Passwords do not match',
      );
      expect(Validators.confirmPassword('abc', 'abc'), isNull);
    });
  });

  group('Validators.maxLength', () {
    test('enforces required and max length', () {
      expect(
        Validators.maxLength('  ', 10, field: 'Title'),
        'Title is required',
      );
      expect(Validators.maxLength('a' * 11, 10, field: 'Title'), isNotNull);
      expect(Validators.maxLength('Leaking tap', 80, field: 'Title'), isNull);
    });
  });
}
