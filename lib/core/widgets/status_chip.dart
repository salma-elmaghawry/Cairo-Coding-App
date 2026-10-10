import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

enum StatusTone { accent, neutral, danger }

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.tone = StatusTone.accent});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (tone) {
      StatusTone.accent => colorScheme.primary,
      StatusTone.neutral => colorScheme.onSurfaceVariant,
      StatusTone.danger => colorScheme.error,
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Text(label, style: AppTextStyles.font12SemiBold.copyWith(color: color)),
    );
  }
}
