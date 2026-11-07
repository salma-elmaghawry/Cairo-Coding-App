import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:cairo_coding_app/data/models/announcement.dart';
import 'package:cairo_coding_app/data/models/student.dart';

/// Attendance, recording views, sign-ins and announcements for the demo, so the dashboard has something to show.
/// A few students are behind on purpose: Youssef missed the last two CS140 sessions, Karim stopped coming before
/// he was deactivated, and Farida never signed in.
void seedFakeActivity(FakeAcademyStore store, DateTime now) {
  final byEmail = {for (final student in store.students.values) student.email: student};
  final neverSignedIn = {byEmail['farida.m@example.com']?.uid};
  final stoppedComing = byEmail['karim.a@example.com']?.uid;
  final missedLatest = byEmail['youssef.s@example.com']?.uid;

  for (final student in store.students.values.toList()) {
    final group = store.groups[student.groupIds.first];
    store.students[student.uid] = Student(
      uid: student.uid,
      name: student.name,
      email: student.email,
      phone: student.phone,
      groupIds: student.groupIds,
      active: student.active,
      createdAt: group?.startDate,
      lastSeenAt: neverSignedIn.contains(student.uid) ? null : now.subtract(Duration(hours: 2 + student.name.length)),
    );
  }

  for (final groupId in store.groups.keys) {
    final members = store.students.values.where((s) => s.groupIds.contains(groupId) && s.active);
    final everyone = store.students.values.where((s) => s.groupIds.contains(groupId));
    final past = store.sessions.values.where((s) => s.groupId == groupId && s.isPast(now) && !s.isCancelled).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    for (final (index, session) in past.indexed) {
      final fromEnd = past.length - index;
      final attendees = [
        for (final student in everyone)
          if (!neverSignedIn.contains(student.uid) &&
              !(student.uid == stoppedComing && fromEnd <= 4) &&
              !(student.uid == missedLatest && fromEnd <= 2) &&
              // Everyone else misses now and then.
              (student.name.length + index) % 7 != 0)
            student.uid,
      ];
      store.sessions[session.id] = session.copyWith(attendees: attendees);
    }

    for (final recording in store.recordings.values.where((r) => r.groupId == groupId).toList()) {
      final viewers = [
        for (final student in members)
          if (!neverSignedIn.contains(student.uid) && (student.name.length + recording.sessionNumber) % 5 != 0)
            student.uid,
      ];
      store.recordings[recording.id] = recording.copyWith(
        viewers: viewers,
        addedAt: recording.recordedAt.add(const Duration(hours: 3)),
      );
    }
  }

  final announcements = [
    Announcement(
      id: store.newId('announcement'),
      title: 'Welcome to CS140',
      body: 'Sessions are on Google Meet every Sunday and Thursday at 7 PM. Recordings go up the same night.',
      groupIds: const ['cs140'],
      createdAt: now.subtract(const Duration(days: 9)),
    ),
    Announcement(
      id: store.newId('announcement'),
      title: 'New quiz: Loops in C++',
      body: 'It closes in a few days. Your first attempt is the one that counts on the leaderboard.',
      groupIds: const ['cs140', 'workshop'],
      createdAt: now.subtract(const Duration(hours: 20)),
    ),
  ];
  for (final announcement in announcements) {
    store.announcements[announcement.id] = announcement;
  }
}
