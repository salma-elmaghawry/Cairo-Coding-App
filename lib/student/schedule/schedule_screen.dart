import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/widgets/segmented_control.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/data/models/recording.dart';
import 'package:cairo_coding_app/shared/session_labels.dart';
import 'package:cairo_coding_app/student/schedule/widgets/timeline_session.dart';
import 'package:cairo_coding_app/student/schedule/widgets/week_strip.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:cairo_coding_app/student/widgets/recording_tile.dart';
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
  DateTime? _day;

  @override
  Widget build(BuildContext context) {
    final isUpcoming = _view == _ScheduleView.upcoming;
    final sessions = ref.watch(isUpcoming ? upcomingSessionsProvider : pastSessionsProvider);
    final allSessions = ref.watch(studentSessionsProvider).value ?? const <ClassSession>[];
    final next = ref.watch(nextSessionProvider).value;
    final groups = ref.watch(groupsByIdProvider);
    final recordings = {
      for (final recording in ref.watch(studentRecordingsProvider).value ?? const <Recording>[])
        '${recording.groupId}#${recording.sessionNumber}': recording,
    };
    final today = DateUtils.dateOnly(ref.watch(clockProvider)());
    final weekEnd = DateUtils.addDaysToDate(today, 7);
    final nextDay = next == null ? null : DateUtils.dateOnly(next.startsAt);
    final selectedDay = _day ?? (nextDay != null && nextDay.isBefore(weekEnd) ? nextDay : today);
    final busyDays = {
      for (final session in allSessions)
        if (!session.isCancelled) DateUtils.dateOnly(session.startsAt),
    };
    final showGroup = groups.length > 1;

    return TabPage(
      eyebrow: groups.isEmpty
          ? 'schedule.eyebrow'.tr()
          : groups.values.map((group) => context.bidi(group.name)).join(' · '),
      title: 'schedule.title'.tr(),
      onRefresh: () async {
        ref.invalidate(studentSessionsProvider);
        await ref.read(studentSessionsProvider.future);
      },
      slivers: [
        SliverToBoxAdapter(
          child: WeekStrip(
            start: today,
            selected: selectedDay,
            busyDays: busyDays,
            onSelect: (day) => setState(() {
              _day = day;
              _view = _ScheduleView.upcoming;
            }),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 18)),
        SliverToBoxAdapter(
          child: AppSegmentedControl<_ScheduleView>(
            segments: [
              AppSegment(_ScheduleView.upcoming, 'schedule.upcoming'.tr()),
              AppSegment(_ScheduleView.past, 'schedule.past'.tr()),
            ],
            selected: _view,
            onChanged: (view) => setState(() => _view = view),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 18)),
        switch (sessions) {
          AsyncError(:final error) => SliverToBoxAdapter(child: ErrorView(message: error.toString())),
          AsyncData(:final value) when value.isEmpty => SliverToBoxAdapter(
            child: EmptyView(
              message: (isUpcoming ? 'schedule.empty_upcoming' : 'schedule.empty_past').tr(),
              icon: Icons.event_busy_outlined,
            ),
          ),
          AsyncData(:final value) => SliverList.builder(
            key: ValueKey(_view),
            itemCount: value.length,
            itemBuilder: (context, index) {
              final session = value[index];
              final recording = recordings['${session.groupId}#${session.number}'];
              return TimelineSession(
                session: session,
                focused: DateUtils.isSameDay(session.startsAt, selectedDay),
                isLast: index == value.length - 1,
                groupName: showGroup ? groups[session.groupId]?.name : null,
                badge: isUpcoming ? _upcomingBadge(session, next) : _pastBadge(session, recording),
                onTap: !isUpcoming && recording != null ? () => openRecording(context, ref, recording) : null,
              ).fadeInSlideUp(delay: AppAnimations.staggerDelay * (index.clamp(0, 8)));
            },
          ),
          _ => const SliverToBoxAdapter(child: SkeletonList(count: 6, itemHeight: 96)),
        },
      ],
    );
  }

  (String, StatusTone)? _upcomingBadge(ClassSession session, ClassSession? next) {
    if (session.id == next?.id) return ('schedule.next'.tr(), StatusTone.accent);
    return session.statusBadge;
  }

  (String, StatusTone)? _pastBadge(ClassSession session, Recording? recording) {
    if (recording != null && !session.isCancelled) return ('schedule.recorded'.tr(), StatusTone.success);
    return session.statusBadge;
  }
}
