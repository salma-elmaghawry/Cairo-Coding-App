import 'package:cairo_coding_app/admin/admin_router.dart';
import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

void main() {
  setUpAll(setUpAppTests);

  testWidgets('admin opens a course and walks through its tabs', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpApp(tester, AppFlavor.admin, adminRouterProvider);
    await signIn(tester, FakeAcademyStore.demoAdminEmail);
    await tester.tap(find.text('Open course').first);
    await settle(tester);
    expect(find.text('22 sessions · 2 groups'), findsOneWidget);
    expect(find.text('CS140'), findsOneWidget);
    expect(find.text('CS150'), findsOneWidget);

    await tester.tap(find.text('Sessions').last);
    await settle(tester);
    expect(find.text('Intro To Programming & Datatypes'), findsOneWidget);
    expect(find.text('File Handling & Exception Handling'), findsOneWidget);

    await tester.tap(find.text('Students').last);
    await settle(tester);
    expect(find.text('Mariam Adel'), findsOneWidget);
    expect(find.text('Hana Ibrahim'), findsOneWidget);
    expect(find.text('Ziad Mahmoud'), findsNothing);

    await tester.tap(find.text('Instructors').last);
    await settle(tester);
    expect(find.text('Eng. Salma Elmaghawry'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await settle(tester);
    await tester.tap(find.text('Eng. Youssef Nabil').last);
    await settle(tester);
    await tester.tap(find.text('Add to course'));
    await settle(tester);
    expect(find.text('Every instructor is already in this course.'), findsOneWidget);
    expect(find.text('Eng. Youssef Nabil'), findsOneWidget);
  });
}
