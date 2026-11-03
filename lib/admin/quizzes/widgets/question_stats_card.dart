import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/theme/app_colors.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/services/quiz_analytics.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_format.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

class QuestionStatsCard extends StatelessWidget {
  const QuestionStatsCard({super.key, required this.number, required this.stats});

  final int number;
  final QuestionStats stats;

  @override
  Widget build(BuildContext context) {
    final rate = (stats.correctRate * 100).round();
    final total = stats.answered + stats.skipped;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$number',
                style: AppTextStyles.monoFont16Bold.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              horizontalSpace(10),
              Expanded(child: Text(context.bidi(stats.question.text), style: AppTextStyles.font14Bold)),
              horizontalSpace(12),
              StatusChip(
                label: 'admin.quiz_analytics.correct_rate'.tr(args: ['$rate']),
                tone: rate >= 70
                    ? StatusTone.success
                    : rate >= 40
                    ? StatusTone.gold
                    : StatusTone.danger,
              ),
            ],
          ),
          verticalSpace(14),
          for (final (option, text) in stats.question.options.indexed) ...[
            _OptionBar(
              option: option,
              text: text,
              count: stats.optionCounts[option],
              total: total,
              isCorrect: option == stats.correctOption,
              isTopWrong: option == stats.topWrongOption,
            ),
            verticalSpace(8),
          ],
          if (stats.skipped > 0)
            Text(
              'admin.quiz_analytics.skipped'.tr(args: ['${stats.skipped}']),
              style: AppTextStyles.font12Normal.secondary(context),
            ),
        ],
      ),
    );
  }
}

/// How many students chose an option. The bar is one colour with its count written beside it; whether the option is
/// right or a common trap is said in words, so it isn't down to colour alone.
class _OptionBar extends StatelessWidget {
  const _OptionBar({
    required this.option,
    required this.text,
    required this.count,
    required this.total,
    required this.isCorrect,
    required this.isTopWrong,
  });

  final int option;
  final String text;
  final int count;
  final int total;
  final bool isCorrect;
  final bool isTopWrong;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final share = total == 0 ? 0.0 : count / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(optionLetter(option), style: AppTextStyles.monoFont12Bold.secondary(context)),
            horizontalSpace(8),
            Expanded(
              child: Text(context.bidi(text), overflow: TextOverflow.ellipsis, style: AppTextStyles.font14Normal),
            ),
            if (isCorrect) ...[
              horizontalSpace(8),
              const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
              horizontalSpace(4),
              Text('admin.quiz_analytics.correct_answer'.tr(), style: AppTextStyles.font12SemiBold),
            ],
            if (isTopWrong) ...[
              horizontalSpace(8),
              Icon(Icons.warning_amber_rounded, size: 16, color: colorScheme.tertiary),
              horizontalSpace(4),
              Text('admin.quiz_analytics.top_wrong'.tr(), style: AppTextStyles.font12SemiBold),
            ],
            horizontalSpace(12),
            Text(
              '$count · ${percentOf(count, total)}%',
              textDirection: TextDirection.ltr,
              style: AppTextStyles.monoFont12Medium.secondary(context),
            ),
          ],
        ),
        verticalSpace(4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: share,
            minHeight: 8,
            color: colorScheme.primary,
            backgroundColor: colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}
