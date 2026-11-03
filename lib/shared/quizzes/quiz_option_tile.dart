import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/theme/app_colors.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_format.dart';
import 'package:flutter/material.dart';

enum QuizOptionState { idle, selected, correct, wrong }

class QuizOptionTile extends StatelessWidget {
  const QuizOptionTile({
    super.key,
    required this.index,
    required this.text,
    this.state = QuizOptionState.idle,
    this.onTap,
  });

  final int index;
  final String text;
  final QuizOptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = switch (state) {
      QuizOptionState.idle || QuizOptionState.selected => colorScheme.primary,
      QuizOptionState.correct => AppColors.success,
      QuizOptionState.wrong => colorScheme.error,
    };
    final filled = state != QuizOptionState.idle;

    return Semantics(
      button: onTap != null,
      selected: state == QuizOptionState.selected,
      child: AnimatedTap(
        onTap: onTap,
        enabled: onTap != null,
        scaleDown: .98,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          curve: AppAnimations.defaultCurve,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: filled ? accent.withValues(alpha: .14) : colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: filled ? accent : colorScheme.outline, width: filled ? 2 : 1),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppAnimations.fast,
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: filled ? accent : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  optionLetter(index),
                  style: AppTextStyles.monoFont14Bold.copyWith(
                    color: filled ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              horizontalSpace(12),
              Expanded(child: Text(context.bidi(text), style: AppTextStyles.font16SemiBold)),
              AnimatedSwitcher(
                duration: AppAnimations.fast,
                child: switch (state) {
                  QuizOptionState.idle => const SizedBox(width: 22, height: 22),
                  QuizOptionState.selected => Icon(Icons.radio_button_checked_rounded, size: 22, color: accent),
                  QuizOptionState.correct => Icon(Icons.check_circle_rounded, size: 22, color: accent),
                  QuizOptionState.wrong => Icon(Icons.cancel_rounded, size: 22, color: accent),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
