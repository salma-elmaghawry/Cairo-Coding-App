import 'package:cairo_coding_app/admin/insights/group_insights.dart';
import 'package:cairo_coding_app/admin/widgets/admin_panel.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/services/attendance.dart';
import 'package:cairo_coding_app/data/services/quiz_averages.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// Each group's average quiz score as a bar.
class QuizScoresPanel extends StatelessWidget {
  const QuizScoresPanel({super.key, required this.groups});

  final List<GroupInsights> groups;

  @override
  Widget build(BuildContext context) {
    final scored = groups.where((g) => g.quizAverage != null).toList();
    final colorScheme = Theme.of(context).colorScheme;

    return AdminPanel(
      title: 'admin.overview.quiz_title'.tr(),
      subtitle: 'admin.overview.quiz_hint'.tr(),
      child: scored.isEmpty
          ? EmptyView(message: 'admin.overview.quiz_empty'.tr(), icon: Icons.quiz_outlined)
          : Column(
              children: [
                for (final group in scored) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(group.group.name, style: AppTextStyles.font14ExtraBold),
                      horizontalSpace(6),
                      Expanded(
                        child: Text(
                          '· ${'admin.overview.results'.tr(args: ['${QuizAverages.submissions(group.boards)}'])}',
                          style: AppTextStyles.font12SemiBold.secondary(context),
                        ),
                      ),
                      Text(
                        '${percent(group.quizAverage!)}%',
                        textDirection: TextDirection.ltr,
                        style: AppTextStyles.monoFont14Bold,
                      ),
                    ],
                  ),
                  verticalSpace(8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: group.quizAverage,
                      minHeight: 10,
                      backgroundColor: colorScheme.primary.withValues(alpha: .14),
                    ),
                  ),
                  verticalSpace(16),
                ],
              ],
            ),
    );
  }
}
