import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

class EyebrowText extends StatelessWidget {
  const EyebrowText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('// ', style: AppTextStyles.monoFont12Medium.copyWith(color: color)),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (isRtl ? AppTextStyles.font12SemiBold : AppTextStyles.monoFont12Medium).copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
