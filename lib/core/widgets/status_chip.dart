import 'package:cairo_coding_app/core/theme/app_colors.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

enum StatusTone { accent, neutral, danger, success, gold }

extension StatusToneColor on StatusTone {
  Color color(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (this) {
      StatusTone.accent => colorScheme.primary,
      StatusTone.neutral => colorScheme.onSurfaceVariant,
      StatusTone.danger => colorScheme.error,
      StatusTone.success => Theme.of(context).brightness == Brightness.dark ? AppColors.successDark : AppColors.success,
      StatusTone.gold => colorScheme.tertiary,
    };
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.tone = StatusTone.accent});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = tone.color(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Text(label, style: AppTextStyles.font12Bold.copyWith(color: color)),
    );
  }
}
