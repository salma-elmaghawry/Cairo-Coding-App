import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/theme/theme_mode_provider.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PreferencesPanel extends ConsumerWidget {
  const PreferencesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('preferences.language'.tr(), style: AppTextStyles.font16Bold),
        verticalSpace(10),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: 'ar',
              label: Text('preferences.language_ar'.tr(), style: AppTextStyles.arabicLabel),
            ),
            ButtonSegment(
              value: 'en',
              label: Text('preferences.language_en'.tr(), style: AppTextStyles.latinLabel),
            ),
          ],
          selected: {context.locale.languageCode},
          onSelectionChanged: (selection) => context.setLocale(Locale(selection.first)),
        ),
        verticalSpace(22),
        Text('preferences.theme'.tr(), style: AppTextStyles.font16Bold),
        verticalSpace(10),
        SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: ThemeMode.system, label: Text('preferences.theme_system'.tr())),
            ButtonSegment(value: ThemeMode.light, label: Text('preferences.theme_light'.tr())),
            ButtonSegment(value: ThemeMode.dark, label: Text('preferences.theme_dark'.tr())),
          ],
          selected: {themeMode},
          onSelectionChanged: (selection) => ref.read(themeModeProvider.notifier).set(selection.first),
        ),
      ],
    );
  }
}
