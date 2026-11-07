import 'app_routes.dart';

/// Where the user is in the sign-in journey.
enum SessionState {
  /// Still asking Firebase whether someone is signed in.
  loading,
  signedOut,

  /// Signed in, but hasn't clicked the link in the verification email.
  unverified,

  /// Signed in and verified — allowed into the app.
  ready,
}

/// Decides where go_router should send the user. Returns null to stay put.
///
/// Kept as a plain function (no Firebase, no widgets) so every rule below
/// is covered by unit tests in `test/unit/auth_redirect_test.dart`.
String? authRedirect({
  required SessionState session,
  required bool isStaff,
  required String location,
}) {
  final isPublic = AppRoutes.publicRoutes.contains(location);

  switch (session) {
    case SessionState.loading:
      return location == AppRoutes.splash ? null : AppRoutes.splash;

    case SessionState.signedOut:
      return isPublic ? null : AppRoutes.welcome;

    case SessionState.unverified:
      return location == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;

    case SessionState.ready:
      // Signed-in users have no business on the welcome/login/splash pages.
      if (isPublic ||
          location == AppRoutes.splash ||
          location == AppRoutes.verifyEmail) {
        return AppRoutes.home;
      }
      // Students can't open staff pages, even by typing the URL.
      if (location.startsWith(AppRoutes.staff) && !isStaff) {
        return AppRoutes.home;
      }
      return null;
  }
}
