import 'package:cairo_coding_app/app.dart';
import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/core/const/app_assets.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/utils/cairo_time.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/student/reminders/reminder_planner.dart';
import 'package:cairo_coding_app/student/reminders/reminder_providers.dart';
import 'package:cairo_coding_app/student/reminders/reminder_scheduler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(WidgetTester tester, AppFlavor flavor, Provider<GoRouter> router) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appFlavorProvider.overrideWithValue(flavor),
        reminderSchedulerProvider.overrideWithValue(SilentReminderScheduler()),
        ...fakeSourceOverrides,
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        saveLocale: false,
        path: AppAssets.translations,
        child: CairoCodingApp(routerProvider: router),
      ),
    ),
  );
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

class SilentReminderScheduler implements ReminderScheduler {
  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> sync(
    List<ClassSession> sessions, {
    required ReminderPlanner planner,
    required Map<String, String> groupNames,
    required DateTime now,
  }) async {}

  @override
  Future<void> clear() async {}
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> signIn(WidgetTester tester, String email) async {
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), 'password123');
  await settle(tester);
  await tester.tap(find.text('Sign in'));
  await settle(tester);
}

Future<void> setUpAppTests() async {
  SharedPreferences.setMockInitialValues({});
  EasyLocalization.logger.enableBuildModes = [];
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting();
  CairoTime.init();
}
