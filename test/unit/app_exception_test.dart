import 'package:campus_incident/core/errors/app_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppException', () {
    test('maps auth codes to friendly messages', () {
      expect(
        AppException.from(FirebaseAuthException(code: 'invalid-credential'))
            .message,
        'Incorrect email or password.',
      );
      expect(
        AppException.from(FirebaseAuthException(code: 'email-already-in-use'))
            .message,
        'An account with this email already exists.',
      );
    });

    test('maps Firestore codes and unknown errors', () {
      expect(
        AppException.from(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        ).message,
        "You don't have permission to do that.",
      );
      expect(
        AppException.from(StateError('boom')).message,
        'Something went wrong. Please try again.',
      );
    });
  });
}
