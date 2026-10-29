import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:cairo_coding_app/student/student_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

void main() {
  setUpAll(setUpAppTests);

  testWidgets('student signs in and moves between tabs', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpApp(tester, AppFlavor.student, studentRouterProvider);
    expect(find.text('Welcome back'), findsOneWidget);

    await signIn(tester, 'nobody@example.com');
    expect(find.text('Wrong email or password'), findsOneWidget);

    await signIn(tester, FakeAcademyStore.demoStudentEmail);
    expect(find.text('Hi, Mariam'), findsOneWidget);
    expect(find.text('Join meeting'), findsOneWidget);

    await tester.tap(find.text('Schedule').last);
    await settle(tester);
    expect(find.text('Upcoming'), findsOneWidget);

    await tester.tap(find.text('Recordings').last);
    await settle(tester);
    final newest = FakeAcademyStore().recordings.values.reduce((a, b) => a.recordedAt.isAfter(b.recordedAt) ? a : b);
    expect(find.text(newest.title), findsWidgets);

    await tester.tap(find.text('Settings').last);
    await settle(tester);
    expect(find.text('Mariam Adel'), findsOneWidget);
  });
}
