import 'package:flutter/material.dart';

/// The raised card at the top of a tab: a soft glow in one corner over the surface color.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.glow = AlignmentDirectional.topEnd,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// The corner the glow spreads from.
  final AlignmentDirectional glow;

  static const double radius = 24;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colorScheme.primary.withValues(alpha: .3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? .55 : .08),
            blurRadius: 40,
            spreadRadius: -18,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius - 1),
          gradient: RadialGradient(
            center: glow.resolve(Directionality.of(context)),
            radius: 1.1,
            colors: [
              colorScheme.primary.withValues(alpha: isDark ? .28 : .14),
              colorScheme.primary.withValues(alpha: 0),
            ],
            stops: const [0, .6],
          ),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
