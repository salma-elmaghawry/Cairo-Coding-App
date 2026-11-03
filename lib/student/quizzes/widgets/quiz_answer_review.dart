import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/section_header.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/models/quiz_attempt.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_option_tile.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Correct answers only appear once the quiz has closed, so they can't reach anyone still to take it.
class QuizAnswerReview extends ConsumerWidget {
  const QuizAnswerReview({super.key, required this.attempt});

  final QuizAttempt attempt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(quizReviewProvider(attempt.quizId));

    return switch (review) {
      AsyncError(:final error) => ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(quizReviewProvider(attempt.quizId)),
      ),
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: 'quizzes.review_answers'.tr()),
          verticalSpace(8),
          for (final (index, question) in value.questions.indexed) ...[
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'quizzes.question_of'.tr(args: ['${index + 1}', '${value.questions.length}']),
                    style: AppTextStyles.font12SemiBold.secondary(context),
                  ),
                  verticalSpace(4),
                  Text(context.bidi(question.text), style: AppTextStyles.font14Bold),
                  verticalSpace(10),
                  for (final (option, text) in question.options.indexed) ...[
                    QuizOptionTile(
                      index: option,
                      text: text,
                      state: switch (option) {
                        _ when option == value.key.correct[question.id] => QuizOptionState.correct,
                        _ when option == attempt.answers[question.id] => QuizOptionState.wrong,
                        _ => QuizOptionState.idle,
                      },
                    ),
                    verticalSpace(6),
                  ],
                  if ((attempt.answers[question.id] ?? QuizAttempt.noAnswer) == QuizAttempt.noAnswer)
                    Text('quizzes.not_answered'.tr(), style: AppTextStyles.font12Medium.secondary(context)),
                ],
              ),
            ),
            verticalSpace(10),
          ],
        ],
      ),
      _ => const SkeletonList(count: 2, itemHeight: 160),
    };
  }
}
