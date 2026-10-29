import 'package:cairo_coding_app/admin/admin_router.dart';
import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

void main() {
  setUpAll(setUpAppTests);

  testWidgets('admin searches and filters every student and adds one to a group', (tester) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpApp(tester, AppFlavor.admin, adminRouterProvider);
    await signIn(tester, FakeAcademyStore.demoAdminEmail);
    await tester.tap(find.text('Students').first);
    await settle(tester);
    expect(find.text('10 students'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Tools and setup'));
    await settle(tester);
    expect(find.text('4 students'), findsOneWidget);
    expect(find.text('Ziad Mahmoud'), findsOneWidget);
    expect(find.text('Omar Khaled'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All courses'));
    await tester.enterText(find.byType(TextField).first, '0159012');
    await settle(tester);
    expect(find.text('1 student'), findsOneWidget);
    expect(find.text('Hana Ibrahim'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '');
    await settle(tester);

    await tester.tap(find.text('Add students'));
    await settle(tester);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await settle(tester);
    await tester.tap(find.text('CS150 · C++').last);
    await settle(tester);
    final dialog = find.byType(AlertDialog);
    final fields = find.descendant(of: dialog, matching: find.byType(TextFormField));
    await tester.enterText(fields.at(0), 'Laila Samy');
    await tester.enterText(fields.at(1), 'laila.s@example.com');
    await tester.tap(find.text('Add student'));
    await settle(tester);
    await tester.tap(find.text('Close'));
    await settle(tester);
    expect(find.text('11 students'), findsOneWidget);
    expect(find.text('Laila Samy'), findsOneWidget);
  });
}
