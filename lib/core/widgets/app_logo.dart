import 'package:cairo_coding_app/core/const/app_assets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Image.asset(
      AppAssets.logo,
      width: size,
      height: size,
      color: isDark ? null : theme.colorScheme.onSurface,
      colorBlendMode: isDark ? null : BlendMode.srcIn,
      semanticLabel: 'app_name'.tr(),
    );
  }
}
