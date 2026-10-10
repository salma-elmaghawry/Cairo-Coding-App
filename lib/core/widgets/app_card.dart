import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.color, this.radius = 18, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final card = Container(
      padding: padding ?? EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colorScheme.outline),
      ),
      child: child,
    );

    if (onTap == null) return card;
    return AnimatedTap(onTap: onTap, scaleDown: AppAnimations.pressScale, child: card);
  }
}
