import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 40, color: Theme.of(context).colorScheme.error),
            verticalSpace(12),
            Text(message, style: AppTextStyles.font14Normal.secondary(context), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              verticalSpace(12),
              OutlinedButton(onPressed: onRetry, child: Text('common.retry'.tr())),
            ],
          ],
        ).fadeInScale(),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message, this.icon = Icons.inbox_outlined});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
          verticalSpace(10),
          Text(message, style: AppTextStyles.font14Normal.secondary(context), textAlign: TextAlign.center),
        ],
      ).fadeInScale(),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.itemHeight = 72});

  final int count;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: List.generate(
        count,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: AnimatedSkeleton(
            width: double.infinity,
            height: itemHeight,
            borderRadius: BorderRadius.circular(16),
            baseColor: colorScheme.surface,
            highlightColor: colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
    );
  }
}
