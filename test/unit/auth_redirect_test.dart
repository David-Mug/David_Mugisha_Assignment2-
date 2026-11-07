import 'package:campus_incident/routing/app_routes.dart';
import 'package:campus_incident/routing/auth_redirect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? go(SessionState s, String location, {bool staff = false}) =>
      authRedirect(session: s, isStaff: staff, location: location);

  group('loading', () {
    test('shows the splash screen', () {
      expect(go(SessionState.loading, AppRoutes.home), AppRoutes.splash);
      expect(go(SessionState.loading, AppRoutes.splash), isNull);
    });
  });

  group('signed out', () {
    test('may open public pages', () {
      for (final route in AppRoutes.publicRoutes) {
        expect(go(SessionState.signedOut, route), isNull, reason: route);
      }
    });

    test('is sent to Welcome from protected pages', () {
      for (final route in [
        AppRoutes.home,
        AppRoutes.newReport,
        AppRoutes.incident('x'),
        AppRoutes.staff,
        AppRoutes.splash,
        AppRoutes.verifyEmail,
      ]) {
        expect(go(SessionState.signedOut, route), AppRoutes.welcome);
      }
    });
  });

  group('unverified', () {
    test('can only see Verify Email', () {
      expect(go(SessionState.unverified, AppRoutes.verifyEmail), isNull);
      expect(
        go(SessionState.unverified, AppRoutes.home),
        AppRoutes.verifyEmail,
      );
      expect(
        go(SessionState.unverified, AppRoutes.login),
        AppRoutes.verifyEmail,
      );
    });
  });

  group('ready', () {
    test('leaves auth pages for Home', () {
      expect(go(SessionState.ready, AppRoutes.login), AppRoutes.home);
      expect(go(SessionState.ready, AppRoutes.splash), AppRoutes.home);
      expect(go(SessionState.ready, AppRoutes.verifyEmail), AppRoutes.home);
    });

    test('can open app pages', () {
      expect(go(SessionState.ready, AppRoutes.home), isNull);
      expect(go(SessionState.ready, AppRoutes.newReport), isNull);
      expect(go(SessionState.ready, AppRoutes.incident('abc')), isNull);
    });

    test('students are blocked from the staff dashboard', () {
      expect(go(SessionState.ready, AppRoutes.staff), AppRoutes.home);
      expect(go(SessionState.ready, AppRoutes.staff, staff: true), isNull);
    });
  });
}
