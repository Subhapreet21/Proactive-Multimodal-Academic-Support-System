// Actually needed for BuildContext? Yes.
import 'package:go_router/go_router.dart';
// Needed for AuthProvider? Yes, in AppRouter.router(AuthProvider authProvider).
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
import '../screens/virtual_tour_screen.dart';
import '../screens/admin_users_screen.dart';
import '../screens/daily_lecture_prep_screen.dart';
import '../screens/faculty_attendance_screen.dart';
import '../screens/student_attendance_screen.dart';
import '../screens/admin_attendance_screen.dart';
import '../screens/quiz_list_screen.dart';
import '../screens/quiz_active_screen.dart';
import '../screens/quiz_result_screen.dart';
import '../screens/faculty_quiz_mgmt_screen.dart';
import '../models/quiz_model.dart';
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
              isGoingToResetPassword) {
            return null;
          }
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
              path: '/app/quizzes',
              builder: (context, state) => const QuizListScreen(),
              routes: [
                GoRoute(
                  path: 'active',
                  builder: (context, state) {
                    if (state.extra is Map<String, dynamic>) {
                      final extra = state.extra as Map<String, dynamic>;
                      return QuizActiveScreen(
                        quiz: extra['quiz'] as Quiz,
                        reviewAttempt: extra['reviewAttempt'] as QuizAttempt?,
                      );
                    }
                    final quiz = state.extra as Quiz;
                    return QuizActiveScreen(quiz: quiz);
                  },
                ),
                GoRoute(
                  path: 'result',
                  builder: (context, state) {
                    final resultData = state.extra as Map<String, dynamic>;
                    return QuizResultScreen(resultData: resultData);
                  },
                ),
                GoRoute(
                  path: 'manage',
                  builder: (context, state) => const FacultyQuizMgmtScreen(),
                ),
              ],
            ),
            GoRoute(
              path: '/app/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/app/virtual-tour',
              builder: (context, state) => const VirtualTourScreen(),
            ),
            // Admin Routes
            GoRoute(
              path: '/app/admin/users',
              builder: (context, state) => const AdminUsersScreen(),
            ),
            GoRoute(
              path: '/app/admin/attendance',
              builder: (context, state) => const AdminAttendanceScreen(),
            ),
            GoRoute(
              path: '/app/faculty/daily-prep',
              builder: (context, state) => const DailyLecturePrepScreen(),
            ),
            GoRoute(
              path: '/app/faculty/attendance',
              builder: (context, state) => const FacultyAttendanceScreen(),
            ),
            GoRoute(
              path: '/app/student/attendance',
              builder: (context, state) => const StudentAttendanceScreen(),
            ),
          ],
        ),
      ],
    );
    return _router!;
  }
}
