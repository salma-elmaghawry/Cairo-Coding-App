import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

class DateBadge extends StatelessWidget {
  const DateBadge({super.key, required this.top, this.bottom, this.size = 46});

  final String top;
  final String? bottom;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            top,
            style: (bottom == null ? AppTextStyles.monoFont14Bold : AppTextStyles.monoFont10Medium).copyWith(
              color: colorScheme.primary,
            ),
          ),
          if (bottom != null) Text(bottom!, style: AppTextStyles.monoFont16Bold.copyWith(color: colorScheme.primary)),
        ],
      ),
    );
  }
}
