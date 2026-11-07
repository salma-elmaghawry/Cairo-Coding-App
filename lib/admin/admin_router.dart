import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/announcements/announcements_screen.dart';
import 'package:cairo_coding_app/admin/course_detail/course_detail_screen.dart';
import 'package:cairo_coding_app/admin/courses/courses_screen.dart';
import 'package:cairo_coding_app/admin/group_detail/group_detail_screen.dart';
import 'package:cairo_coding_app/admin/groups/groups_screen.dart';
import 'package:cairo_coding_app/admin/instructors/instructors_screen.dart';
import 'package:cairo_coding_app/admin/overview/overview_screen.dart';
import 'package:cairo_coding_app/admin/quizzes/admin_quizzes_screen.dart';
import 'package:cairo_coding_app/admin/quizzes/quiz_admin_providers.dart';
import 'package:cairo_coding_app/admin/quizzes/quiz_analytics_screen.dart';
import 'package:cairo_coding_app/admin/quizzes/quiz_builder_screen.dart';
import 'package:cairo_coding_app/admin/settings/admin_settings_screen.dart';
import 'package:cairo_coding_app/admin/shell/admin_scaffold.dart';
import 'package:cairo_coding_app/admin/students/students_screen.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/widgets/not_found_screen.dart';
import 'package:cairo_coding_app/shared/auth/blocked_screen.dart';
import 'package:cairo_coding_app/shared/auth/login_screen.dart';
import 'package:cairo_coding_app/shared/routing/auth_listenable.dart';
import 'package:cairo_coding_app/shared/splash_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final adminRouterProvider = Provider<GoRouter>((ref) {
  final auth = authListenable(ref);

  NoTransitionPage<void> page(Widget child) => NoTransitionPage(child: child);

  // A sidebar click would otherwise lose a half-written quiz without warning.
  Future<bool> confirmLeavingBuilder(BuildContext context, GoRouterState state) async {
    if (!ref.read(quizBuilderDirtyProvider)) return true;
    final leave = await showConfirmDialog(
      context,
      title: 'admin.quiz_builder.leave_title'.tr(),
      message: 'admin.quiz_builder.leave_message'.tr(),
      confirmLabel: 'admin.quiz_builder.leave'.tr(),
      cancelLabel: 'admin.quiz_builder.stay'.tr(),
      destructive: true,
    );
    if (leave) ref.read(quizBuilderDirtyProvider.notifier).set(false);
    return leave;
  }

  // `/<section>/:id` opens the first tab, and an unknown tab falls back to it.
  GoRoute tabbedDetail<T extends Enum>({
    required String section,
    required String param,
    required List<T> tabs,
    required String Function(String id) firstTab,
    required Widget Function(String id, T tab) builder,
  }) => GoRoute(
    path: ':$param',
    redirect: (_, state) => state.fullPath == '$section/:$param' ? firstTab(state.pathParameters[param]!) : null,
    routes: [
      GoRoute(
        path: ':tab',
        redirect: (_, state) =>
            tabs.asNameMap()[state.pathParameters['tab']] == null ? firstTab(state.pathParameters[param]!) : null,
        pageBuilder: (_, state) =>
            page(builder(state.pathParameters[param]!, tabs.asNameMap()[state.pathParameters['tab']]!)),
      ),
    ],
  );

  final router = GoRouter(
    initialLocation: AuthRoutes.splash,
    refreshListenable: auth,
    redirect: (context, state) => authRedirect(
      auth: auth.value,
      location: state.matchedLocation,
      isAllowed: (user) => user.isAdmin,
      home: AdminRoutes.overview,
    ),
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AdminRoutes.overview),
      GoRoute(path: AuthRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AuthRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AuthRoutes.blocked, builder: (_, _) => const BlockedScreen()),
      ShellRoute(
        builder: (context, state, child) => AdminScaffold(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: AdminRoutes.overview, pageBuilder: (_, _) => page(const OverviewScreen())),
          GoRoute(
            path: AdminRoutes.courses,
            pageBuilder: (_, _) => page(const CoursesScreen()),
            routes: [
              tabbedDetail(
                section: AdminRoutes.courses,
                param: 'courseId',
                tabs: CourseTab.values,
                firstTab: AdminRoutes.course,
                builder: (courseId, tab) => CourseDetailScreen(courseId: courseId, tab: tab),
              ),
            ],
          ),
          GoRoute(
            path: AdminRoutes.groups,
            pageBuilder: (_, _) => page(const GroupsScreen()),
            routes: [
              tabbedDetail(
                section: AdminRoutes.groups,
                param: 'groupId',
                tabs: GroupTab.values,
                firstTab: AdminRoutes.group,
                builder: (groupId, tab) => GroupDetailScreen(groupId: groupId, tab: tab),
              ),
            ],
          ),
          GoRoute(path: AdminRoutes.students, pageBuilder: (_, _) => page(const StudentsScreen())),
          GoRoute(path: AdminRoutes.instructors, pageBuilder: (_, _) => page(const InstructorsScreen())),
          GoRoute(
            path: AdminRoutes.quizzes,
            pageBuilder: (_, _) => page(const AdminQuizzesScreen()),
            routes: [
              // Listed before ':quizId' so "new" isn't read as a quiz id.
              GoRoute(
                path: 'new',
                onExit: confirmLeavingBuilder,
                pageBuilder: (_, _) => page(const QuizBuilderScreen()),
              ),
              GoRoute(
                path: ':quizId/edit',
                onExit: confirmLeavingBuilder,
                pageBuilder: (_, state) => page(QuizBuilderScreen(quizId: state.pathParameters['quizId'])),
              ),
              GoRoute(
                path: ':quizId/analytics',
                pageBuilder: (_, state) => page(QuizAnalyticsScreen(quizId: state.pathParameters['quizId']!)),
              ),
            ],
          ),
          GoRoute(path: AdminRoutes.announcements, pageBuilder: (_, _) => page(const AnnouncementsScreen())),
          GoRoute(path: AdminRoutes.settings, pageBuilder: (_, _) => page(const AdminSettingsScreen())),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
