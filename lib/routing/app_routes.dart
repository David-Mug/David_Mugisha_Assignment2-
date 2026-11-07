/// Every route path in one place, so a typo can't create a broken link.
abstract final class AppRoutes {
  /// Shown for a moment at launch while Firebase restores the session.
  static const splash = '/splash';

  // Public (no sign-in needed)
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  static const publicRoutes = {welcome, login, register, forgotPassword};

  // Signed in, email not yet verified
  static const verifyEmail = '/verify-email';

  // Signed in + verified — student tabs
  static const home = '/home';
  static const reports = '/reports';
  static const profile = '/profile';

  // Signed in + verified — full-screen pages
  static const newReport = '/report/new';
  static String incident(String id) => '/incidents/$id';
  static const incidentPattern = '/incidents/:id';
  static const myReports = '/my-reports';

  // Staff only
  static const staff = '/staff';
}
