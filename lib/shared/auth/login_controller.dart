import 'dart:async';

import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final loginControllerProvider = AsyncNotifierProvider.autoDispose<LoginController, void>(LoginController.new);

class LoginController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).signIn(email: email, password: password);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}
