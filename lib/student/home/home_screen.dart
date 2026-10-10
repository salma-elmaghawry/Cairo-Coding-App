import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/section_header.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/student/home/widgets/home_header.dart';
import 'package:cairo_coding_app/student/home/widgets/next_session_card.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:cairo_coding_app/student/student_routes.dart';
import 'package:cairo_coding_app/student/widgets/recording_tile.dart';
import 'package:cairo_coding_app/student/widgets/session_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingSessionsProvider);
    final next = ref.watch(nextSessionProvider);
    final groups = ref.watch(groupsByIdProvider);
    final latestRecording = ref.watch(studentRecordingsProvider.select((value) => value.value?.firstOrNull));

    Future<void> refresh() async {
      ref.invalidate(studentSessionsProvider);
      ref.invalidate(studentRecordingsProvider);
      await ref.read(studentSessionsProvider.future);
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: refresh,
        child: switch (upcoming) {
          AsyncError(:final error) => ErrorView(message: error.toString(), onRetry: refresh),
          AsyncData(:final value) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              const HomeHeader(),
              verticalSpace(20),
              if (next.value case final ClassSession session)
                NextSessionCard(session: session, group: groups[session.groupId])
              else
                AppCard(
                  child: EmptyView(message: 'home.no_upcoming'.tr(), icon: Icons.event_available_outlined),
                ),
              verticalSpace(24),
              SectionHeader(
                title: 'home.this_week'.tr(),
                actionLabel: 'home.full_schedule'.tr(),
                onAction: () => context.go(StudentRoutes.schedule),
              ),
              verticalSpace(8),
              _WeekList(sessions: _thisWeek(value, next.value)),
              if (latestRecording != null) ...[
                verticalSpace(24),
                SectionHeader(
                  title: 'home.latest_recording'.tr(),
                  actionLabel: 'home.all_recordings'.tr(),
                  onAction: () => context.go(StudentRoutes.recordings),
                ),
                verticalSpace(8),
                RecordingTile(recording: latestRecording, groupName: groups[latestRecording.groupId]?.name),
              ],
            ].animateList(),
          ),
          _ => ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: const [SkeletonList(count: 1, itemHeight: 320), SkeletonList(count: 3)],
          ),
        },
      ),
    );
  }

  List<ClassSession> _thisWeek(List<ClassSession> upcoming, ClassSession? next) {
    if (upcoming.isEmpty) return const [];
    final limit = upcoming.first.startsAt.add(const Duration(days: 7));
    return upcoming.where((s) => s != next && s.startsAt.isBefore(limit)).take(3).toList();
  }
}

class _WeekList extends StatelessWidget {
  const _WeekList({required this.sessions});

  final List<ClassSession> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return AppCard(
        child: EmptyView(message: 'home.week_empty'.tr(), icon: Icons.weekend_outlined),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      radius: 16,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          for (final (index, session) in sessions.indexed) ...[
            if (index > 0) const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SessionTile(session: session),
            ),
          ],
        ],
      ),
    );
  }
}
