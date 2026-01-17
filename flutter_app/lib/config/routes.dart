import 'package:flutter/material.dart'; // Actually needed for BuildContext? Yes.
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // Needed for AuthProvider? Yes, in AppRouter.router(AuthProvider authProvider).
import '../providers/auth_provider.dart';
import '../screens/landing_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/verify_otp_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/onboarding_details_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/timetable_screen.dart';
import '../screens/events_screen.dart';
import '../screens/knowledge_base_screen.dart';
import '../screens/reminders_screen.dart';
import '../screens/study_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/app_shell.dart';
import '../utils/constants.dart';

class AppRouter {
  static GoRouter? _router;

  static GoRouter router(AuthProvider authProvider) {
    _router ??= GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isOnboarded = authProvider.isOnboarded;
        final isLoading = authProvider.isLoading;

        final isGoingToAuth = state.matchedLocation == '/auth';
        final isGoingToLanding = state.matchedLocation == '/';
        final isGoingToRoleSelection =
            state.matchedLocation == '/role-selection';
        final isGoingToOnboardingDetails =
            state.matchedLocation == '/onboarding-details';
        final isGoingToResetPassword =
            state.matchedLocation == '/reset-password';
        final isGoingToVerifyOtp =
            state.matchedLocation.startsWith('/verify-otp');

        if (authProvider.isPasswordRecovery) {
          if (isGoingToResetPassword) return null;
          return '/reset-password';
        }

        if (isLoading) return null;

        if (!isAuthenticated) {
          if (isGoingToAuth ||
              isGoingToLanding ||
              isGoingToVerifyOtp ||
              isGoingToResetPassword) return null;
          return '/';
        }

        if (!isOnboarded) {
          // If already on one of the onboarding steps, stay there
          if (isGoingToRoleSelection || isGoingToOnboardingDetails) return null;
          // Otherwise, start with role selection
          return '/role-selection';
        }

        // If onboarded, don't allow going back to auth/onboarding pages
        if (isGoingToLanding ||
            isGoingToAuth ||
            isGoingToRoleSelection ||
            isGoingToOnboardingDetails) {
          return '/app/dashboard';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LandingScreen(),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: '/role-selection',
          builder: (context, state) => const RoleSelectionScreen(),
        ),
        GoRoute(
          path: '/onboarding-details',
          builder: (context, state) {
            final role =
                state.uri.queryParameters['role'] ?? AppConstants.roleStudent;
            return OnboardingDetailsScreen(role: role);
          },
        ),
        GoRoute(
          path: '/verify-otp',
          builder: (context, state) {
            final email = state.uri.queryParameters['email'] ?? '';
            return VerifyOtpScreen(email: email);
          },
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => const ResetPasswordScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) =>
              AppShell(currentPath: state.matchedLocation, child: child),
          routes: [
            GoRoute(
              path: '/app/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/app/chat',
              builder: (context, state) => const ChatScreen(),
            ),
            GoRoute(
              path: '/app/timetable',
              builder: (context, state) => const TimetableScreen(),
            ),
            GoRoute(
              path: '/app/events-notices',
              builder: (context, state) => const EventsScreen(),
            ),
            GoRoute(
              path: '/app/knowledge-base',
              builder: (context, state) => const KnowledgeBaseScreen(),
            ),
            GoRoute(
              path: '/app/reminders',
              builder: (context, state) => const RemindersScreen(),
            ),
            GoRoute(
              path: '/app/study-planner',
              builder: (context, state) => const StudyScreen(),
            ),
            GoRoute(
              path: '/app/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    );
    return _router!;
  }
}
