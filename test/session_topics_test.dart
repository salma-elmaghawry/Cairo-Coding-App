import 'package:cairo_coding_app/core/utils/cairo_time.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_source.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
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
      await repository.updateSessionDetails(session, topic: ' Topic ${index + 1} ', instructor: 'Eng. Salma');
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
}
