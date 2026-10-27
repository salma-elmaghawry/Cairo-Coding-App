import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/student/reminders/reminder_planner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(initializeDateFormatting);

  final now = DateTime(2026, 11, 2, 12);
  final planner = ReminderPlanner(translate: (key, [args = const []]) => [key, ...args].join('|'), languageCode: 'en');

  ClassSession session(String id, DateTime startsAt, {SessionStatus status = SessionStatus.scheduled}) =>
      ClassSession(id: id, groupId: 'cs140', number: 8, startsAt: startsAt, durationMin: 120, status: status);

  test('plans a reminder a day before and an hour before each session', () {
    final startsAt = DateTime(2026, 11, 5, 19);
    final reminders = planner.plan([session('s8', startsAt)], groupNames: {'cs140': 'CS140'}, now: now);
    final time = DateFormat.jm('en').format(startsAt);

    expect(reminders.map((r) => r.fireAt), [DateTime(2026, 11, 4, 19), DateTime(2026, 11, 5, 18)]);
    expect(reminders.first.title, 'reminders.tomorrow|session.title|8|$time');
    expect(reminders.last.title, 'reminders.soon|session.title|8|$time');
    expect(reminders.first.body, 'reminders.body_group|CS140');
    expect(reminders.last.visibleFor, const Duration(hours: 3));
  });

  test('skips cancelled sessions and reminders whose time already passed', () {
    final reminders = planner.plan(
      [
        session('cancelled', DateTime(2026, 11, 5, 19), status: SessionStatus.cancelled),
        session('tonight', DateTime(2026, 11, 2, 19)),
      ],
      groupNames: const {},
      now: now,
    );

    expect(reminders, hasLength(1));
    expect(reminders.single.fireAt, DateTime(2026, 11, 2, 18));
    expect(reminders.single.body, 'reminders.body');
  });

  test('ignores sessions beyond the two-week horizon', () {
    final reminders = planner.plan([session('later', DateTime(2026, 11, 20, 19))], groupNames: const {}, now: now);

    expect(reminders, isEmpty);
  });

  test('gives every reminder an id that stays the same between syncs', () {
    final sessions = [session('s8', DateTime(2026, 11, 5, 19)), session('s9', DateTime(2026, 11, 8, 19))];
    final first = planner.plan(sessions, groupNames: const {}, now: now).map((r) => r.id).toList();
    final second = planner.plan(sessions, groupNames: const {}, now: now).map((r) => r.id).toList();

    expect(second, first);
    expect(first.toSet(), hasLength(4));
  });
}
