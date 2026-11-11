import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/announcement.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/data/models/recording.dart';
import 'package:cairo_coding_app/data/services/attendance.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the student app writes about the student: attendance, recordings opened, and when they were last here.
/// Each write is best effort: the dashboard misses one data point if it fails, and the student never notices.
class StudentActivity {
  StudentActivity(this._ref);

  final Ref _ref;

  /// Students may mark themselves present from this long before a session starts; the rules say the same.
  static const Duration joinWindow = Duration(minutes: 30);

  String? get _uid => _ref.read(currentUserProvider)?.uid;

  Future<void> joined(ClassSession session) async {
    final uid = _uid;
    final now = _ref.read(clockProvider)();
    final open = !now.isBefore(session.startsAt.subtract(joinWindow)) && now.isBefore(session.endsAt);
    if (uid == null || !open || session.isCancelled || (session.attendees?.contains(uid) ?? false)) return;
    await _ref.read(academyRepositoryProvider).markAttended(session, uid);
  }

  Future<void> watched(Recording recording) async {
    final uid = _uid;
    if (uid == null || recording.viewers.contains(uid)) return;
    await _ref.read(academyRepositoryProvider).markViewed(recording, uid);
  }

  /// At most every few hours, so opening the app doesn't write each time.
  Future<void> seen() async {
    final user = _ref.read(currentUserProvider);
    final last = user?.profile.lastSeenAt;
    final now = _ref.read(clockProvider)();
    if (user == null || (last != null && now.difference(last).inHours < 6)) return;
    await _ref.read(academyRepositoryProvider).touchLastSeen(user.uid);
  }
}

final studentActivityProvider = Provider<StudentActivity>(StudentActivity.new);

/// The student's attendance over the sessions that have it, from 0 to 1; null before any.
final myAttendanceProvider = Provider<double?>((ref) {
  final uid = ref.watch(currentUserProvider.select((user) => user?.uid));
  final sessions = ref.watch(studentSessionsProvider).value ?? const <ClassSession>[];
  if (uid == null) return null;
  return Attendance.studentRate(uid, Attendance.counted(sessions, ref.watch(clockProvider)()));
});

final studentAnnouncementsProvider = StreamProvider<List<Announcement>>((ref) {
  final ids = ref.watch(studentGroupIdsProvider);
  return ref.watch(academyRepositoryProvider).watchAnnouncements(ids);
});

/// When the student last opened the announcements, kept on the phone.
final announcementsReadAtProvider = NotifierProvider<AnnouncementsReadAt, DateTime>(AnnouncementsReadAt.new);

class AnnouncementsReadAt extends Notifier<DateTime> {
  static const String _key = 'announcements_read_at';

  @override
  DateTime build() => DateTime.fromMillisecondsSinceEpoch(ref.watch(sharedPreferencesProvider).getInt(_key) ?? 0);

  Future<void> markRead() async {
    final now = ref.read(clockProvider)();
    state = now;
    await ref.read(sharedPreferencesProvider).setInt(_key, now.millisecondsSinceEpoch);
  }
}

final unreadAnnouncementsProvider = Provider<int>((ref) {
  final readAt = ref.watch(announcementsReadAtProvider);
  final announcements = ref.watch(studentAnnouncementsProvider).value ?? const <Announcement>[];
  return announcements.where((a) => a.createdAt.isAfter(readAt)).length;
});
