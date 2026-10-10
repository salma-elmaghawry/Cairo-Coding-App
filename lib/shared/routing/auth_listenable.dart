import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/app_user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

ValueListenable<AsyncValue<AppUser?>> authListenable(Ref ref) {
  final notifier = ValueNotifier<AsyncValue<AppUser?>>(ref.read(authStateProvider));
  ref.listen(authStateProvider, (_, next) => notifier.value = next);
  ref.onDispose(notifier.dispose);
  return notifier;
}

class AuthRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String blocked = '/blocked';

  static const Set<String> entry = {splash, login, blocked};
}

String? authRedirect({
  required AsyncValue<AppUser?> auth,
  required String location,
  required bool Function(AppUser user) isAllowed,
  required String home,
}) {
  if (auth.isLoading && !auth.hasValue) {
    return location == AuthRoutes.splash ? null : AuthRoutes.splash;
  }
  final user = auth.value;
  if (user == null) return location == AuthRoutes.login ? null : AuthRoutes.login;
  if (!isAllowed(user)) return location == AuthRoutes.blocked ? null : AuthRoutes.blocked;
  if (AuthRoutes.entry.contains(location) || location == '/') return home;
  return null;
}
