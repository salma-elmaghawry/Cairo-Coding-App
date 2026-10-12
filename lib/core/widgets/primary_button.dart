import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 52,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled && !isLoading,
      label: label,
      onTap: enabled && !isLoading ? onPressed : null,
      excludeSemantics: true,
      child: AnimatedButton(
        onPressed: onPressed,
        isLoading: isLoading,
        height: height,
        shrinkWrap: !expand,
        borderRadius: BorderRadius.circular(14),
        backgroundColor: enabled ? colorScheme.primary : colorScheme.primary.withValues(alpha: .4),
        loadingColor: colorScheme.onPrimary,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 20, color: colorScheme.onPrimary), horizontalSpace(8)],
              if (expand) Flexible(child: _label(colorScheme)) else _label(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(ColorScheme colorScheme) => Text(
    label,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: AppTextStyles.font16ExtraBold.copyWith(color: colorScheme.onPrimary),
  );
}
