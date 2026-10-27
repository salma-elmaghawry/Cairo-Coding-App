import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/student/reminders/reminder_planner.dart';
import 'package:cairo_coding_app/student/reminders/reminder_scheduler.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) => ReminderScheduler());

final remindersEnabledProvider = NotifierProvider<RemindersEnabledNotifier, bool>(RemindersEnabledNotifier.new);

class RemindersEnabledNotifier extends Notifier<bool> {
  static const String _key = 'reminders_enabled';
  static const String _askedKey = 'reminders_permission_asked';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  /// Returns false when the phone blocks notifications for the app.
  Future<bool> set(bool enabled) async {
    state = enabled;
    await ref.read(sharedPreferencesProvider).setBool(_key, enabled);
    return !enabled || await ref.read(reminderSchedulerProvider).requestPermission();
  }

  Future<void> askPermissionOnce() async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (!state || (prefs.getBool(_askedKey) ?? false)) return;
    await prefs.setBool(_askedKey, true);
    await ref.read(reminderSchedulerProvider).requestPermission();
  }
}

/// Keeps the phone's scheduled reminders in step with the student's sessions while the app is open.
final reminderSyncProvider = FutureProvider.autoDispose.family<void, String>((ref, languageCode) async {
  final scheduler = ref.watch(reminderSchedulerProvider);
  final user = ref.watch(currentUserProvider);
  if (!ref.watch(remindersEnabledProvider) || user == null || !user.canUseStudentApp) return scheduler.clear();

  final sessions = ref.watch(studentSessionsProvider).value;
  if (sessions == null) return;
  final groups = ref.watch(groupsByIdProvider);
  await ref.read(remindersEnabledProvider.notifier).askPermissionOnce();

  await scheduler.sync(
    sessions,
    planner: ReminderPlanner(
      translate: (key, [args = const []]) => key.tr(args: args),
      languageCode: languageCode,
    ),
    groupNames: {for (final MapEntry(:key, :value) in groups.entries) key: value.name},
    now: ref.read(clockProvider)(),
  );
});
