import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_animations.dart';

class AnimatedTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;
  final Duration duration;
  final bool enabled;

  const AnimatedTap({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 100),
    this.enabled = true,
  });

  @override
  State<AnimatedTap> createState() => _AnimatedTapState();
}

class _AnimatedTapState extends State<AnimatedTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enabled) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.enabled) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.enabled) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}

class AnimatedButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? loadingColor;
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final bool shrinkWrap;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isLoading = false,
    this.loadingColor,
    this.height = 56,
    this.width,
    this.borderRadius,
    this.backgroundColor,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTap(
      onTap: isLoading ? null : onPressed,
      enabled: !isLoading,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        height: height,
        width: shrinkWrap ? null : (width ?? double.infinity),
        decoration: BoxDecoration(color: backgroundColor, borderRadius: borderRadius ?? BorderRadius.circular(20)),
        child: AnimatedSwitcher(
          duration: AppAnimations.fast,
          child: isLoading
              ? Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: loadingColor ?? Colors.white),
                  ),
                )
              : child,
        ),
      ),
    );
  }
}

class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, child) {
        return Text('$animatedValue', style: style);
      },
    );
  }
}

class AnimatedExpand extends StatelessWidget {
  final Widget child;
  final bool isExpanded;
  final Duration duration;
  final Curve curve;

  const AnimatedExpand({
    super.key,
    required this.child,
    required this.isExpanded,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: child
          .animate(target: isExpanded ? 1 : 0)
          .fadeIn(duration: duration, curve: curve)
          .slideY(begin: -0.1, end: 0, duration: duration, curve: curve),
      crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: duration,
      sizeCurve: curve,
    );
  }
}

class AnimatedSlideVisibility extends StatelessWidget {
  final Widget child;
  final bool isVisible;
  final Duration duration;
  final Curve curve;
  final Offset slideOffset;

  const AnimatedSlideVisibility({
    super.key,
    required this.child,
    required this.isVisible,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.slideOffset = const Offset(0, 0.2),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(begin: slideOffset, end: Offset.zero).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: isVisible ? child : const SizedBox.shrink(),
    );
  }
}

class AnimatedSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const AnimatedSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: baseColor ?? Colors.grey.shade200,
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: const Duration(milliseconds: 1500), color: highlightColor ?? Colors.grey.shade100);
  }
}

class AnimatedRotatingIcon extends StatelessWidget {
  final IconData icon;
  final bool isRotated;
  final double rotationAngle;
  final Duration duration;
  final Color? color;
  final double size;

  const AnimatedRotatingIcon({
    super.key,
    required this.icon,
    required this.isRotated,
    this.rotationAngle = 0.5,
    this.duration = const Duration(milliseconds: 300),
    this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: isRotated ? rotationAngle : 0,
      duration: duration,
      curve: Curves.easeInOutCubic,
      child: Icon(icon, color: color, size: size),
    );
  }
}

class AnimatedPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;

  AnimatedPageRoute({required this.page, this.direction = SlideDirection.right})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final begin = direction.offset;
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeOutCubic));
          final offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: AppAnimations.normal,
        reverseTransitionDuration: AppAnimations.fast,
      );
}

enum SlideDirection {
  right,
  left,
  up,
  down;

  Offset get offset {
    switch (this) {
      case SlideDirection.right:
        return const Offset(1.0, 0.0);
      case SlideDirection.left:
        return const Offset(-1.0, 0.0);
      case SlideDirection.up:
        return const Offset(0.0, 1.0);
      case SlideDirection.down:
        return const Offset(0.0, -1.0);
    }
  }
}
