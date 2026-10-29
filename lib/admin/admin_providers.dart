import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:cairo_coding_app/data/models/instructor.dart';
import 'package:cairo_coding_app/data/models/recording.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminGroupsProvider = StreamProvider<List<AcademyGroup>>(
  (ref) => ref.watch(academyRepositoryProvider).watchGroups(),
);

class GroupsView {
  const GroupsView({this.archived = false, this.query = ''});

  final bool archived;
  final String query;
}

final groupsViewProvider = NotifierProvider<GroupsViewNotifier, GroupsView>(GroupsViewNotifier.new);

class GroupsViewNotifier extends Notifier<GroupsView> {
  @override
  GroupsView build() => const GroupsView();

  void showArchived(bool archived) => state = GroupsView(archived: archived, query: state.query);

  void search(String query) => state = GroupsView(archived: state.archived, query: query.trim().toLowerCase());
}

final visibleGroupsProvider = Provider<AsyncValue<List<AcademyGroup>>>((ref) {
  final view = ref.watch(groupsViewProvider);
  final courseNames = {
    for (final course in ref.watch(coursesProvider).value ?? const <Course>[]) course.id: course.name,
  };
  return ref
      .watch(adminGroupsProvider)
      .whenData(
        (groups) => groups
            .where((g) => g.archived == view.archived)
            .where(
              (g) =>
                  view.query.isEmpty || '${g.name} ${courseNames[g.courseId] ?? ''}'.toLowerCase().contains(view.query),
            )
            .toList(),
      );
});

final groupCountsProvider = Provider<({int active, int archived})>((ref) {
  final groups = ref.watch(adminGroupsProvider).value ?? const [];
  final archived = groups.where((g) => g.archived).length;
  return (active: groups.length - archived, archived: archived);
});

final allStudentsProvider = StreamProvider.autoDispose<List<Student>>(
  (ref) => ref.watch(academyRepositoryProvider).watchAllStudents(),
);

class StudentsView {
  const StudentsView({this.query = '', this.courseId});

  final String query;

  /// Only students in this course's groups; null shows everyone.
  final String? courseId;
}

final studentsViewProvider = NotifierProvider<StudentsViewNotifier, StudentsView>(StudentsViewNotifier.new);

class StudentsViewNotifier extends Notifier<StudentsView> {
  @override
  StudentsView build() => const StudentsView();

  void search(String query) => state = StudentsView(query: query.trim().toLowerCase(), courseId: state.courseId);

  void filterCourse(String? courseId) => state = StudentsView(query: state.query, courseId: courseId);
}

final visibleStudentsProvider = Provider.autoDispose<AsyncValue<List<Student>>>((ref) {
  final view = ref.watch(studentsViewProvider);
  final courseGroupIds = {
    for (final group in ref.watch(adminGroupsProvider).value ?? const <AcademyGroup>[])
      if (group.courseId == view.courseId) group.id,
  };
  // Phones are typed with spaces, so "0101234" should still find "010 1234 4821".
  bool matches(Student s) =>
      '${s.name} ${s.email} ${s.phone} ${s.phone.replaceAll(' ', '')}'.toLowerCase().contains(view.query);
  return ref
      .watch(allStudentsProvider)
      .whenData(
        (students) => students
            .where((s) => view.courseId == null || s.groupIds.any(courseGroupIds.contains))
            .where((s) => view.query.isEmpty || matches(s))
            .toList(),
      );
});

final groupProvider = Provider.family<AsyncValue<AcademyGroup?>, String>(
  (ref, groupId) =>
      ref.watch(adminGroupsProvider).whenData((groups) => groups.where((g) => g.id == groupId).firstOrNull),
);

final groupStudentsProvider = StreamProvider.autoDispose.family<List<Student>, String>(
  (ref, groupId) => ref.watch(academyRepositoryProvider).watchStudents(groupId),
);

final groupSessionsProvider = StreamProvider.autoDispose.family<List<ClassSession>, String>(
  (ref, groupId) => ref.watch(academyRepositoryProvider).watchSessions([groupId]),
);

final groupRecordingsProvider = StreamProvider.autoDispose.family<List<Recording>, String>(
  (ref, groupId) => ref.watch(academyRepositoryProvider).watchRecordings([groupId]),
);

final groupNextSessionProvider = Provider.autoDispose.family<ClassSession?, String>((ref, groupId) {
  final now = ref.watch(clockProvider)();
  final sessions = ref.watch(groupSessionsProvider(groupId)).value ?? const [];
  return sessions.where((s) => !s.isCancelled && !s.isPast(now)).firstOrNull;
});

final instructorsProvider = StreamProvider<List<Instructor>>(
  (ref) => ref.watch(academyRepositoryProvider).watchInstructors(),
);

final coursesProvider = StreamProvider<List<Course>>((ref) => ref.watch(academyRepositoryProvider).watchCourses());

final courseProvider = Provider.family<AsyncValue<Course?>, String>(
  (ref, courseId) =>
      ref.watch(coursesProvider).whenData((courses) => courses.where((c) => c.id == courseId).firstOrNull),
);

/// The course's groups that aren't archived.
final courseGroupsProvider = Provider.family<AsyncValue<List<AcademyGroup>>, String>(
  (ref, courseId) => ref
      .watch(adminGroupsProvider)
      .whenData((groups) => groups.where((g) => g.courseId == courseId && !g.archived).toList()),
);

final courseStudentsProvider = StreamProvider.autoDispose.family<List<Student>, String>((ref, courseId) async* {
  final repository = ref.watch(academyRepositoryProvider);
  final groups = await ref.watch(adminGroupsProvider.future);
  yield* repository.watchStudentsOf([
    for (final group in groups)
      if (group.courseId == courseId && !group.archived) group.id,
  ]);
});

final courseInstructorsProvider = Provider.family<List<Instructor>, String>((ref, courseId) {
  final ids = ref.watch(courseProvider(courseId)).value?.instructorIds ?? const [];
  return (ref.watch(instructorsProvider).value ?? const []).where((i) => ids.contains(i.id)).toList();
});

/// Who a session of this group can be given to: its course's instructors, or everyone while the course has none.
final sessionInstructorsProvider = Provider.family<List<Instructor>, String>((ref, groupId) {
  final courseId = ref.watch(groupProvider(groupId)).value?.courseId ?? '';
  final assigned = ref.watch(courseInstructorsProvider(courseId));
  return assigned.isEmpty ? ref.watch(instructorsProvider).value ?? const [] : assigned;
});
