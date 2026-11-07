import 'package:cairo_coding_app/core/theme/app_colors.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

/// A round avatar with someone's initials, in one of a few purples picked from their name.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.size = 36, this.ring});

  final String name;
  final double size;

  /// A border in the color behind the avatar, so overlapping avatars stay apart.
  final Color? ring;

  static const _palette = [
    (AppColors.primaryLight, Colors.white),
    (Color(0xFFA855F7), AppColors.onPrimaryDark),
    (AppColors.secondaryDark, AppColors.onPrimaryDark),
    (AppColors.secondaryLight, Colors.white),
  ];

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _palette[name.codeUnits.fold(0, (sum, unit) => sum + unit) % _palette.length];

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        border: ring == null ? null : Border.all(color: ring!, width: 2),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Text(
            initialsOf(name),
            style: AppTextStyles.font12ExtraBold.copyWith(color: foreground, fontSize: size * .34),
          ),
        ),
      ),
    );
  }
}

/// Up to three avatars overlapping, the first on top.
class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key, required this.names, this.size = 28, required this.ring});

  final List<String> names;
  final double size;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    final shown = names.take(3).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    final step = size * .72;

    return ExcludeSemantics(
      child: SizedBox(
        width: size + step * (shown.length - 1),
        height: size,
        child: Stack(
          children: [
            for (final (index, name) in shown.indexed.toList().reversed)
              PositionedDirectional(
                start: step * index,
                child: InitialsAvatar(name: name, size: size, ring: ring),
              ),
          ],
        ),
      ),
    );
  }
}
