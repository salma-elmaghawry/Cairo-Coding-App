import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:flutter/material.dart';

class QuizStatTile extends StatelessWidget {
  const QuizStatTile({super.key, required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    // Values can hold words ("10 min"), and the mono font has no Arabic letters.
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          verticalSpace(10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.font12Normal.secondary(context),
          ),
          verticalSpace(2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(value, style: isRtl ? AppTextStyles.font16ExtraBold : AppTextStyles.monoFont16Bold),
          ),
        ],
      ),
    );
  }
}
