import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/hero_card.dart';
import 'package:cairo_coding_app/core/widgets/progress_ring.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_summary.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The average score as a ring, with open, done and points beside it.
class QuizPerformanceCard extends StatelessWidget {
  const QuizPerformanceCard({super.key, required this.summary});

  final QuizSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final average = summary.average;

    return HeroCard(
      padding: const EdgeInsets.all(18),
      glow: AlignmentDirectional.topStart,
      child: Row(
        children: [
          ProgressRing(
            value: (average ?? 0) / 100,
            size: 84,
            strokeWidth: 9,
            semanticsLabel: '${'quizzes.stat_average'.tr()} ${average == null ? '–' : '$average%'}',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  average == null ? '–' : '$average%',
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.monoFont20Bold.copyWith(height: 1),
                ),
                verticalSpace(3),
                Text('quizzes.avg'.tr().toUpperCase(), style: AppTextStyles.font11ExtraBold.muted(context)),
              ],
            ),
          ),
          horizontalSpace(18),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _Stat(label: 'quizzes.stat_open'.tr(), value: summary.open),
                ),
                _divider(colorScheme),
                Expanded(
                  child: _Stat(label: 'quizzes.stat_done'.tr(), value: summary.done),
                ),
                _divider(colorScheme),
                Expanded(
                  child: _Stat(label: 'quizzes.stat_total_points'.tr(), value: summary.points),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme colorScheme) =>
      Container(width: 1, height: 44, margin: const EdgeInsetsDirectional.only(end: 10), color: colorScheme.outline);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.font12Normal.secondary(context)),
        verticalSpace(4),
        Text('$value', style: AppTextStyles.monoFont20Bold),
      ],
    );
  }
}
