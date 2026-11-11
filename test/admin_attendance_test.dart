import 'package:cairo_coding_app/admin/admin_router.dart';
import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

void main() {
  setUpAll(setUpAppTests);

  Future<void> openAdmin(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester, AppFlavor.admin, adminRouterProvider);
    await signIn(tester, FakeAcademyStore.demoAdminEmail);
  }

  testWidgets('the overview flags students who missed the last two sessions', (tester) async {
    await openAdmin(tester);
    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.text('Youssef Samir'), findsOneWidget);
    expect(find.textContaining('CS140 · missed #'), findsWidgets);
  });

  testWidgets('admin corrects attendance for a past session', (tester) async {
    await openAdmin(tester);
    await tester.tap(find.text('Groups').first);
    await settle(tester);
    await openGroup(tester, 'CS140');
    await tester.tap(find.text('Schedule').last);
    await settle(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Attendance').first);
    await settle(tester);
    final dialog = find.byType(AlertDialog);
    expect(find.descendant(of: dialog, matching: find.text('Attendance · Session 1')), findsOneWidget);
    final before = find.descendant(of: dialog, matching: find.textContaining(' of 5 present'));
    final count = int.parse((tester.widget<Text>(before).data ?? '').split(' ').first);

    await tester.tap(find.descendant(of: dialog, matching: find.text('Youssef Samir')));
    await settle(tester);
    expect(find.descendant(of: dialog, matching: find.text('$count of 5 present')), findsNothing);
    await tester.tap(find.descendant(of: dialog, matching: find.text('Save')));
    await settle(tester);
    expect(find.text('Attendance saved'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('admin ticks who handed in a task and can take the task off the session', (tester) async {
    await openAdmin(tester);
    await tester.tap(find.text('Groups').first);
    await settle(tester);
    await openGroup(tester, 'CS140');
    await tester.tap(find.text('Schedule').last);
    await settle(tester);

    final withTask = find.ancestor(of: find.textContaining(RegExp(r'^Task \d+/5$')), matching: find.byType(TextButton));
    final before = withTask.evaluate().length;
    expect(before, greaterThan(0));
    await tester.tap(withTask.first);
    await settle(tester);
    final dialog = find.byType(AlertDialog);
    expect(find.descendant(of: dialog, matching: find.text('Task · Session 1')), findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.textContaining(' of 5 handed in')), findsOneWidget);
    await tester.tap(find.descendant(of: dialog, matching: find.text('Youssef Samir')));
    await tester.tap(find.descendant(of: dialog, matching: find.text('Save')));
    await settle(tester);
    expect(find.text('Task saved'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(withTask.first);
    await settle(tester);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('No task')));
    await settle(tester);
    expect(find.text('Task taken off this session'), findsOneWidget);
    expect(withTask.evaluate().length, before - 1);
  });

  testWidgets('admin posts an announcement to a group and can delete it', (tester) async {
    await openAdmin(tester);
    await tester.tap(find.text('Announcements').first);
    await settle(tester);
    expect(find.text('Welcome to CS140'), findsOneWidget);

    await tester.tap(find.text('Send'));
    await settle(tester);
    expect(find.text('Pick at least one group'), findsOneWidget);

    final fields = find.descendant(of: find.byType(Form), matching: find.byType(TextFormField));
    await tester.enterText(fields.at(0), 'No session on Thursday');
    await tester.enterText(fields.at(1), 'We meet again on Sunday.');
    await tester.tap(find.widgetWithText(FilterChip, 'CS150'));
    await settle(tester);
    await tester.tap(find.text('Send'));
    await settle(tester);
    expect(find.text('Announcement sent'), findsOneWidget);
    expect(find.text('No session on Thursday'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete').first);
    await settle(tester);
    await tester.tap(find.text('Delete').last);
    await settle(tester);
    expect(find.text('No session on Thursday'), findsNothing);
  });
}
