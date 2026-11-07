import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/theme/theme_mode_provider.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/segmented_control.dart';
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
        Text('preferences.language'.tr(), style: AppTextStyles.font14Bold),
        verticalSpace(8),
        AppSegmentedControl<String>(
          segments: [
            AppSegment('ar', 'preferences.language_ar'.tr(), style: AppTextStyles.arabicLabel),
            AppSegment('en', 'preferences.language_en'.tr(), style: AppTextStyles.latinLabel),
          ],
          selected: context.locale.languageCode,
          onChanged: (code) => context.setLocale(Locale(code)),
        ),
        verticalSpace(16),
        Text('preferences.theme'.tr(), style: AppTextStyles.font14Bold),
        verticalSpace(8),
        AppSegmentedControl<ThemeMode>(
          segments: [
            AppSegment(ThemeMode.system, 'preferences.theme_system'.tr()),
            AppSegment(ThemeMode.light, 'preferences.theme_light'.tr()),
            AppSegment(ThemeMode.dark, 'preferences.theme_dark'.tr()),
          ],
          selected: themeMode,
          onChanged: (mode) => ref.read(themeModeProvider.notifier).set(mode),
        ),
      ],
    );
  }
}
