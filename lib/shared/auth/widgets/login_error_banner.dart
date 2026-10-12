import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

class LoginErrorBanner extends StatelessWidget {
  const LoginErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: error.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: error.withValues(alpha: .4)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, size: 20, color: error),
            horizontalSpace(10),
            Expanded(
              child: Text(message, style: AppTextStyles.font14SemiBold.copyWith(color: error)),
            ),
          ],
        ),
      ),
    ).fadeInSlideUp();
  }
}
