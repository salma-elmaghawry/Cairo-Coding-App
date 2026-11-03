import 'package:cairo_coding_app/admin/admin_router.dart';
import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

void main() {
  setUpAll(setUpAppTests);

  testWidgets('bulk paste does not show the name error from the single-student form', (tester) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpApp(tester, AppFlavor.admin, adminRouterProvider);
    await signIn(tester, FakeAcademyStore.demoAdminEmail);
    await tester.tap(find.text('Groups').first);
    await settle(tester);
    await tester.tap(find.text('Open group').first);
    await settle(tester);

    await tester.tap(find.text('Add student'));
    await settle(tester);
    expect(find.text('Name is required'), findsOneWidget);

    await tester.tap(find.text('Bulk paste'));
    await settle(tester);
    expect(find.text('Name is required'), findsNothing);
  });
}
