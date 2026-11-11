import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:cairo_coding_app/data/services/attendance.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How many out of how many, as in "13 of 15 sessions". A total of 0 means nothing was recorded yet.
typedef Tally = ({int done, int total});

/// Sessions the student was at, out of the held sessions that had attendance taken (see [Attendance.counted]).
final myAttendanceTallyProvider = Provider<Tally>((ref) {
  final uid = ref.watch(currentUserProvider.select((user) => user?.uid));
  final sessions = ref.watch(studentSessionsProvider).value ?? const <ClassSession>[];
  final counted = Attendance.counted(sessions, ref.watch(clockProvider)());
  return (done: counted.where((s) => s.attendees!.contains(uid)).length, total: counted.length);
});

/// Tasks the student handed in, out of the sessions the admin recorded a task for.
final myTasksTallyProvider = Provider<Tally>((ref) {
  final uid = ref.watch(currentUserProvider.select((user) => user?.uid));
  final sessions = ref.watch(studentSessionsProvider).value ?? const <ClassSession>[];
  final withTask = sessions.where((s) => !s.isCancelled && s.hasTask).toList();
  return (done: withTask.where((s) => s.taskDoneBy!.contains(uid)).length, total: withTask.length);
});

/// The groups the profile names: the current ones, or the archived ones when the student has nothing else.
final profileGroupsProvider = Provider<List<AcademyGroup>>((ref) {
  final groups = ref.watch(studentGroupsProvider).value ?? const <AcademyGroup>[];
  final current = groups.where((g) => !g.archived).toList();
  return current.isEmpty ? groups : current;
});

/// The courses of those groups, each read by id: the rules don't let students list every course.
final profileCoursesProvider = StreamProvider<List<Course>>((ref) {
  final key = ref.watch(
    profileGroupsProvider.select(
      (groups) => {
        for (final group in groups)
          if (group.courseId.isNotEmpty) group.courseId,
      }.join(','),
    ),
  );
  return ref.watch(academyRepositoryProvider).watchCourses(ids: key.isEmpty ? const [] : key.split(','));
});
