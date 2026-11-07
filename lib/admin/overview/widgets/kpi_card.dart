import 'package:cairo_coding_app/admin/overview/overview_numbers.dart';
import 'package:cairo_coding_app/admin/widgets/sparkline.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/theme/app_colors.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/icon_tile.dart';
import 'package:flutter/material.dart';

/// One headline number with its change and a sparkline.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.icon,
    required this.kpi,
    required this.format,
    this.note,
    this.vs,
  });

  final String label;
  final IconData icon;
  final Kpi kpi;

  /// Turns the value (and the change) into text.
  final String Function(double value, {bool signed}) format;

  /// Shown in place of the change, such as "2 done · 4 left".
  final String? note;

  /// What the change compares with, such as "vs the 30 days before".
  final String? vs;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final change = kpi.change;
    final up = (change ?? 0) >= 0;
    final changeColor = up ? (isDark ? AppColors.successDark : AppColors.success) : colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.font13ExtraBold.secondary(context))),
              IconTile(icon: icon, size: 34, iconSize: 17),
            ],
          ),
          verticalSpace(12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kpi.value == null ? '–' : format(kpi.value!),
                      textDirection: TextDirection.ltr,
                      style: AppTextStyles.monoFont28Bold.copyWith(height: 1, letterSpacing: -1),
                    ),
                    verticalSpace(8),
                    if (note != null)
                      Text(note!, style: AppTextStyles.font12ExtraBold.secondary(context))
                    else if (change != null)
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: format(change, signed: true),
                              style: AppTextStyles.font12ExtraBold.copyWith(color: changeColor),
                            ),
                            if (vs != null) TextSpan(text: ' $vs', style: AppTextStyles.font12SemiBold.muted(context)),
                          ],
                        ),
                      )
                    else
                      Text(' ', style: AppTextStyles.font12ExtraBold),
                  ],
                ),
              ),
              Sparkline(values: kpi.trend),
            ],
          ),
        ],
      ),
    );
  }
}
