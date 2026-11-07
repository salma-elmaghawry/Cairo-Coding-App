import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A small trend line with no axes, for a KPI card.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, this.width = 88, this.height = 36});

  final List<double> values;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return SizedBox(width: width, height: height);
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(width, height),
        painter: _SparklinePainter(values: values, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final low = values.reduce(math.min);
    final high = values.reduce(math.max);
    final span = high - low == 0 ? 1 : high - low;
    final path = Path();
    for (final (index, value) in values.indexed) {
      final x = 2 + index * (size.width - 4) / (values.length - 1);
      final y = size.height - 4 - (value - low) / span * (size.height - 8);
      index == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.values != values || old.color != color;
}
