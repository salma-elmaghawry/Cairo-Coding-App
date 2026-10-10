import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/group_detail/group_detail_screen.dart';
import 'package:cairo_coding_app/admin/groups/groups_screen.dart';
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

  final router = GoRouter(
    initialLocation: AuthRoutes.splash,
    refreshListenable: auth,
    redirect: (context, state) => authRedirect(
      auth: auth.value,
      location: state.matchedLocation,
      isAllowed: (user) => user.isAdmin,
      home: AdminRoutes.groups,
    ),
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AdminRoutes.groups),
      GoRoute(path: AuthRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AuthRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AuthRoutes.blocked, builder: (_, _) => const BlockedScreen()),
      ShellRoute(
        builder: (context, state, child) => AdminScaffold(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: AdminRoutes.groups,
            pageBuilder: (_, _) => page(const GroupsScreen()),
            routes: [
              GoRoute(
                path: ':groupId',
                redirect: (_, state) => state.fullPath == '${AdminRoutes.groups}/:groupId'
                    ? AdminRoutes.group(state.pathParameters['groupId']!)
                    : null,
                routes: [
                  GoRoute(
                    path: ':tab',
                    redirect: (_, state) {
                      final tab = GroupTab.values.asNameMap()[state.pathParameters['tab']];
                      return tab == null ? AdminRoutes.group(state.pathParameters['groupId']!) : null;
                    },
                    pageBuilder: (_, state) => page(
                      GroupDetailScreen(
                        groupId: state.pathParameters['groupId']!,
                        tab: GroupTab.values.byName(state.pathParameters['tab']!),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(path: AdminRoutes.settings, pageBuilder: (_, _) => page(const AdminSettingsScreen())),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
