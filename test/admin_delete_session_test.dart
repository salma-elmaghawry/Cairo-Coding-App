import 'package:cairo_coding_app/admin/admin_router.dart';
import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_source.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/data/repositories/academy_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

void main() {
  setUpAll(setUpAppTests);

  test('a deleted session is gone from the sessions students load', () async {
    final store = FakeAcademyStore(now: DateTime(2026, 10, 28, 12));
    final repository = AcademyRepository(FakeAcademySource(store));
    final extra = store.sessions.values.firstWhere((s) => s.status == SessionStatus.extra);

    await repository.deleteSession(extra);

    final sessions = await repository.watchSessions([extra.groupId]).first;
    expect(sessions.map((s) => s.id), isNot(contains(extra.id)));
    expect(sessions, isNotEmpty);
  });

  testWidgets('admin deletes a session after confirming', (tester) async {
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

    await tester.tap(find.byTooltip('Delete session').first);
    await settle(tester);
    expect(find.text('Delete Session 1?'), findsOneWidget);
    await tester.tap(find.text('Cancel').last);
    await settle(tester);
    expect(find.text('Intro To Programming & Datatypes'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete session').first);
    await settle(tester);
    await tester.tap(find.text('Delete'));
    await settle(tester);
    expect(find.text('Session deleted'), findsOneWidget);
    expect(find.text('Intro To Programming & Datatypes'), findsNothing);
    expect(find.text('Operators In C++'), findsOneWidget);
  });
}
