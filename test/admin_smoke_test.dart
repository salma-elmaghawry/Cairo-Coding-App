import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:cairo_coding_app/admin/admin_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

void main() {
  setUpAll(setUpAppTests);

  testWidgets('admin signs in, opens a group and switches tabs', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpApp(tester, AppFlavor.admin, adminRouterProvider);
    expect(find.text('Admin dashboard'), findsOneWidget);

    await signIn(tester, FakeAcademyStore.demoAdminEmail);
    expect(find.text('Groups'), findsWidgets);
    expect(find.text('CS140'), findsOneWidget);

    await tester.tap(find.text('Open group').first);
    await settle(tester);
    expect(find.text('Mariam Adel'), findsOneWidget);

    await tester.tap(find.text('Schedule'));
    await settle(tester);
    expect(find.text('Weekly slots'), findsOneWidget);

    await tester.tap(find.text('Recordings'));
    await settle(tester);
    expect(find.text('Add recording'), findsOneWidget);
  });
}
