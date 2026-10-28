import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
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
  return ref
      .watch(adminGroupsProvider)
      .whenData(
        (groups) => groups
            .where((g) => g.archived == view.archived)
            .where((g) => view.query.isEmpty || '${g.name} ${g.track}'.toLowerCase().contains(view.query))
            .toList(),
      );
});

final groupCountsProvider = Provider<({int active, int archived})>((ref) {
  final groups = ref.watch(adminGroupsProvider).value ?? const [];
  final archived = groups.where((g) => g.archived).length;
  return (active: groups.length - archived, archived: archived);
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
