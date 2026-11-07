import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

/// The next seven days; a dot marks the days that have a session.
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.start,
    required this.selected,
    required this.busyDays,
    required this.onSelect,
  });

  /// The first day shown, at midnight.
  final DateTime start;
  final DateTime selected;
  final Set<DateTime> busyDays;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final days = [for (var i = 0; i < 7; i++) DateUtils.addDaysToDate(start, i)];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        children: [
          for (final (index, day) in days.indexed) ...[
            if (index > 0) horizontalSpace(4),
            Expanded(
              child: _Day(
                date: day,
                selected: DateUtils.isSameDay(day, selected),
                busy: busyDays.contains(day),
                onTap: () => onSelect(day),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.date, required this.selected, required this.busy, required this.onTap});

  final DateTime date;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected ? colorScheme.onPrimary : colorScheme.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      label: context.fullDay(date),
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        curve: AppAnimations.defaultCurve,
        height: 72,
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: .7),
                blurRadius: 18,
                spreadRadius: -8,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      context.weekdayShort(date),
                      style: AppTextStyles.font11ExtraBold.copyWith(color: foreground.withValues(alpha: .8)),
                    ),
                  ),
                ),
                verticalSpace(2),
                Text(context.dayNumber(date), style: AppTextStyles.monoFont16Bold.copyWith(color: foreground)),
                verticalSpace(4),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: !busy ? null : (selected ? colorScheme.onPrimary : colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
