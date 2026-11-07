import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// "Showing 1–10 of 18" with page buttons, under a table.
class TablePager extends StatelessWidget {
  const TablePager({
    super.key,
    required this.page,
    required this.pages,
    required this.shown,
    required this.total,
    required this.pageSize,
    required this.onPage,
  });

  /// From 0.
  final int page;
  final int pages;
  final int shown;
  final int total;
  final int pageSize;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final first = total == 0 ? 0 : page * pageSize + 1;
    final range = '$first–${page * pageSize + shown}';

    Widget square({required Widget child, VoidCallback? onTap, bool selected = false, String? tooltip}) => Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : null,
            borderRadius: BorderRadius.circular(9),
            border: selected ? null : Border.all(color: colorScheme.outline),
          ),
          child: child,
        ),
      ),
    );

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text('admin.table.showing'.tr(args: [range, '$total']), style: AppTextStyles.font13Normal.secondary(context)),
        if (pages > 1)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              square(
                tooltip: 'admin.table.previous'.tr(),
                onTap: page > 0 ? () => onPage(page - 1) : null,
                child: const Icon(Icons.chevron_left_rounded, size: 18),
              ),
              for (var index = 0; index < pages; index++) ...[
                horizontalSpace(4),
                square(
                  selected: index == page,
                  onTap: () => onPage(index),
                  child: Text(
                    '${index + 1}',
                    style: AppTextStyles.monoFont12Bold.copyWith(
                      color: index == page ? colorScheme.onPrimary : colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
              horizontalSpace(4),
              square(
                tooltip: 'admin.table.next'.tr(),
                onTap: page < pages - 1 ? () => onPage(page + 1) : null,
                child: const Icon(Icons.chevron_right_rounded, size: 18),
              ),
            ],
          ),
      ],
    );
  }
}
