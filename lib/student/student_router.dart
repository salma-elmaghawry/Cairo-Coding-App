import 'package:cairo_coding_app/core/widgets/not_found_screen.dart';
import 'package:cairo_coding_app/shared/auth/blocked_screen.dart';
import 'package:cairo_coding_app/shared/auth/login_screen.dart';
import 'package:cairo_coding_app/shared/routing/auth_listenable.dart';
import 'package:cairo_coding_app/shared/splash_screen.dart';
import 'package:cairo_coding_app/student/announcements/announcements_screen.dart';
import 'package:cairo_coding_app/student/home/home_screen.dart';
import 'package:cairo_coding_app/student/quizzes/leaderboard_screen.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_intro_screen.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_result_screen.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_take_screen.dart';
import 'package:cairo_coding_app/student/quizzes/quizzes_screen.dart';
import 'package:cairo_coding_app/student/recordings/recordings_screen.dart';
import 'package:cairo_coding_app/student/schedule/schedule_screen.dart';
import 'package:cairo_coding_app/student/settings/settings_screen.dart';
import 'package:cairo_coding_app/student/shell/student_shell.dart';
import 'package:cairo_coding_app/student/student_routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final studentRouterProvider = Provider<GoRouter>((ref) {
  final auth = authListenable(ref);
  // Quiz pages open above the bottom tabs, so taking a quiz fills the screen.
  final rootKey = GlobalKey<NavigatorState>();

  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: AuthRoutes.splash,
    refreshListenable: auth,
    redirect: (context, state) => authRedirect(
      auth: auth.value,
      location: state.matchedLocation,
      isAllowed: (user) => user.canUseStudentApp,
      home: StudentRoutes.home,
    ),
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => StudentRoutes.home),
      GoRoute(path: AuthRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AuthRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AuthRoutes.blocked, builder: (_, _) => const BlockedScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => StudentShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: StudentRoutes.home,
                builder: (_, _) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'announcements',
                    parentNavigatorKey: rootKey,
                    builder: (_, _) => const AnnouncementsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: StudentRoutes.schedule, builder: (_, _) => const ScheduleScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: StudentRoutes.quizzes,
                builder: (_, _) => const QuizzesScreen(),
                routes: [
                  // Listed before ':quizId' so "leaderboard" isn't read as a quiz id.
                  GoRoute(
                    path: 'leaderboard',
                    parentNavigatorKey: rootKey,
                    builder: (_, state) => LeaderboardScreen(quizId: state.uri.queryParameters['quiz']),
                  ),
                  GoRoute(
                    path: ':quizId',
                    parentNavigatorKey: rootKey,
                    builder: (_, state) => QuizIntroScreen(quizId: state.pathParameters['quizId']!),
                    routes: [
                      GoRoute(
                        path: 'take',
                        parentNavigatorKey: rootKey,
                        builder: (_, state) => QuizTakeScreen(quizId: state.pathParameters['quizId']!),
                      ),
                      GoRoute(
                        path: 'result/:number',
                        parentNavigatorKey: rootKey,
                        builder: (_, state) => QuizResultScreen(
                          quizId: state.pathParameters['quizId']!,
                          attemptNumber: int.tryParse(state.pathParameters['number']!) ?? 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: StudentRoutes.recordings, builder: (_, _) => const RecordingsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: StudentRoutes.settings, builder: (_, _) => const SettingsScreen())],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
