import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/app_user.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/data/models/recording.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentUserProvider = Provider<AppUser?>((ref) => ref.watch(authStateProvider).value);

final studentGroupIdsProvider = Provider<List<String>>((ref) {
  final key = ref.watch(currentUserProvider.select((user) => user?.profile.groupIds.join(',') ?? ''));
  return key.isEmpty ? const [] : key.split(',');
});

final studentGroupsProvider = StreamProvider<List<AcademyGroup>>((ref) {
  final ids = ref.watch(studentGroupIdsProvider);
  return ref.watch(academyRepositoryProvider).watchGroups(ids: ids);
});

final groupsByIdProvider = Provider<Map<String, AcademyGroup>>((ref) {
  final groups = ref.watch(studentGroupsProvider).value ?? const [];
  return {for (final group in groups) group.id: group};
});

final studentSessionsProvider = StreamProvider<List<ClassSession>>((ref) {
  final ids = ref.watch(studentGroupIdsProvider);
  return ref.watch(academyRepositoryProvider).watchSessions(ids);
});

final studentRecordingsProvider = StreamProvider<List<Recording>>((ref) {
  final ids = ref.watch(studentGroupIdsProvider);
  return ref.watch(academyRepositoryProvider).watchRecordings(ids);
});

final upcomingSessionsProvider = Provider<AsyncValue<List<ClassSession>>>((ref) {
  final now = ref.watch(clockProvider)();
  return ref.watch(studentSessionsProvider).whenData((sessions) => sessions.where((s) => !s.isPast(now)).toList());
});

final pastSessionsProvider = Provider<AsyncValue<List<ClassSession>>>((ref) {
  final now = ref.watch(clockProvider)();
  return ref
      .watch(studentSessionsProvider)
      .whenData((sessions) => sessions.where((s) => s.isPast(now)).toList().reversed.toList());
});

final nextSessionProvider = Provider<AsyncValue<ClassSession?>>((ref) {
  return ref.watch(upcomingSessionsProvider).whenData((sessions) {
    for (final session in sessions) {
      if (!session.isCancelled) return session;
    }
    return null;
  });
});

final recordingsFilterProvider = NotifierProvider<RecordingsFilter, String?>(RecordingsFilter.new);

class RecordingsFilter extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? groupId) => state = groupId;
}

final filteredRecordingsProvider = Provider<AsyncValue<List<Recording>>>((ref) {
  final groupId = ref.watch(recordingsFilterProvider);
  return ref
      .watch(studentRecordingsProvider)
      .whenData((recordings) => groupId == null ? recordings : recordings.where((r) => r.groupId == groupId).toList());
});
