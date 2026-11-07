import 'package:flutter/material.dart';

/// An icon on a tinted rounded square, used at the start of list rows and cards.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.color,
    this.background,
    this.border,
    this.size = 44,
    this.iconSize,
  });

  final IconData icon;

  /// Defaults to the primary color; the background is a tint of it unless given.
  final Color? color;
  final Color? background;
  final Color? border;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? tint.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(size * .3),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Icon(icon, size: iconSize ?? size * .48, color: tint),
    );
  }
}
