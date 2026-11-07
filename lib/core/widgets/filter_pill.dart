import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

/// A rounded filter choice, with an optional count badge after the label.
class FilterPill extends StatelessWidget {
  const FilterPill({super.key, required this.label, required this.selected, required this.onSelected, this.count});

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      shape: const StadiumBorder(),
      backgroundColor: colorScheme.surfaceContainer,
      selectedColor: colorScheme.primary,
      side: BorderSide(color: selected ? colorScheme.primary : colorScheme.outline),
      padding: EdgeInsetsDirectional.only(start: 8, end: count == null ? 8 : 0, top: 7, bottom: 7),
      labelStyle: (selected ? AppTextStyles.font14ExtraBold : AppTextStyles.font14Bold).copyWith(color: foreground),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count != null) ...[
            horizontalSpace(8),
            Container(
              constraints: const BoxConstraints(minWidth: 22),
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: selected ? colorScheme.onPrimary.withValues(alpha: .18) : colorScheme.surfaceContainerLowest,
              ),
              child: Text('$count', style: AppTextStyles.monoFont11Bold.copyWith(color: foreground)),
            ),
          ],
        ],
      ),
    );
  }
}

/// A row of [FilterPill]s that scrolls sideways when it runs past the screen edge.
class FilterPillBar extends StatelessWidget {
  const FilterPillBar({super.key, required this.children, this.padding = EdgeInsets.zero});

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (index, child) in children.indexed) ...[if (index > 0) horizontalSpace(8), child],
        ],
      ),
    );
  }
}
