import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/data/services/quiz_progress.dart';
import 'package:cairo_coding_app/student/student_routes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A quiz the student started and hasn't submitted yet.
class ContinueQuizCard extends StatelessWidget {
  const ContinueQuizCard({super.key, required this.progress});

  final QuizProgress progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final attempt = progress.inProgress!;
    final total = progress.quiz.questionCount;
    final answered = attempt.answers.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.primary.withValues(alpha: .4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('quizzes.continue'.tr(), style: AppTextStyles.font12Bold.copyWith(color: colorScheme.primary)),
          verticalSpace(4),
          Text(context.bidi(progress.quiz.title), style: AppTextStyles.font18ExtraBold),
          verticalSpace(12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : answered / total,
              minHeight: 8,
              backgroundColor: colorScheme.primary.withValues(alpha: .16),
            ),
          ),
          verticalSpace(6),
          Text(
            'quizzes.answered_of'.tr(args: ['$answered', '$total']),
            style: AppTextStyles.font12Normal.secondary(context),
          ),
          verticalSpace(12),
          PrimaryButton(
            label: 'quizzes.resume'.tr(),
            icon: Icons.play_arrow_rounded,
            height: 46,
            onPressed: () => context.push(StudentRoutes.takeQuiz(progress.quiz.id)),
          ),
        ],
      ),
    );
  }
}
