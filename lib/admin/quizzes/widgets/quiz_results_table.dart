import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_data_table.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/data/services/quiz_analytics.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_format.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

class QuizResultsTable extends StatelessWidget {
  const QuizResultsTable({super.key, required this.quiz, required this.analytics, required this.groups});

  final Quiz quiz;
  final QuizAnalytics analytics;
  final Map<String, AcademyGroup> groups;

  @override
  Widget build(BuildContext context) {
    return AppDataTable(
      minWidth: 900,
      columns: [
        AppTableColumn('admin.students.name'.tr(), flex: 4),
        AppTableColumn('admin.courses.groups'.tr(), flex: 2),
        AppTableColumn('admin.quiz_analytics.score'.tr(), flex: 2),
        AppTableColumn('admin.quiz_analytics.correct'.tr(), flex: 2),
        AppTableColumn('admin.quiz_analytics.time_taken'.tr(), flex: 2),
        AppTableColumn('admin.quiz_analytics.attempts'.tr(), flex: 2),
        AppTableColumn('admin.students.status'.tr(), flex: 2, alignEnd: true),
      ],
      rows: [
        for (final result in analytics.results)
          [
            Text(context.bidi(result.name), style: AppTextStyles.font14Bold, overflow: TextOverflow.ellipsis),
            Text(
              [
                for (final id in result.groupIds)
                  if (quiz.groupIds.contains(id)) ?groups[id]?.name,
              ].map(context.bidi).join(' · '),
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.font12Normal.secondary(context),
            ),
            Text(
              result.score == null
                  ? '–'
                  : '${result.score}/${analytics.totalPoints} · ${percentOf(result.score!, analytics.totalPoints)}%',
              textDirection: TextDirection.ltr,
              style: AppTextStyles.monoFont12Bold,
            ),
            Text(
              result.correctCount == null ? '–' : '${result.correctCount}/${analytics.questions.length}',
              textDirection: TextDirection.ltr,
              style: AppTextStyles.monoFont12Medium,
            ),
            Text(
              result.timeTaken == null ? '–' : formatClock(result.timeTaken!),
              textDirection: TextDirection.ltr,
              style: AppTextStyles.monoFont12Medium,
            ),
            Text(
              result.attemptCount == 0
                  ? '–'
                  : result.attemptCount > 1 && result.bestScore != null
                  ? 'admin.quiz_analytics.attempts_best'.tr(args: ['${result.attemptCount}', '${result.bestScore}'])
                  : '${result.attemptCount}',
              style: AppTextStyles.font12Medium,
            ),
            StatusChip(
              label: switch (result.status) {
                StudentQuizStatus.completed => 'admin.quiz_analytics.status_completed'.tr(),
                StudentQuizStatus.inProgress => 'admin.quiz_analytics.status_in_progress'.tr(),
                StudentQuizStatus.notStarted => 'admin.quiz_analytics.status_not_started'.tr(),
              },
              tone: switch (result.status) {
                StudentQuizStatus.completed => StatusTone.success,
                StudentQuizStatus.inProgress => StatusTone.gold,
                StudentQuizStatus.notStarted => StatusTone.neutral,
              },
            ),
          ],
      ],
    );
  }
}
