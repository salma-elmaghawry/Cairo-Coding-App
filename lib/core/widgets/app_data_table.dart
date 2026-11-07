import 'dart:math' as math;

import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

class AppTableColumn {
  const AppTableColumn(this.label, {this.flex = 1, this.alignEnd = false});

  final String label;
  final int flex;
  final bool alignEnd;
}

class AppDataTable extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minWidth = 640,
    this.dimmedRows = const {},
    this.highlightedRows = const {},
    this.header,
    this.footer,
  });

  final List<AppTableColumn> columns;
  final List<List<Widget>> rows;
  final double minWidth;
  final Set<int> dimmedRows;

  /// Rows with a faint tint, such as the next session.
  final Set<int> highlightedRows;

  /// Sits above the column titles, inside the card: filters, search, buttons.
  final Widget? header;

  /// Sits under the last row, inside the card: paging.
  final Widget? footer;

  Widget _row(List<Widget> cells, {EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 10)}) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          for (final (index, column) in columns.indexed)
            Expanded(
              flex: column.flex,
              child: Align(
                alignment: column.alignEnd ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                child: cells[index],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final divider = Divider(color: colorScheme.primary.withValues(alpha: .12));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) ...[Padding(padding: const EdgeInsets.all(16), child: header), divider],
            LayoutBuilder(
              builder: (context, constraints) {
                final width = math.max(constraints.maxWidth, minWidth);
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: width,
                    child: Column(
                      children: [
                        ColoredBox(
                          color: colorScheme.surfaceContainerLowest.withValues(alpha: .35),
                          child: _row([
                            for (final column in columns)
                              Text(
                                column.label.toUpperCase(),
                                style: AppTextStyles.font11ExtraBold.muted(context).copyWith(letterSpacing: .9),
                              ),
                          ], padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13)),
                        ),
                        for (final (index, cells) in rows.indexed) ...[
                          divider,
                          ColoredBox(
                            color: highlightedRows.contains(index)
                                ? colorScheme.primary.withValues(alpha: .08)
                                : Colors.transparent,
                            child: Opacity(opacity: dimmedRows.contains(index) ? .6 : 1, child: _row(cells)),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            if (footer != null) ...[divider, Padding(padding: const EdgeInsets.all(12), child: footer)],
          ],
        ),
      ),
    );
  }
}
