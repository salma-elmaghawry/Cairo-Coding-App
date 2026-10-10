import 'package:cairo_coding_app/core/utils/cairo_time.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/app_user.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:cairo_coding_app/data/models/weekly_slot.dart';
import 'package:cairo_coding_app/data/services/session_generator.dart';
import 'package:cairo_coding_app/shared/routing/auth_listenable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppUser _user({bool active = true, List<String> groups = const ['cs140'], bool admin = false}) => AppUser(
  profile: Student(uid: 'u1', name: 'Test', email: 't@example.com', phone: '', groupIds: groups, active: active),
  isAdmin: admin,
);

String? _redirect(AsyncValue<AppUser?> auth, String location) =>
    authRedirect(auth: auth, location: location, isAllowed: (user) => user.canUseStudentApp, home: '/home');

void main() {
  group('authRedirect', () {
    test('waits on splash while auth is loading', () {
      expect(_redirect(const AsyncLoading(), '/home'), AuthRoutes.splash);
      expect(_redirect(const AsyncLoading(), AuthRoutes.splash), isNull);
    });

    test('signed-out users go to login', () {
      expect(_redirect(const AsyncData(null), '/home'), AuthRoutes.login);
      expect(_redirect(const AsyncData(null), AuthRoutes.login), isNull);
    });

    test('inactive or group-less students are blocked', () {
      expect(_redirect(AsyncData(_user(active: false)), '/home'), AuthRoutes.blocked);
      expect(_redirect(AsyncData(_user(groups: const [])), '/home'), AuthRoutes.blocked);
    });

    test('allowed users leave entry screens for home and stay elsewhere', () {
      expect(_redirect(AsyncData(_user()), AuthRoutes.login), '/home');
      expect(_redirect(AsyncData(_user()), '/'), '/home');
      expect(_redirect(AsyncData(_user()), '/schedule'), isNull);
    });
  });

  setUpAll(CairoTime.init);

  group('SessionGenerator', () {
    final group = AcademyGroup(
      id: 'g',
      name: 'G',
      track: '',
      meetingLink: '',
      location: '',
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 10, 31),
      weeklySlots: const [
        WeeklySlot(weekday: DateTime.thursday, hour: 19, minute: 0, durationMin: 120),
        WeeklySlot(weekday: DateTime.sunday, hour: 19, minute: 0, durationMin: 120),
      ],
    );

    test('expands weekly slots into numbered sessions within the date range', () {
      final sessions = const SessionGenerator().generate(group: group, from: group.startDate);
      expect(sessions.length, 9);
      expect(sessions.first.startsAt, CairoTime.at(2026, 10, 1, 19));
      expect(sessions.map((s) => s.number), List.generate(9, (i) => i + 1));
    });

    test('keeps 7 PM Cairo time on both sides of the DST change', () {
      final acrossDst = group.copyWith(endDate: DateTime(2026, 11, 15));
      final sessions = const SessionGenerator().generate(group: acrossDst, from: acrossDst.startDate);
      for (final session in sessions) {
        final cairo = CairoTime.from(session.startsAt);
        expect((cairo.hour, cairo.minute), (19, 0));
      }
      final offsets = sessions.map((s) => CairoTime.from(s.startsAt).timeZoneOffset).toSet();
      expect(offsets.length, 2);
    });

    test('skips sessions before the start moment and continues numbering', () {
      final sessions = const SessionGenerator().generate(
        group: group,
        from: CairoTime.at(2026, 10, 15, 20),
        firstNumber: 6,
      );
      expect(sessions.first.startsAt, CairoTime.at(2026, 10, 18, 19));
      expect(sessions.first.number, 6);
    });
  });
}
