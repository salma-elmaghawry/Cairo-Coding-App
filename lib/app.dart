import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/theme/app_theme.dart';
import 'package:cairo_coding_app/core/theme/theme_mode_provider.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CairoCodingApp extends ConsumerWidget {
  const CairoCodingApp({super.key, required this.routerProvider});

  final Provider<GoRouter> routerProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppTextStyles.setLanguage(context.locale.languageCode);
    final flavor = ref.watch(appFlavorProvider);

    return MaterialApp.router(
      onGenerateTitle: (_) => flavor.titleKey.tr(),
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      scrollBehavior: const _NoGlowScrollBehavior(),
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

class _NoGlowScrollBehavior extends MaterialScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
