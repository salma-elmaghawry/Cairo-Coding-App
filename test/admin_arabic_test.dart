import 'package:cairo_coding_app/admin/admin_router.dart';
import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

void main() {
  setUpAll(setUpAppTests);

  testWidgets('switching to Arabic retitles settings at once and keeps phone numbers in order', (tester) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpApp(tester, AppFlavor.admin, adminRouterProvider);
    await signIn(tester, FakeAcademyStore.demoAdminEmail);
    await tester.tap(find.text('Settings').first);
    await settle(tester);
    await tester.tap(find.text('العربية'));
    await settle(tester);

    expect(find.text('Settings'), findsNothing);
    expect(find.textContaining('التفضيلات'), findsOneWidget);

    await tester.tap(find.text('الطلاب').first);
    await settle(tester);
    expect(tester.widget<Text>(find.text('011 6789 8201')).textDirection, TextDirection.ltr);
  });
}
