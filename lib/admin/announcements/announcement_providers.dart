import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/announcement.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Announcements sent to any group, archived ones included, newest first.
final adminAnnouncementsProvider = StreamProvider.autoDispose<List<Announcement>>((ref) async* {
  final groups = await ref.watch(adminGroupsProvider.future);
  yield* ref.watch(academyRepositoryProvider).watchAnnouncements([for (final AcademyGroup g in groups) g.id]);
});
