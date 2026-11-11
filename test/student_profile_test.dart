import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:cairo_coding_app/data/models/certificate.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:cairo_coding_app/data/services/attendance.dart';
import 'package:cairo_coding_app/student/student_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

void main() {
  setUpAll(setUpAppTests);

  testWidgets('the Profile tab shows who the student is, their rates and their certificates', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final store = FakeAcademyStore();
    final mariam = store.studentByEmail(FakeAcademyStore.demoStudentEmail)!;
    final sessions = store.sessions.values.where((s) => mariam.groupIds.contains(s.groupId)).toList();
    final counted = Attendance.counted(sessions, DateTime.now());
    final attended = counted.where((s) => s.attendees!.contains(mariam.uid)).length;
    final withTask = sessions.where((s) => !s.isCancelled && s.hasTask).toList();
    final handedIn = withTask.where((s) => s.taskDoneBy!.contains(mariam.uid)).length;
    expect(withTask, isNotEmpty);

    await pumpApp(
      tester,
      AppFlavor.student,
      studentRouterProvider,
      overrides: [fakeAcademyStoreProvider.overrideWithValue(store)],
    );
    await signIn(tester, FakeAcademyStore.demoStudentEmail);
    await tester.tap(find.text('Profile').last);
    await settle(tester);

    expect(find.text('Mariam Adel'), findsOneWidget);
    expect(find.text(FakeAcademyStore.demoStudentEmail), findsOneWidget);
    expect(find.text('C++ · Tools and setup'), findsOneWidget);
    expect(find.text('CS140 · Workshop'), findsOneWidget);
    expect(find.text('$attended of ${counted.length} sessions'), findsOneWidget);
    expect(find.text('$handedIn of ${withTask.length} tasks'), findsOneWidget);
    expect(find.text('Programming Basics'), findsOneWidget);
    expect(find.textContaining('Issued '), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });

  test('certificates and tasks read back the way they were saved', () {
    final certificate = Certificate(title: 'C++', url: 'https://x.dev/c.pdf', issuedOn: DateTime(2026, 3, 9));
    expect(certificate.toMap()['issuedOn'], '2026-03-09');
    expect(Certificate.fromMap(certificate.toMap()), certificate);

    final student = Student.fromMap('s1', {
      'email': 'a@b.com',
      'certificates': [certificate.toMap()],
    });
    expect(student.certificates, [certificate]);
    expect(student.copyWith(name: 'A').certificates, [certificate]);

    final session = ClassSession.fromMap('x', {
      'groupId': 'g1',
      'startsAt': 0,
      'durationMin': 90,
      'taskDoneBy': ['s1'],
    });
    expect(session.taskDoneBy, ['s1']);
    expect(session.toMap().containsKey('taskDoneBy'), isFalse);
    expect(session.copyWith(topic: 'Loops').taskDoneBy, ['s1']);
    expect(session.withTaskDoneBy(null).hasTask, isFalse);
  });
}
