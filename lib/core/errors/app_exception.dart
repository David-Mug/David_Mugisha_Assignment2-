// firebase_auth re-exports FirebaseException from firebase_core.
import 'package:firebase_auth/firebase_auth.dart';

/// The single error type the UI has to deal with.
///
/// Repositories catch Firebase's exceptions and rethrow them as an
/// [AppException] with a message that is safe to show in a SnackBar, so
/// screens never need to know Firebase error codes.
class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;

  /// The original Firebase code (e.g. `wrong-password`), kept for debugging.
  final String? code;

  /// Converts any error into an [AppException].
  factory AppException.from(Object error) {
    if (error is AppException) return error;
    if (error is FirebaseAuthException) {
      return AppException.fromAuthCode(error.code);
    }
    if (error is FirebaseException) {
      return AppException.fromFirebaseCode(error.code);
    }
    return const AppException('Something went wrong. Please try again.');
  }

  /// Firebase Auth codes → friendly text.
  factory AppException.fromAuthCode(String code) {
    final message = switch (code) {
      'invalid-email' => 'That email address is not valid.',
      'user-disabled' =>
        'This account has been disabled. Contact campus support.',
      // Newer Firebase projects return `invalid-credential` for both a wrong
      // password and an unknown email, so users can't probe which emails exist.
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Incorrect email or password.',
      'email-already-in-use' => 'An account with this email already exists.',
      'weak-password' => 'That password is too weak.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment and try again.',
      'network-request-failed' =>
        'No internet connection. Check your network and try again.',
      'requires-recent-login' => 'Please sign in again to continue.',
      _ => 'Authentication failed. Please try again.',
    };
    return AppException(message, code: code);
  }

  /// Firestore / Storage codes → friendly text.
  factory AppException.fromFirebaseCode(String code) {
    final message = switch (code) {
      'permission-denied' ||
      'unauthorized' => "You don't have permission to do that.",
      'unavailable' =>
        'The service is unavailable. Check your connection and try again.',
      'not-found' || 'object-not-found' => 'That item no longer exists.',
      'failed-precondition' =>
        'This item was changed by someone else. Refresh and try again.',
      'canceled' => 'The operation was cancelled.',
      'quota-exceeded' => 'Storage limit reached. Please try again later.',
      _ => 'Something went wrong. Please try again.',
    };
    return AppException(message, code: code);
  }

  @override
  String toString() => message;
}
