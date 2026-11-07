import 'package:cairo_coding_app/admin/insights/group_insights.dart';
import 'package:cairo_coding_app/admin/overview/overview_numbers.dart';
import 'package:cairo_coding_app/admin/overview/widgets/activity_panel.dart';
import 'package:cairo_coding_app/admin/overview/widgets/attendance_chart.dart';
import 'package:cairo_coding_app/admin/overview/widgets/coming_up_panel.dart';
import 'package:cairo_coding_app/admin/overview/widgets/kpi_card.dart';
import 'package:cairo_coding_app/admin/overview/widgets/needs_attention_panel.dart';
import 'package:cairo_coding_app/admin/overview/widgets/quiz_scores_panel.dart';
import 'package:cairo_coding_app/admin/widgets/admin_page.dart';
import 'package:cairo_coding_app/admin/widgets/card_grid.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/widgets/segmented_control.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/services/attendance.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  OverviewPeriod _period = OverviewPeriod.month;

  String _greetingKey(int hour) => switch (hour) {
    < 12 => 'admin.overview.greeting_morning',
    < 17 => 'admin.overview.greeting_afternoon',
    _ => 'admin.overview.greeting_evening',
  };

  String _count(double value, {bool signed = false}) => '${signed && value > 0 ? '+' : ''}${value.round()}';

  String _percent(double value, {bool signed = false}) => '${signed && value > 0 ? '+' : ''}${percent(value)}%';

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(activeInsightsProvider);
    final now = ref.watch(minuteTickerProvider).value ?? ref.watch(clockProvider)();
    final name = ref.watch(authStateProvider.select((auth) => auth.value?.profile.name ?? ''));
    final numbers = OverviewNumbers(groups: groups, now: now, period: _period);
    final left = numbers.thisWeek.length - numbers.doneThisWeek;
    final vs = _period == OverviewPeriod.all ? null : 'admin.overview.vs_${_period.name}'.tr();

    return AdminPage(
      eyebrow: 'admin.overview.eyebrow'.tr(),
      title: _greetingKey(now.hour).tr(args: [name.split(' ').first]),
      subtitle: 'admin.overview.summary'.tr(args: ['${groups.length}', '$left', '${numbers.quizzesClosingSoon}']),
      actions: [
        SizedBox(
          width: 300,
          child: AppSegmentedControl<OverviewPeriod>(
            height: 34,
            segments: [
              for (final period in OverviewPeriod.values)
                AppSegment(period, 'admin.overview.period_${period.name}'.tr()),
            ],
            selected: _period,
            onChanged: (period) => setState(() => _period = period),
          ),
        ),
      ],
      children: [
        CardGrid(
          minItemWidth: 230,
          children: [
            KpiCard(
              label: 'admin.overview.kpi_students'.tr(),
              icon: Icons.school_outlined,
              kpi: numbers.activeStudents,
              format: _count,
              vs: vs,
            ),
            KpiCard(
              label: 'admin.overview.kpi_attendance'.tr(),
              icon: Icons.task_alt_rounded,
              kpi: numbers.attendance,
              format: _percent,
              vs: vs,
            ),
            KpiCard(
              label: 'admin.overview.kpi_quiz'.tr(),
              icon: Icons.fact_check_outlined,
              kpi: numbers.quizScore,
              format: _percent,
              vs: vs,
            ),
            KpiCard(
              label: 'admin.overview.kpi_sessions'.tr(),
              icon: Icons.calendar_month_outlined,
              kpi: numbers.sessionsThisWeek,
              format: _count,
              note: 'admin.overview.done_left'.tr(args: ['${numbers.doneThisWeek}', '$left']),
            ),
          ],
        ),
        verticalSpace(16),
        LayoutBuilder(
          builder: (context, constraints) {
            final chart = AttendanceChart(groups: groups);
            final comingUp = ComingUpPanel(upcoming: numbers.upcoming, now: now);
            if (constraints.maxWidth < 900) {
              return Column(children: [chart, verticalSpace(16), comingUp]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: chart),
                horizontalSpace(16),
                Expanded(flex: 2, child: comingUp),
              ],
            );
          },
        ),
        verticalSpace(16),
        CardGrid(
          minItemWidth: 300,
          animate: false,
          children: [
            QuizScoresPanel(groups: groups),
            NeedsAttentionPanel(groups: groups),
            ActivityPanel(groups: groups, now: now),
          ],
        ),
      ],
    );
  }
}
