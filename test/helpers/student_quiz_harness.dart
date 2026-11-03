import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:cairo_coding_app/student/student_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> openQuizzes(WidgetTester tester, {DateTime Function()? clock, Locale? locale}) async {
  await pumpApp(
    tester,
    AppFlavor.student,
    studentRouterProvider,
    overrides: [if (clock != null) clockProvider.overrideWithValue(clock)],
    startLocale: locale ?? const Locale('en'),
  );
  await signIn(tester, FakeAcademyStore.demoStudentEmail);
  await tester.tap(find.text('Quizzes').last);
  await settle(tester);
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).first);
  await tester.pump();
  await tester.tap(find.text(text).first);
  await settle(tester);
}

Future<void> openLoops(WidgetTester tester) async {
  await tapText(tester, 'Loops in C++');
  await tapText(tester, 'Start quiz');
}

Future<void> openGit(WidgetTester tester) async {
  await tester.scrollUntilVisible(find.text('Git basics'), 200, scrollable: find.byType(Scrollable).last);
  await tapText(tester, 'Git basics');
  await tapText(tester, 'Start quiz');
}

Future<void> answer(WidgetTester tester, String option) async {
  await tapText(tester, option);
  await tapText(tester, 'Next');
}
