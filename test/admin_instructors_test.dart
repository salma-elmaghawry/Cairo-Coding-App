import 'package:cairo_coding_app/admin/admin_router.dart';
import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

void main() {
  setUpAll(setUpAppTests);

  testWidgets('admin sees how many groups each instructor teaches and edits one', (tester) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpApp(tester, AppFlavor.admin, adminRouterProvider);
    await signIn(tester, FakeAcademyStore.demoAdminEmail);
    await tester.tap(find.text('Instructors').first);
    await settle(tester);
    // CS120 is archived, so it doesn't count.
    expect(find.text('2 groups'), findsOneWidget);
    expect(find.text('1 group'), findsOneWidget);
    expect(find.text('salma@example.com'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'CS120'), findsNothing);

    await tester.tap(find.byTooltip('Edit instructor').last);
    await settle(tester);
    final dialog = find.byType(AlertDialog);
    final fields = find.descendant(of: dialog, matching: find.byType(TextFormField));
    expect(find.text('A new name also replaces the old one on their sessions.'), findsNothing);
    await tester.enterText(fields.at(0), 'Eng. Youssef Nabil Ali');
    await tester.pump();
    expect(find.text('A new name also replaces the old one on their sessions.'), findsOneWidget);

    await tester.enterText(fields.at(1), 'salma@example.com');
    await tester.tap(find.descendant(of: dialog, matching: find.text('Save')));
    await settle(tester);
    expect(find.text('Another instructor already has this email'), findsOneWidget);

    await tester.enterText(fields.at(1), 'youssef.n@example.com');
    await tester.tap(find.widgetWithText(ChoiceChip, 'C++'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'CS150 · C++'));
    await tester.pump();
    await tester.tap(find.descendant(of: dialog, matching: find.text('Save')));
    await settle(tester);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Instructor saved'), findsOneWidget);
    expect(find.text('Eng. Youssef Nabil Ali'), findsOneWidget);
    expect(find.text('youssef.n@example.com'), findsOneWidget);
    expect(find.text('2 groups'), findsNWidgets(2));
    expect(find.widgetWithText(ActionChip, 'C++'), findsNWidgets(2));
  });
}
