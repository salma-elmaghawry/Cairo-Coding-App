import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppAnimations {
  AppAnimations._();

  static const Duration ultraFast = Duration(milliseconds: 100);

  static const Duration fast = Duration(milliseconds: 200);

  static const Duration normal = Duration(milliseconds: 300);

  static const Duration medium = Duration(milliseconds: 400);

  static const Duration slow = Duration(milliseconds: 500);

  static const Duration verySlow = Duration(milliseconds: 700);

  static const Curve defaultCurve = Curves.easeOutCubic;

  static const Curve bounceCurve = Curves.elasticOut;

  static const Curve snappyCurve = Curves.easeOutBack;

  static const Curve slideInCurve = Curves.decelerate;

  static const Curve emphasisCurve = Curves.easeInOutCubic;

  static const Duration staggerDelay = Duration(milliseconds: 50);

  static const Duration gridStaggerDelay = Duration(milliseconds: 80);

  static const Duration sectionDelay = Duration(milliseconds: 100);

  static const Offset slideUpSmall = Offset(0, 20);

  static const Offset slideUpNormal = Offset(0, 30);

  static const Offset slideUpLarge = Offset(0, 50);

  static const Offset slideFromLeft = Offset(-30, 0);

  static const Offset slideFromRight = Offset(30, 0);

  static const double pressScale = 0.95;

  static const double tapBounceScale = 0.9;

  static const double revealScale = 0.8;

  static const double attentionScale = 1.05;
}

extension AppAnimateExtensions on Widget {
  Widget fadeInSlideUp({Duration? duration, Duration? delay, Offset? offset, Curve? curve}) {
    return animate(delay: delay)
        .fadeIn(duration: duration ?? AppAnimations.normal, curve: curve ?? AppAnimations.defaultCurve)
        .slideY(
          begin: (offset?.dy ?? AppAnimations.slideUpNormal.dy) / 100,
          end: 0,
          duration: duration ?? AppAnimations.normal,
          curve: curve ?? AppAnimations.defaultCurve,
        );
  }

  Widget fadeInScale({Duration? duration, Duration? delay, double? beginScale, Curve? curve}) {
    return animate(delay: delay)
        .fadeIn(duration: duration ?? AppAnimations.normal, curve: curve ?? AppAnimations.defaultCurve)
        .scale(
          begin: Offset(beginScale ?? AppAnimations.revealScale, beginScale ?? AppAnimations.revealScale),
          end: const Offset(1, 1),
          duration: duration ?? AppAnimations.normal,
          curve: curve ?? AppAnimations.snappyCurve,
        );
  }

  Widget slideInFromLeft({Duration? duration, Duration? delay, Curve? curve}) {
    return animate(delay: delay)
        .fadeIn(duration: duration ?? AppAnimations.normal, curve: curve ?? AppAnimations.defaultCurve)
        .slideX(
          begin: -0.3,
          end: 0,
          duration: duration ?? AppAnimations.normal,
          curve: curve ?? AppAnimations.slideInCurve,
        );
  }

  Widget slideInFromRight({Duration? duration, Duration? delay, Curve? curve}) {
    return animate(delay: delay)
        .fadeIn(duration: duration ?? AppAnimations.normal, curve: curve ?? AppAnimations.defaultCurve)
        .slideX(
          begin: 0.3,
          end: 0,
          duration: duration ?? AppAnimations.normal,
          curve: curve ?? AppAnimations.slideInCurve,
        );
  }

  Widget popIn({Duration? duration, Duration? delay, Curve? curve}) {
    return animate(delay: delay)
        .fadeIn(duration: duration ?? AppAnimations.fast)
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          duration: duration ?? AppAnimations.medium,
          curve: curve ?? AppAnimations.bounceCurve,
        );
  }

  Widget shimmer({Duration? duration, Color? color}) {
    return animate(onPlay: (controller) => controller.repeat()).shimmer(
      duration: duration ?? const Duration(milliseconds: 1500),
      color: color ?? Colors.white.withValues(alpha: 0.3),
    );
  }

  Widget pulse({Duration? duration}) {
    return animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(
      begin: const Offset(1, 1),
      end: const Offset(1.05, 1.05),
      duration: duration ?? const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
    );
  }

  Widget shake({Duration? duration, double? offset}) {
    return animate().shake(duration: duration ?? AppAnimations.medium, hz: 4, offset: Offset(offset ?? 10, 0));
  }
}

extension StaggeredListAnimation on List<Widget> {
  List<Widget> animateList({
    Duration? itemDuration,
    Duration? staggerDelay,
    Offset? slideOffset,
    bool fadeIn = true,
    bool slideUp = true,
  }) {
    return asMap().entries.map((entry) {
      final index = entry.key;
      final widget = entry.value;

      Widget animatedWidget = widget.animate(delay: (staggerDelay ?? AppAnimations.staggerDelay) * index);

      if (fadeIn) {
        animatedWidget = (animatedWidget as Animate).fadeIn(
          duration: itemDuration ?? AppAnimations.normal,
          curve: AppAnimations.defaultCurve,
        );
      }

      if (slideUp) {
        animatedWidget = (animatedWidget as Animate).slideY(
          begin: (slideOffset?.dy ?? 20) / 100,
          end: 0,
          duration: itemDuration ?? AppAnimations.normal,
          curve: AppAnimations.defaultCurve,
        );
      }

      return animatedWidget;
    }).toList();
  }
}

class AnimationBuilder {
  static List<Widget> staggerColumn({
    required List<Widget> children,
    Duration? duration,
    Duration? staggerDelay,
    int startIndex = 0,
  }) {
    return children.asMap().entries.map((entry) {
      final index = entry.key + startIndex;
      return entry.value.fadeInSlideUp(delay: (staggerDelay ?? AppAnimations.staggerDelay) * index, duration: duration);
    }).toList();
  }

  static Widget staggerGrid({
    required List<Widget> children,
    required int crossAxisCount,
    Duration? duration,
    Duration? staggerDelay,
  }) {
    final animatedChildren = children.asMap().entries.map((entry) {
      final index = entry.key;

      final row = index ~/ crossAxisCount;
      final col = index % crossAxisCount;
      final diagonalIndex = row + col;

      return entry.value.fadeInScale(
        delay: (staggerDelay ?? AppAnimations.gridStaggerDelay) * diagonalIndex,
        duration: duration,
      );
    }).toList();

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: animatedChildren,
    );
  }
}
