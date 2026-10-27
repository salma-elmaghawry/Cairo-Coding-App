import 'dart:convert';

import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/core/const/app_assets.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/firebase_options.dart';
import 'package:cairo_coding_app/student/reminders/reminder_planner.dart';
import 'package:cairo_coding_app/student/reminders/reminder_providers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const String _syncTask = 'reminder-sync';

/// Re-reads the schedule every few hours, so a session moved or cancelled while the app is closed
/// doesn't leave a reminder at the old time.
Future<void> registerReminderSync() async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  await Workmanager().initialize(reminderSyncDispatcher);
  await Workmanager().registerPeriodicTask(
    _syncTask,
    _syncTask,
    frequency: const Duration(hours: 6),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}

@pragma('vm:entry-point')
void reminderSyncDispatcher() {
  Workmanager().executeTask((task, inputData) => _syncReminders().catchError((Object _) => false));
}

Future<bool> _syncReminders() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appFlavorProvider.overrideWithValue(AppFlavor.student),
    ],
  );

  try {
    final scheduler = container.read(reminderSchedulerProvider);
    final user = await container.read(authRepositoryProvider).authStateChanges().first;
    if (!container.read(remindersEnabledProvider) || user == null || !user.canUseStudentApp) {
      await scheduler.clear();
      return true;
    }

    final repository = container.read(academyRepositoryProvider);
    final groupIds = user.profile.groupIds;
    final now = DateTime.now();
    final sessions = await repository.sessionsBetween(groupIds, now, now.add(ReminderPlanner.horizon));
    if (sessions is! Ok<List<ClassSession>>) return false;
    final groups = await repository.watchGroups(ids: groupIds).first;

    final languageCode = _savedLanguage(prefs);
    await initializeDateFormatting(languageCode);
    final translations = await rootBundle.loadString('${AppAssets.translations}/$languageCode.json');

    await scheduler.sync(
      sessions.value,
      planner: ReminderPlanner(translate: _jsonTranslate(jsonDecode(translations)), languageCode: languageCode),
      groupNames: {for (final group in groups) group.id: group.name},
      now: now,
    );
    return true;
  } finally {
    container.dispose();
  }
}

// easy_localization keeps the language the student picked under this key; until then it follows the phone.
String _savedLanguage(SharedPreferences prefs) {
  final saved = prefs.getString('locale') ?? PlatformDispatcher.instance.locale.languageCode;
  return saved.startsWith('ar') ? 'ar' : 'en';
}

Translate _jsonTranslate(Object? translations) => (key, [args = const []]) {
  var node = translations;
  for (final part in key.split('.')) {
    node = node is Map ? node[part] : null;
  }
  var text = node is String ? node : key;
  for (final arg in args) {
    text = text.replaceFirst('{}', arg);
  }
  return text;
};
