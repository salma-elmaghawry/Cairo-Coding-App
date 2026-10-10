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
  });

  final List<AppTableColumn> columns;
  final List<List<Widget>> rows;
  final double minWidth;
  final Set<int> dimmedRows;

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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = math.max(constraints.maxWidth, minWidth);
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                child: Column(
                  children: [
                    _row([
                      for (final column in columns)
                        Text(column.label, style: AppTextStyles.font12SemiBold.secondary(context)),
                    ], padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
                    for (final (index, cells) in rows.indexed) ...[
                      const Divider(),
                      Opacity(opacity: dimmedRows.contains(index) ? .6 : 1, child: _row(cells)),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
