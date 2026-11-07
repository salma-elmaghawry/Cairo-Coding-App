import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

class AppSegment<T> {
  const AppSegment(this.value, this.label, {this.style});

  final T value;
  final String label;

  /// Overrides the font, for a label that must keep its own script (العربية, English).
  final TextStyle? style;
}

/// Equal-width options in a sunken track; the chosen one is raised.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.height = 40,
  });

  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        children: [
          for (final (index, segment) in segments.indexed) ...[
            if (index > 0) horizontalSpace(4),
            Expanded(child: _segment(segment, colorScheme, isDark)),
          ],
        ],
      ),
    );
  }

  Widget _segment(AppSegment<T> segment, ColorScheme colorScheme, bool isDark) {
    final isSelected = segment.value == selected;
    final style = (segment.style ?? AppTextStyles.font14Bold).copyWith(
      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
      color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
    );

    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        curve: AppAnimations.defaultCurve,
        height: height,
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.surface : colorScheme.surface.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? .5 : .1),
                blurRadius: 10,
                spreadRadius: -4,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: isSelected ? null : () => onChanged(segment.value),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(segment.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
