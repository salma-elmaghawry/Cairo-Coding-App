import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

class EyebrowText extends StatelessWidget {
  const EyebrowText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      '// $text',
      style: AppTextStyles.monoFont12Medium.copyWith(color: Theme.of(context).colorScheme.primary),
    );
  }
}
