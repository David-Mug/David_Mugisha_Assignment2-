import 'package:flutter/material.dart';

/// Single source of truth for every colour in CampusCare.
///
/// Screens never hard-code hex values; they read from here (or from the
/// [ThemeData] built in `app_theme.dart`). Changing the brand colour therefore
/// means editing one file.
abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF6738F5);
  static const secondary = Color(0xFF8B5CF6);
  static const primarySoft = Color(0xFFEFE9FF); // tinted backgrounds, chips

  // Surfaces & text
  static const background = Color(0xFFF8F8FC);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE7E7F0);
  static const textPrimary = Color(0xFF171B35);
  static const textSecondary = Color(0xFF777D96);

  // Feedback
  static const success = Color(0xFF22A45D);
  static const successSoft = Color(0xFFE4F6EB);
  static const warning = Color(0xFFD99A00);
  static const warningSoft = Color(0xFFFFF4D6);
  static const error = Color(0xFFE5484D);
  static const errorSoft = Color(0xFFFDECEC);
  static const info = Color(0xFF3B82F6);
  static const infoSoft = Color(0xFFE8F0FE);

  /// Purple gradient used for the hero card and primary call-to-action.
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7A4DFB), Color(0xFF9C7BFA)],
  );
}
