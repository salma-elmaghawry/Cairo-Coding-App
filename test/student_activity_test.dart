import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:cairo_coding_app/data/models/app_user.dart';
import 'package:cairo_coding_app/student/student_activity.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final store = FakeAcademyStore();
  final farida = store.studentByEmail('farida.m@example.com')!;
  final next =
      (store.sessions.values.where((s) => s.groupId == 'cs140' && !s.isPast(DateTime.now())).toList()
            ..sort((a, b) => a.startsAt.compareTo(b.startsAt)))
          .first;

  Future<ProviderContainer> containerAt(DateTime now) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        ...fakeSourceOverrides,
        fakeAcademyStoreProvider.overrideWithValue(store),
        sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
        appFlavorProvider.overrideWithValue(AppFlavor.student),
        clockProvider.overrideWithValue(() => now),
        currentUserProvider.overrideWithValue(AppUser(profile: store.students[farida.uid]!, isAdmin: false)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('joining marks the student present only from 30 minutes before the start until the end', () async {
    final early = await containerAt(next.startsAt.subtract(const Duration(minutes: 40)));
    await early.read(studentActivityProvider).joined(next);
    expect(store.sessions[next.id]!.attendees, isNull);

    final onTime = await containerAt(next.startsAt.subtract(const Duration(minutes: 10)));
    await onTime.read(studentActivityProvider).joined(next);
    expect(store.sessions[next.id]!.attendees, [farida.uid]);

    final late = await containerAt(next.endsAt.add(const Duration(minutes: 1)));
    await late.read(studentActivityProvider).joined(store.sessions[next.id]!.copyWith(attendees: const []));
    expect(store.sessions[next.id]!.attendees, [farida.uid]);
  });

  test('opening a recording adds the student to its viewers once', () async {
    final recording = store.recordings.values.firstWhere((r) => r.groupId == 'cs140');
    expect(recording.viewers, isNot(contains(farida.uid)));
    final container = await containerAt(DateTime.now());
    await container.read(studentActivityProvider).watched(recording);
    expect(store.recordings[recording.id]!.viewers.where((uid) => uid == farida.uid), hasLength(1));
  });

  test('opening the app stamps a student who never signed in', () async {
    expect(store.students[farida.uid]!.lastSeenAt, isNull);
    final container = await containerAt(DateTime.now());
    await container.read(studentActivityProvider).seen();
    expect(store.students[farida.uid]!.lastSeenAt, isNotNull);
  });

  test('announcements count as unread until the student opens them', () async {
    final container = await containerAt(DateTime.now());
    container.listen(studentAnnouncementsProvider, (_, _) {});
    await container.read(studentAnnouncementsProvider.future);
    expect(container.read(unreadAnnouncementsProvider), 2);
    await container.read(announcementsReadAtProvider.notifier).markRead();
    expect(container.read(unreadAnnouncementsProvider), 0);
  });
}
