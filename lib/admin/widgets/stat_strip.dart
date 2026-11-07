import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Numbers side by side in one box, each with a small label under it.
class StatStrip extends StatelessWidget {
  const StatStrip({super.key, required this.items});

  /// Value, then label.
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (index, (value, label)) in items.indexed) ...[
              if (index > 0) VerticalDivider(width: 1, color: colorScheme.outline),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, textDirection: TextDirection.ltr, style: AppTextStyles.monoFont14Bold),
                    Text(label, style: AppTextStyles.font12Normal.secondary(context)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
