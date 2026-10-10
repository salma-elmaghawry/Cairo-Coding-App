import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:cairo_coding_app/student/widgets/session_tile.dart';
import 'package:cairo_coding_app/student/widgets/tab_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _ScheduleView { upcoming, past }

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  _ScheduleView _view = _ScheduleView.upcoming;

  @override
  Widget build(BuildContext context) {
    final isUpcoming = _view == _ScheduleView.upcoming;
    final sessions = ref.watch(isUpcoming ? upcomingSessionsProvider : pastSessionsProvider);
    final nextId = ref.watch(nextSessionProvider.select((value) => value.value?.id));
    final groups = ref.watch(groupsByIdProvider);
    final showGroup = groups.length > 1;

    return TabPage(
      eyebrow: 'schedule.eyebrow'.tr(),
      title: 'schedule.title'.tr(),
      onRefresh: () async {
        ref.invalidate(studentSessionsProvider);
        await ref.read(studentSessionsProvider.future);
      },
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SegmentedButton<_ScheduleView>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: _ScheduleView.upcoming, label: Text('schedule.upcoming'.tr())),
                ButtonSegment(value: _ScheduleView.past, label: Text('schedule.past'.tr())),
              ],
              selected: {_view},
              onSelectionChanged: (selection) => setState(() => _view = selection.first),
            ),
          ),
        ),
        switch (sessions) {
          AsyncError(:final error) => SliverToBoxAdapter(child: ErrorView(message: error.toString())),
          AsyncData(:final value) when value.isEmpty => SliverToBoxAdapter(
            child: EmptyView(
              message: (isUpcoming ? 'schedule.empty_upcoming' : 'schedule.empty_past').tr(),
              icon: Icons.event_busy_outlined,
            ),
          ),
          AsyncData(:final value) => SliverList.separated(
            key: ValueKey(_view),
            itemCount: value.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final session = value[index];
              return AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                radius: 16,
                child: SessionTile(
                  session: session,
                  groupName: showGroup ? groups[session.groupId]?.name : null,
                  badge: _badgeFor(session, nextId),
                ),
              ).fadeInSlideUp(delay: AppAnimations.staggerDelay * (index.clamp(0, 8)));
            },
          ),
          _ => const SliverToBoxAdapter(child: SkeletonList(count: 6)),
        },
      ],
    );
  }

  (String, StatusTone)? _badgeFor(ClassSession session, String? nextId) {
    if (session.id == nextId) return ('schedule.next'.tr(), StatusTone.accent);
    return null;
  }
}
