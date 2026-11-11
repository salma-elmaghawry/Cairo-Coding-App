import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/quizzes/quiz_admin_providers.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/data/models/quiz_board.dart';
import 'package:cairo_coding_app/data/models/recording.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:cairo_coding_app/data/services/attendance.dart';
import 'package:cairo_coding_app/data/services/quiz_averages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum StudentStanding { active, invited, inactive }

/// Everything the dashboard says about one group, worked out once from its live data.
class GroupInsights {
  GroupInsights({
    required this.group,
    required this.students,
    required this.sessions,
    required this.recordings,
    required this.boards,
    required this.quizzes,
    required this.now,
  });

  final AcademyGroup group;

  /// Everyone in the group, deactivated students too.
  final List<Student> students;

  /// Oldest first.
  final List<ClassSession> sessions;
  final List<Recording> recordings;
  final List<QuizBoard> boards;
  final Map<String, Quiz> quizzes;
  final DateTime now;

  late final List<Student> members = students.where((s) => s.active).toList();
  late final Set<String> memberIds = {for (final student in members) student.uid};
  late final List<ClassSession> held = sessions.where((s) => !s.isCancelled).toList();
  late final int done = held.where((s) => s.isPast(now)).length;
  int get total => held.length;
  late final ClassSession? next = held.where((s) => !s.isPast(now)).firstOrNull;
  late final List<ClassSession> counted = Attendance.counted(sessions, now);
  late final double? attendance = Attendance.groupRate(counted, memberIds);
  late final double? quizAverage = QuizAverages.group(boards, quizzes);
  late final List<Quiz> groupQuizzes = quizzes.values.where((q) => q.groupIds.contains(group.id)).toList()
    ..sort((a, b) => b.opensAt.compareTo(a.opensAt));

  /// Sessions that ended more than a day ago and still have no recording.
  late final List<ClassSession> missingRecordings = () {
    final recorded = {for (final recording in recordings) recording.sessionNumber};
    final dayAgo = now.subtract(const Duration(days: 1));
    return held.where((s) => s.number != null && s.endsAt.isBefore(dayAgo) && !recorded.contains(s.number)).toList();
  }();

  /// Students who missed at least the last two sessions, with the sessions they missed.
  late final List<(Student, List<ClassSession>)> fallingBehind = [
    for (final student in members)
      if (Attendance.missedStreak(student.uid, counted) case final missed when missed.length >= 2) (student, missed),
  ];

  /// Sessions per week, from the weekly slots.
  int get weeklySessions => group.weeklySlots.length;

  /// Ends within two weeks, so the dashboard can say so.
  bool get endingSoon => !group.archived && group.endDate.difference(now).inDays <= 14 && group.endDate.isAfter(now);

  double? attendanceOf(String uid) => Attendance.studentRate(uid, counted);

  double? quizAverageOf(String uid) => QuizAverages.student(uid, boards, quizzes);

  int viewersOf(Recording recording) => recording.viewers.where(memberIds.contains).length;

  int attendedOf(ClassSession session) => session.attendees?.where(memberIds.contains).length ?? 0;

  int taskDoneOf(ClassSession session) => session.taskDoneBy?.where(memberIds.contains).length ?? 0;

  QuizBoard? boardOf(String quizId) => boards.where((b) => b.quizId == quizId).firstOrNull;

  static StudentStanding standingOf(Student student) => !student.active
      ? StudentStanding.inactive
      : (student.lastSeenAt == null ? StudentStanding.invited : StudentStanding.active);
}

final adminGroupBoardsProvider = StreamProvider.autoDispose.family<List<QuizBoard>, String>(
  (ref, groupId) => ref.watch(quizRepositoryProvider).watchBoards(groupId),
);

final adminQuizzesByIdProvider = Provider<Map<String, Quiz>>(
  (ref) => {for (final quiz in ref.watch(adminQuizzesProvider).value ?? const <Quiz>[]) quiz.id: quiz},
);

/// Null until the group, its students and its sessions have loaded.
final groupInsightsProvider = Provider.autoDispose.family<GroupInsights?, String>((ref, groupId) {
  final group = ref.watch(groupProvider(groupId)).value;
  final students = ref.watch(allStudentsProvider).value;
  final sessions = ref.watch(groupSessionsProvider(groupId)).value;
  if (group == null || students == null || sessions == null) return null;
  return GroupInsights(
    group: group,
    students: students.where((s) => s.groupIds.contains(groupId)).toList(),
    sessions: sessions,
    recordings: ref.watch(groupRecordingsProvider(groupId)).value ?? const [],
    boards: ref.watch(adminGroupBoardsProvider(groupId)).value ?? const [],
    quizzes: ref.watch(adminQuizzesByIdProvider),
    now: ref.watch(clockProvider)(),
  );
});

/// The insights of every group that isn't archived, once each has loaded.
final activeInsightsProvider = Provider.autoDispose<List<GroupInsights>>((ref) {
  final groups = (ref.watch(adminGroupsProvider).value ?? const <AcademyGroup>[]).where((g) => !g.archived);
  return [for (final group in groups) ?ref.watch(groupInsightsProvider(group.id))];
});
