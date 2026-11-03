import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/data/models/quiz_attempt.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_format.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_providers.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_session_controller.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuizTopBar extends StatelessWidget {
  const QuizTopBar({super.key, required this.session, required this.onClose});

  final QuizSession session;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = session.questions.length;
    final locked = session.attempt.answers.length;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'quizzes.leave'.tr(),
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
              horizontalSpace(10),
              Expanded(
                child: Text(
                  session.reviewing
                      ? 'quizzes.review_title'.tr()
                      : 'quizzes.question_of'.tr(args: ['${session.index + 1}', '$total']),
                  style: AppTextStyles.font14ExtraBold,
                ),
              ),
              _QuizClock(attempt: session.attempt),
            ],
          ),
          verticalSpace(10),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: total == 0 ? 0 : locked / total),
                duration: AppAnimations.normal,
                curve: AppAnimations.defaultCurve,
                builder: (_, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The quiz's own countdown; only this rebuilds every second, and only when the quiz has a limit.
class _QuizClock extends ConsumerWidget {
  const _QuizClock({required this.attempt});

  final QuizAttempt attempt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (attempt.durationMin == 0) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final now = ref.watch(quizNowProvider).value;
    final left = now == null ? Duration.zero : attempt.deadline.difference(now);
    final urgent = left.inSeconds <= 30;
    final color = urgent ? colorScheme.error : colorScheme.primary;

    return AnimatedContainer(
      duration: AppAnimations.fast,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: color),
          horizontalSpace(6),
          Text(
            formatClock(left),
            textDirection: TextDirection.ltr,
            style: AppTextStyles.monoFont14Bold.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
