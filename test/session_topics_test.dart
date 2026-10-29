import 'dart:async';

import 'package:cairo_coding_app/core/utils/cairo_time.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_source.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:cairo_coding_app/data/models/weekly_slot.dart';
import 'package:cairo_coding_app/data/repositories/academy_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(CairoTime.init);

  test('regenerating sessions keeps their names and instructors in course order', () async {
    final now = DateTime(2026, 10, 28, 12);
    final store = FakeAcademyStore(now: now);
    final repository = AcademyRepository(FakeAcademySource(store), clock: () => now);
    List<ClassSession> upcoming() =>
        store.sessions.values.where((s) => s.groupId == 'cs150' && !s.isPast(now)).toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    final before = upcoming();
    for (final (index, session) in before.take(3).indexed) {
      await repository.updateSession(
        session,
        topic: ' Topic ${index + 1} ',
        number: session.number!,
        startsAt: session.startsAt,
        instructor: 'Eng. Salma',
        meetingLink: '',
      );
    }

    final group = store.groups['cs150']!;
    await repository.saveSlotsAndGenerate(group, [
      for (final slot in group.weeklySlots)
        WeeklySlot(weekday: slot.weekday, hour: slot.hour + 1, minute: slot.minute, durationMin: slot.durationMin),
    ]);

    final after = upcoming();
    expect(after.first.startsAt, before.first.startsAt.add(const Duration(hours: 1)));
    expect(after.take(4).map((s) => (s.topic, s.instructor)), [
      ('Topic 1', 'Eng. Salma'),
      ('Topic 2', 'Eng. Salma'),
      ('Topic 3', 'Eng. Salma'),
      ('', ''),
    ]);
  });

  test('new sessions take their names from the course list and hand-added sessions survive', () async {
    final now = DateTime(2026, 10, 28, 12);
    final store = FakeAcademyStore(now: now);
    final repository = AcademyRepository(FakeAcademySource(store), clock: () => now);
    final group = store.groups['cs150']!;
    final course = store.courses[group.courseId]!;

    await repository.addSession(
      group,
      topic: ' Revision ',
      number: 2,
      startsAt: DateTime(2026, 11, 3, 18),
      instructor: 'Eng. Salma Elmaghawry',
      meetingLink: ' https://zoom.us/j/1 ',
    );
    await repository.saveSlotsAndGenerate(group, group.weeklySlots, course: course);

    final upcoming = store.sessions.values.where((s) => s.groupId == 'cs150' && !s.isPast(now)).toList();
    final manual = upcoming.singleWhere((s) => s.manual);
    expect((manual.topic, manual.number, manual.meetingLinkOverride), ('Revision', 2, 'https://zoom.us/j/1'));
    final generated = upcoming.where((s) => !s.manual && s.number! <= course.sessionTitles.length);
    expect(generated, isNotEmpty);
    for (final session in generated) {
      expect(session.topic, course.sessionTitles[session.number! - 1]);
    }
  });

  test('moving a generated session marks it moved, a hand-added one keeps its status', () async {
    final now = DateTime(2026, 10, 28, 12);
    final store = FakeAcademyStore(now: now);
    final repository = AcademyRepository(FakeAcademySource(store), clock: () => now);
    final generated = store.sessions.values.firstWhere(
      (s) => s.groupId == 'cs150' && !s.isPast(now) && s.status == SessionStatus.scheduled,
    );
    Future<void> moveByAnHour(ClassSession session) => repository.updateSession(
      session,
      topic: session.topic,
      number: session.number!,
      startsAt: session.startsAt.add(const Duration(hours: 1)),
      instructor: session.instructor,
      meetingLink: '',
    );

    await moveByAnHour(generated);
    expect(store.sessions[generated.id]!.status, SessionStatus.moved);

    await repository.addSession(
      store.groups['cs150']!,
      topic: 'Revision',
      number: 30,
      startsAt: DateTime(2026, 11, 3, 18),
      instructor: '',
      meetingLink: '',
    );
    final manual = store.sessions.values.singleWhere((s) => s.manual);
    await moveByAnHour(manual);
    expect(store.sessions[manual.id]!.status, SessionStatus.scheduled);
  });

  test('a course lists each student of its groups once', () async {
    final store = FakeAcademyStore(now: DateTime(2026, 10, 28, 12));
    final repository = AcademyRepository(FakeAcademySource(store));

    await repository.addStudents('cs150', [const NewStudent(email: 'mariam.adel@example.com')]);
    // Not `.first`: it waits for the cancel, and the fake store's streams only finish cancelling on the next change.
    final firstValue = Completer<List<Student>>();
    final subscription = repository.watchStudentsOf(['cs140', 'cs150']).listen((value) {
      if (!firstValue.isCompleted) firstValue.complete(value);
    });
    final students = await firstValue.future;
    unawaited(subscription.cancel());

    expect(students.where((s) => s.email == FakeAcademyStore.demoStudentEmail), hasLength(1));
    expect(students.map((s) => s.name), containsAll(['Omar Khaled', 'Hana Ibrahim']));
    expect(students.map((s) => s.name), isNot(contains('Ziad Mahmoud')));
  });

  test('instructors are listed by name and can be removed', () async {
    final store = FakeAcademyStore(now: DateTime(2026, 10, 28, 12));
    final repository = AcademyRepository(FakeAcademySource(store));

    await repository.addInstructor('  Eng. Amira Hassan ');
    final names = (await repository.watchInstructors().first).map((i) => i.name);
    expect(names, ['Eng. Amira Hassan', 'Eng. Salma Elmaghawry', 'Eng. Youssef Nabil']);

    final amira = (await repository.watchInstructors().first).first;
    await repository.deleteInstructor(amira);
    expect((await repository.watchInstructors().first).map((i) => i.name), isNot(contains('Eng. Amira Hassan')));
  });

  test('editing an instructor updates their courses, groups and the name on their sessions', () async {
    final store = FakeAcademyStore(now: DateTime(2026, 10, 28, 12));
    final repository = AcademyRepository(FakeAcademySource(store));
    final youssef = store.instructors['instructor_youssef']!;
    final named = store.sessions.values.where((s) => s.instructor == youssef.name).map((s) => s.id).toList();
    expect(named, isNotEmpty);

    await repository.updateInstructor(
      youssef,
      youssef.copyWith(
        name: ' Eng. Youssef Nabil Ali ',
        email: ' Youssef.N@Example.com',
        phone: ' 012 7777 1618 ',
        groupIds: ['workshop', 'cs150'],
      ),
      courses: await repository.watchCourses().first,
      courseIds: {'cpp'},
    );

    final saved = store.instructors[youssef.id]!;
    expect(saved.name, 'Eng. Youssef Nabil Ali');
    expect(saved.email, 'youssef.n@example.com');
    expect(saved.phone, '012 7777 1618');
    expect(saved.groupIds, ['workshop', 'cs150']);
    expect(store.courses['cpp']!.instructorIds, ['instructor_salma', youssef.id]);
    expect(store.courses['tools']!.instructorIds, isEmpty);
    expect(named.map((id) => store.sessions[id]!.instructor).toSet(), {'Eng. Youssef Nabil Ali'});
    expect(store.sessions.values.where((s) => s.instructor == 'Eng. Salma Elmaghawry'), isNotEmpty);
  });
}
