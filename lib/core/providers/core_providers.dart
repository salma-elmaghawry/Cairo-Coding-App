import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Overridden in bootstrap'),
);

final appFlavorProvider = Provider<AppFlavor>((ref) => throw UnimplementedError('Overridden in bootstrap'));

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final minuteTickerProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  final now = ref.watch(clockProvider);
  yield now();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => now());
});
