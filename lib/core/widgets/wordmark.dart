import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cairo Coding School',
      excludeSemantics: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text('CAIRO;\nCODING\nSCHOOL', style: AppTextStyles.wordmarkOf(fontSize)),
      ),
    );
  }
}
