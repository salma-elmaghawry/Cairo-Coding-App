import 'dart:math' as math;

import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:flutter/material.dart';

/// Lays cards out in as many equal columns of at least 320 as fit.
class CardGrid extends StatelessWidget {
  const CardGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 16.0;
        final columns = math.max(1, (constraints.maxWidth + gap) ~/ (320 + gap));
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final child in children) SizedBox(width: width, child: child)].animateList(),
        );
      },
    );
  }
}
