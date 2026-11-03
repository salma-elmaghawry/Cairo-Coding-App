import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/data/models/quiz_question.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_question_view.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_providers.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_session_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuizQuestionPage extends StatelessWidget {
  const QuizQuestionPage({super.key, required this.session, required this.controller});

  final QuizSession session;
  final QuizSessionController controller;

  @override
  Widget build(BuildContext context) {
    final question = session.current;
    final isLast = session.nextOpen(session.index) == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: QuizQuestionView(
              question: question,
              selected: session.selected,
              trailing: question.hasTimeLimit
                  ? _QuestionTimer(question: question, startedAt: session.questionStartedAt)
                  : null,
              onSelect: (option) {
                HapticFeedback.selectionClick();
                controller.select(option);
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Row(
            children: [
              // A question with its own timer can't be left for later, or skipping would stop its clock.
              if (!question.hasTimeLimit) ...[
                TextButton(onPressed: controller.skip, child: Text('quizzes.skip'.tr())),
                horizontalSpace(8),
              ],
              Expanded(
                child: PrimaryButton(
                  label: isLast ? 'quizzes.finish'.tr() : 'quizzes.next'.tr(),
                  icon: isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded,
                  onPressed: session.selected == null ? null : controller.confirm,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestionTimer extends ConsumerWidget {
  const _QuestionTimer({required this.question, required this.startedAt});

  final QuizQuestion question;
  final DateTime startedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = ref.watch(quizNowProvider).value;
    final limit = question.timeLimitSec;
    final used = now == null ? 0 : now.difference(startedAt).inSeconds;
    final left = (limit - used).clamp(0, limit);
    final color = left <= 5 ? colorScheme.error : colorScheme.primary;

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: limit == 0 ? 0 : left / limit,
              strokeWidth: 4,
              color: color,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
          Text('$left', style: AppTextStyles.monoFont14Bold.copyWith(color: color)),
        ],
      ),
    );
  }
}
