import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/icon_tile.dart';
import 'package:flutter/material.dart';

/// A small all-caps heading over a card of rows.
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4),
          child: Semantics(
            header: true,
            child: Text(
              title.toUpperCase(),
              style: AppTextStyles.font12ExtraBold.muted(context).copyWith(letterSpacing: 1),
            ),
          ),
        ),
        verticalSpace(10),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, child) in children.indexed) ...[
                  if (index > 0) Divider(color: colorScheme.primary.withValues(alpha: .14)),
                  child,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// An icon, a title with an optional hint under it, and a control or chevron at the end.
class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.icon, required this.title, this.subtitle, this.trailing, this.onTap});

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            IconTile(icon: icon, size: 38, iconSize: 18),
            horizontalSpace(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.font15Bold),
                  if (subtitle != null) ...[
                    verticalSpace(1),
                    Text(subtitle!, style: AppTextStyles.font12Normal.secondary(context)),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[horizontalSpace(8), trailing!],
          ],
        ),
      ),
    );
  }
}
