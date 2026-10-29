import 'package:cairo_coding_app/admin/admin_router.dart';
import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

void main() {
  setUpAll(setUpAppTests);

  testWidgets('admin edits a student but not their sign-in email', (tester) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpApp(tester, AppFlavor.admin, adminRouterProvider);
    await signIn(tester, FakeAcademyStore.demoAdminEmail);
    await tester.tap(find.text('Students').first);
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'hana');
    await settle(tester);

    await tester.tap(find.byTooltip('Edit student'));
    await settle(tester);
    final dialog = find.byType(AlertDialog);
    final fields = find.descendant(of: dialog, matching: find.byType(TextFormField));
    final email = tester.widget<TextField>(find.descendant(of: fields.at(1), matching: find.byType(TextField)));
    expect(email.controller!.text, 'hana.i@example.com');
    expect(email.readOnly, isTrue);

    await tester.enterText(fields.at(0), ' ');
    await tester.tap(find.descendant(of: dialog, matching: find.text('Save')));
    await settle(tester);
    expect(find.text('Name is required'), findsOneWidget);

    await tester.enterText(fields.at(0), 'Hana Ibrahim Ali ');
    await tester.enterText(fields.at(2), ' 015 9012 0000 ');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Workshop · Tools and setup'));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await tester.tap(find.descendant(of: dialog, matching: find.text('Save')));
    await settle(tester);

    expect(find.text('Student saved'), findsOneWidget);
    expect(find.text('Hana Ibrahim Ali'), findsOneWidget);
    expect(find.text('015 9012 0000'), findsOneWidget);
    expect(find.text('hana.i@example.com'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'CS150'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Workshop'), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);
  });
}
