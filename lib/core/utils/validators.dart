import '../constants/app_constants.dart';

/// Pure validation functions used by `TextFormField.validator`.
///
/// Each returns `null` when the value is valid, or an error message to show
/// under the field. Being plain functions makes them trivial to unit-test.
abstract final class Validators {
  static final _emailPattern = RegExp(r'^[\w.+-]+@([\w-]+\.)+[a-zA-Z]{2,}$');

  static String? required(String? value, {String field = 'This field'}) =>
      (value == null || value.trim().isEmpty) ? '$field is required' : null;

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Full name is required';
    if (v.length < 3) return 'Enter your full name';
    if (v.length > AppConstants.nameMaxLength) return 'Name is too long';
    return null;
  }

  /// Valid email format AND an ALU domain (student or staff).
  static String? aluEmail(String? value) {
    final v = value?.trim().toLowerCase() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(v)) return 'Enter a valid email address';
    if (!isAluEmail(v)) {
      return 'Use your ALU email (@${AppConstants.studentEmailDomain} '
          'or @${AppConstants.staffEmailDomain})';
    }
    return null;
  }

  static bool isAluEmail(String email) {
    final domain = email.trim().toLowerCase().split('@').last;
    return AppConstants.allowedEmailDomains.contains(domain);
  }

  /// At least 8 characters with a letter and a number.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < AppConstants.minPasswordLength) {
      return 'Use at least ${AppConstants.minPasswordLength} characters';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Include at least one letter and one number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    return value == original ? null : 'Passwords do not match';
  }

  static String? maxLength(String? value, int max, {required String field}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$field is required';
    if (v.length > max) return '$field must be $max characters or fewer';
    return null;
  }
}
