import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

class StudentAvatar extends StatelessWidget {
  const StudentAvatar({super.key, required this.name, required this.size, this.ring});

  final String name;
  final double size;
  final Color? ring;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primary.withValues(alpha: .16),
        border: Border.all(color: ring ?? colorScheme.outline, width: ring == null ? 1 : 3),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(_initials, style: AppTextStyles.font14ExtraBold.copyWith(color: colorScheme.primary)),
        ),
      ),
    );
  }
}
