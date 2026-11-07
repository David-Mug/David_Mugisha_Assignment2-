import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/form_fields.dart';
import '../data/providers.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/verify_email_screen.dart';
import '../features/auth/welcome_screen.dart';
import '../features/home/home_screen.dart';
import '../features/incident/incident_detail_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/report/new_report_screen.dart';
import '../features/reports/my_reports_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/staff/staff_dashboard_screen.dart';
import 'app_routes.dart';
import 'app_shell.dart';
import 'auth_redirect.dart';

/// The app's router.
///
/// How sign-in protection works:
///  1. [_RouterRefresh] listens to the auth and profile providers.
///  2. Whenever either changes, it tells go_router to re-run `redirect`.
///  3. `redirect` works out the [SessionState] and asks [authRedirect]
///     where the user is allowed to be.
/// So screens never navigate after sign-in/out — the router does it.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final profile = ref.read(currentUserProvider);
      return authRedirect(
        session: _sessionState(auth, profile),
        isStaff: profile.value?.isStaff ?? false,
        location: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const _SplashScreen()),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (_, _) => const VerifyEmailScreen(),
      ),

      // Bottom-navigation tabs. Each branch keeps its own navigation stack.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.reports,
                builder: (_, _) => const ReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Full-screen pages pushed over the tabs.
      GoRoute(
        path: AppRoutes.newReport,
        builder: (_, _) => const NewReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.incidentPattern,
        builder: (_, state) =>
            IncidentDetailScreen(incidentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.myReports,
        builder: (_, _) => const MyReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.staff,
        builder: (_, _) => const StaffDashboardScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Turns the raw provider values into one of four simple states.
SessionState _sessionState(AsyncValue auth, AsyncValue profile) {
  if (auth.isLoading && !auth.hasValue) return SessionState.loading;
  final user = auth.value;
  if (user == null) return SessionState.signedOut;
  if (!user.emailVerified) return SessionState.unverified;
  // Wait for the Firestore profile so we know whether they're staff.
  if (profile.isLoading && !profile.hasValue) return SessionState.loading;
  return SessionState.ready;
}

/// Bridges Riverpod → go_router: notifies the router when auth or the
/// user's profile (role) changes, so `redirect` runs again.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
    ref.listen(currentUserProvider, (_, _) => notifyListeners());
  }
}

/// Shown for a moment while Firebase restores the saved session.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 88),
            SizedBox(height: 32),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
