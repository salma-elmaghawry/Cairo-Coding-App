import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/data/services/quiz_analytics.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_format.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Single numbers, so they read best as plain tiles rather than a chart.
class QuizKpis extends StatelessWidget {
  const QuizKpis({super.key, required this.analytics});

  final QuizAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    String score(num? value) =>
        value == null ? '–' : '${value is double ? value.toStringAsFixed(1) : value}/${analytics.totalPoints}';

    final tiles = [
      ('admin.quiz_analytics.assigned', '${analytics.assigned}'),
      ('admin.quiz_analytics.completed', '${analytics.completed}'),
      ('admin.quiz_analytics.completion_rate', '${percentOf(analytics.completed, analytics.assigned)}%'),
      ('admin.quiz_analytics.average', score(analytics.average)),
      ('admin.quiz_analytics.highest', score(analytics.highest)),
      ('admin.quiz_analytics.lowest', score(analytics.lowest)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final columns = constraints.maxWidth >= 900 ? 6 : (constraints.maxWidth >= 480 ? 3 : 2);
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (label, value) in tiles)
              SizedBox(
                width: width,
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  radius: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label.tr(), style: AppTextStyles.font12Normal.secondary(context)),
                      verticalSpace(6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(value, style: AppTextStyles.monoFont20Bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
