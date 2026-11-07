import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

class UnderlineTab {
  const UnderlineTab(this.label, {this.count});

  final String label;
  final int? count;
}

/// Section tabs on a bottom rule, the chosen one underlined, each with an optional count badge.
class UnderlineTabs extends StatelessWidget {
  const UnderlineTabs({super.key, required this.tabs, required this.selected, required this.onSelect});

  final List<UnderlineTab> tabs;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outline)),
      ),
      child: Wrap(
        spacing: 22,
        children: [for (final (index, tab) in tabs.indexed) _tab(context, tab, index == selected, index)],
      ),
    );
  }

  Widget _tab(BuildContext context, UnderlineTab tab, bool isSelected, int index) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: () => onSelect(index),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isSelected ? colorScheme.primary : Colors.transparent, width: 2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tab.label,
                style: (isSelected ? AppTextStyles.font15ExtraBold : AppTextStyles.font15Bold).copyWith(
                  color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                ),
              ),
              if (tab.count != null) ...[
                horizontalSpace(8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primary : colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${tab.count}',
                    style: AppTextStyles.monoFont11Bold.copyWith(
                      color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
