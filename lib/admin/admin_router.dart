import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/course_detail/course_detail_screen.dart';
import 'package:cairo_coding_app/admin/courses/courses_screen.dart';
import 'package:cairo_coding_app/admin/group_detail/group_detail_screen.dart';
import 'package:cairo_coding_app/admin/groups/groups_screen.dart';
import 'package:cairo_coding_app/admin/instructors/instructors_screen.dart';
import 'package:cairo_coding_app/admin/settings/admin_settings_screen.dart';
import 'package:cairo_coding_app/admin/shell/admin_scaffold.dart';
import 'package:cairo_coding_app/core/widgets/not_found_screen.dart';
import 'package:cairo_coding_app/shared/auth/blocked_screen.dart';
import 'package:cairo_coding_app/shared/auth/login_screen.dart';
import 'package:cairo_coding_app/shared/routing/auth_listenable.dart';
import 'package:cairo_coding_app/shared/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final adminRouterProvider = Provider<GoRouter>((ref) {
  final auth = authListenable(ref);

  NoTransitionPage<void> page(Widget child) => NoTransitionPage(child: child);

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
      home: AdminRoutes.courses,
    ),
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AdminRoutes.courses),
      GoRoute(path: AuthRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AuthRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AuthRoutes.blocked, builder: (_, _) => const BlockedScreen()),
      ShellRoute(
        builder: (context, state, child) => AdminScaffold(location: state.matchedLocation, child: child),
        routes: [
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
          GoRoute(path: AdminRoutes.instructors, pageBuilder: (_, _) => page(const InstructorsScreen())),
          GoRoute(path: AdminRoutes.settings, pageBuilder: (_, _) => page(const AdminSettingsScreen())),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
