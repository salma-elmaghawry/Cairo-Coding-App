import 'package:cairo_coding_app/admin/insights/group_insights.dart';
import 'package:cairo_coding_app/admin/widgets/admin_panel.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/shared/session_labels.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Every session as a square: done, still to come, or cancelled.
class CourseTimeline extends StatelessWidget {
  const CourseTimeline({super.key, required this.insights});

  final GroupInsights insights;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = insights.now;
    final sessions = insights.sessions;
    final cancelled = sessions.where((s) => s.isCancelled).length;
    final upcoming = insights.total - insights.done;

    Widget legend(Color color, String label, {Color? border}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: border == null ? null : Border.all(color: border),
          ),
        ),
        horizontalSpace(6),
        Text(label, style: AppTextStyles.font12Normal.secondary(context)),
      ],
    );

    return AdminPanel(
      title: 'admin.schedule.timeline'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 4.0;
              final size = (constraints.maxWidth - gap * 11) / 12;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final session in sessions)
                    Tooltip(
                      message: '${session.title} · ${context.shortDay(session.startsAt)}',
                      child: Container(
                        width: size,
                        height: 22,
                        decoration: BoxDecoration(
                          color: session.isCancelled
                              ? colorScheme.error
                              : session.isPast(now)
                              ? colorScheme.primary
                              : colorScheme.primary.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(5),
                          border: !session.isCancelled && !session.isPast(now)
                              ? Border.all(color: colorScheme.primary.withValues(alpha: .5))
                              : null,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          verticalSpace(14),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              legend(colorScheme.primary, 'admin.schedule.legend_done'.tr(args: ['${insights.done}'])),
              legend(
                colorScheme.primary.withValues(alpha: .2),
                'admin.schedule.legend_upcoming'.tr(args: ['$upcoming']),
                border: colorScheme.primary.withValues(alpha: .5),
              ),
              legend(colorScheme.error, 'admin.schedule.legend_cancelled'.tr(args: ['$cancelled'])),
            ],
          ),
        ],
      ),
    );
  }
}
