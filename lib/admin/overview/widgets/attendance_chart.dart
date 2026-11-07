import 'package:cairo_coding_app/admin/insights/group_insights.dart';
import 'package:cairo_coding_app/admin/widgets/admin_panel.dart';
import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/filter_pill.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/services/attendance.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The share of a group at each of its last eight sessions, one group at a time.
class AttendanceChart extends StatefulWidget {
  const AttendanceChart({super.key, required this.groups});

  final List<GroupInsights> groups;

  @override
  State<AttendanceChart> createState() => _AttendanceChartState();
}

class _AttendanceChartState extends State<AttendanceChart> {
  String? _groupId;

  @override
  Widget build(BuildContext context) {
    final groups = widget.groups;
    final selected = groups.where((g) => g.group.id == _groupId).firstOrNull ?? groups.firstOrNull;
    final bars = selected == null
        ? const <(String, double)>[]
        : [
            for (final session in selected.counted.reversed.take(8).toList().reversed)
              if (Attendance.sessionRate(session, selected.memberIds) case final rate?)
                (session.number == null ? 'X' : 'S${session.number}', rate),
          ];

    return AdminPanel(
      title: 'admin.overview.attendance_title'.tr(),
      subtitle: 'admin.overview.attendance_hint'.tr(),
      trailing: groups.length < 2
          ? null
          : FilterPillBar(
              children: [
                for (final group in groups)
                  FilterPill(
                    label: group.group.name,
                    selected: group == selected,
                    onSelected: () => setState(() => _groupId = group.group.id),
                  ),
              ],
            ),
      child: bars.isEmpty
          ? EmptyView(message: 'admin.overview.attendance_empty'.tr(), icon: Icons.bar_chart_rounded)
          : Semantics(
              label: 'admin.overview.attendance_label'.tr(
                args: [selected!.group.name, bars.map((b) => '${percent(b.$2)}%').join(', ')],
              ),
              excludeSemantics: true,
              child: SizedBox(height: 220, child: _Bars(bars: bars)),
            ),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars({required this.bars});

  final List<(String, double)> bars;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final axis = AppTextStyles.monoFont10Medium.muted(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 22, top: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final tick in ['100', '75', '50', '25', '0']) Text(tick, style: axis),
            ],
          ),
        ),
        horizontalSpace(12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final plot = constraints.maxHeight - 40;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (index, (label, rate)) in bars.indexed) ...[
                    if (index > 0) horizontalSpace(12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${percent(rate)}%',
                            style: AppTextStyles.monoFont10Medium.copyWith(fontWeight: FontWeight.w700),
                          ),
                          verticalSpace(4),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: rate),
                            duration: AppAnimations.slow,
                            curve: AppAnimations.defaultCurve,
                            builder: (context, value, _) => Container(
                              height: plot * value,
                              constraints: const BoxConstraints(maxWidth: 44),
                              decoration: BoxDecoration(
                                color: index == bars.length - 1
                                    ? colorScheme.primary
                                    : colorScheme.primary.withValues(alpha: .42),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                  bottom: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          verticalSpace(6),
                          Text(label, style: AppTextStyles.monoFont10Medium.secondary(context)),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
