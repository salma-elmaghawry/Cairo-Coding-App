import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/theme/app_colors.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

class QuizScoreHero extends StatelessWidget {
  const QuizScoreHero({super.key, required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (percent) {
      >= 70 => AppColors.success,
      >= 50 => colorScheme.tertiary,
      _ => colorScheme.error,
    };

    return SizedBox(
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: _SunburstPainter(colorScheme.primary.withValues(alpha: .14)))),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percent / 100),
            duration: AppAnimations.verySlow * 2,
            curve: AppAnimations.defaultCurve,
            builder: (context, value, _) => SizedBox(
              width: 130,
              height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 11,
                      strokeCap: StrokeCap.round,
                      color: color,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  Text('${(value * 100).round()}%', style: AppTextStyles.monoFont28Bold.copyWith(color: color)),
                ],
              ),
            ),
          ).popIn(),
        ],
      ),
    );
  }
}

/// Soft rays behind the score, fading out before they reach the content around it.
class _SunburstPainter extends CustomPainter {
  const _SunburstPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final paint = Paint()..shader = ui.Gradient.radial(center, radius, [color, color.withValues(alpha: 0)], [.45, 1]);
    const rays = 14;
    const step = 2 * math.pi / rays;
    for (var i = 0; i < rays; i++) {
      final start = step * i;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + radius * math.cos(start), center.dy + radius * math.sin(start))
        ..lineTo(center.dx + radius * math.cos(start + step / 2), center.dy + radius * math.sin(start + step / 2))
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SunburstPainter oldDelegate) => oldDelegate.color != color;
}
