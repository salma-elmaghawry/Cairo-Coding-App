import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:cairo_coding_app/admin/admin_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

void main() {
  setUpAll(setUpAppTests);

  testWidgets('admin edits a session, adds one from the course list and adds an instructor', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpApp(tester, AppFlavor.admin, adminRouterProvider);
    await signIn(tester, FakeAcademyStore.demoAdminEmail);
    await tester.tap(find.text('Groups').first);
    await settle(tester);
    await tester.tap(find.text('Open group').first);
    await settle(tester);
    await tester.tap(find.text('Schedule'));
    await settle(tester);
    expect(find.text('Intro To Programming & Datatypes'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await settle(tester);
    final dialog = find.byType(AlertDialog);
    final menus = find.descendant(of: dialog, matching: find.byType(DropdownMenu<String>));
    expect(find.descendant(of: dialog, matching: find.text('Edit session')), findsOneWidget);

    // CS140 is a C++ group, so only the C++ instructors are offered.
    await tester.tap(menus.last);
    await settle(tester);
    expect(find.text('Eng. Salma Elmaghawry'), findsWidgets);
    expect(find.text('Eng. Youssef Nabil'), findsNothing);
    await tester.tap(find.text('No instructor').last);
    await settle(tester);

    await tester.enterText(find.descendant(of: menus.first, matching: find.byType(TextField)), 'Operator precedence');
    await settle(tester);
    await tester.tap(find.descendant(of: dialog, matching: find.text('Save')));
    await settle(tester);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Operator precedence'), findsOneWidget);
    expect(find.text('Intro To Programming & Datatypes'), findsNothing);

    await tester.tap(find.text('Add session'));
    await settle(tester);
    expect(find.descendant(of: dialog, matching: find.text('Add session')), findsOneWidget);
    await tester.enterText(find.descendant(of: menus.first, matching: find.byType(TextField)), 'Unit');
    await settle(tester);
    await tester.tap(find.text('Intro To Unit Testing').last);
    await settle(tester);
    expect(find.descendant(of: dialog, matching: find.text('21')), findsOneWidget);

    await tester.tap(find.descendant(of: dialog, matching: find.text('Save')));
    await settle(tester);
    expect(find.text('Pick the session date and time'), findsOneWidget);
    await tester.tap(find.text('Select date'));
    await settle(tester);
    await tester.tap(find.text('OK'));
    await settle(tester);
    await tester.tap(find.text('OK'));
    await settle(tester);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextFormField)).last,
      'https://zoom.us/j/123',
    );
    await tester.tap(find.descendant(of: dialog, matching: find.text('Save')));
    await settle(tester);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Session added'), findsOneWidget);

    await tester.tap(find.text('Instructors').first);
    await settle(tester);
    expect(find.text('New instructor'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Eng. Amira Hassan');
    await tester.tap(find.text('Add instructor'));
    await settle(tester);
    expect(find.text('Eng. Amira Hassan'), findsOneWidget);
    expect(find.text('Not in a course yet'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'eng. amira hassan');
    await tester.tap(find.text('Add instructor'));
    await settle(tester);
    expect(find.text('This instructor is already in the list'), findsOneWidget);
  });
}
