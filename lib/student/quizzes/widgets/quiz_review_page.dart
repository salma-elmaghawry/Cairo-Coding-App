import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/data/models/quiz_attempt.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_session_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class QuizReviewPage extends StatelessWidget {
  const QuizReviewPage({super.key, required this.session, required this.controller});

  final QuizSession session;
  final QuizSessionController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final unanswered = session.unansweredCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  unanswered == 0 ? Icons.task_alt_rounded : Icons.error_outline_rounded,
                  size: 56,
                  color: unanswered == 0 ? colorScheme.primary : colorScheme.tertiary,
                ).popIn(),
                verticalSpace(14),
                Text(
                  'quizzes.answered_of'.tr(args: ['${session.attempt.answeredCount}', '${session.questions.length}']),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font22ExtraBold,
                ),
                verticalSpace(6),
                Text(
                  unanswered == 0 ? 'quizzes.review_ready'.tr() : 'quizzes.review_skipped'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font14Normal.secondary(context),
                ),
                verticalSpace(20),
                AppCard(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final (index, question) in session.questions.indexed)
                        _QuestionDot(
                          number: index + 1,
                          answer: session.attempt.answers[question.id],
                          onTap: session.isLocked(question) ? null : () => controller.openQuestion(index),
                        ),
                    ],
                  ),
                ),
                if (session.failure != null) ...[
                  verticalSpace(16),
                  Text(
                    session.failure!.message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font14SemiBold.copyWith(color: colorScheme.error),
                  ).shake(),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: PrimaryButton(
            label: session.failure == null ? 'quizzes.submit'.tr() : 'common.retry'.tr(),
            icon: Icons.send_rounded,
            onPressed: controller.submit,
          ),
        ),
      ],
    );
  }
}

class _QuestionDot extends StatelessWidget {
  const _QuestionDot({required this.number, required this.answer, this.onTap});

  final int number;
  final int? answer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final answered = answer != null && answer != QuizAttempt.noAnswer;
    final timedOut = answer == QuizAttempt.noAnswer;

    return AnimatedTap(
      onTap: onTap,
      enabled: onTap != null,
      child: Semantics(
        button: onTap != null,
        label: '$number',
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: answered ? colorScheme.primary : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: answered ? colorScheme.primary : colorScheme.outline),
          ),
          child: timedOut
              ? Icon(Icons.timer_off_outlined, size: 18, color: colorScheme.onSurfaceVariant)
              : Text(
                  '$number',
                  style: AppTextStyles.monoFont14Bold.copyWith(
                    color: answered ? colorScheme.onPrimary : colorScheme.onSurface,
                  ),
                ),
        ),
      ),
    );
  }
}
