import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:cairo_coding_app/admin/admin_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

void main() {
  setUpAll(setUpAppTests);

  testWidgets('admin names a session, picks its instructor and adds a new instructor', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpApp(tester, AppFlavor.admin, adminRouterProvider);
    await signIn(tester, FakeAcademyStore.demoAdminEmail);
    await tester.tap(find.text('Open group').first);
    await settle(tester);
    await tester.tap(find.text('Schedule'));
    await settle(tester);
    expect(find.text('Intro to C++'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await settle(tester);
    final dialog = find.byType(AlertDialog);
    expect(find.descendant(of: dialog, matching: find.text('Session details')), findsOneWidget);

    await tester.enterText(find.descendant(of: dialog, matching: find.byType(TextFormField)), 'Operator precedence');
    await tester.tap(find.descendant(of: dialog, matching: find.text('Eng. Salma Elmaghawry')));
    await settle(tester);
    await tester.tap(find.text('Eng. Youssef Nabil').last);
    await settle(tester);
    await tester.tap(find.descendant(of: dialog, matching: find.text('Save')));
    await settle(tester);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Operator precedence'), findsOneWidget);
    expect(find.text('by Eng. Youssef Nabil'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await settle(tester);
    expect(find.text('Instructors'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Eng. Amira Hassan');
    await tester.tap(find.text('Add instructor'));
    await settle(tester);
    expect(find.text('Eng. Amira Hassan'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'eng. amira hassan');
    await tester.tap(find.text('Add instructor'));
    await settle(tester);
    expect(find.text('This instructor is already in the list'), findsOneWidget);
  });
}
