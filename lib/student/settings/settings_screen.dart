import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/shared/preferences/preferences_panel.dart';
import 'package:cairo_coding_app/student/settings/widgets/profile_card.dart';
import 'package:cairo_coding_app/student/widgets/tab_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'settings.logout_title'.tr(),
      message: 'settings.logout_message'.tr(),
      confirmLabel: 'auth.logout'.tr(),
      cancelLabel: 'common.cancel'.tr(),
      destructive: true,
    );
    if (confirmed) await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return TabPage(
      eyebrow: 'settings.eyebrow'.tr(),
      title: 'settings.title'.tr(),
      slivers: [
        SliverList.list(
          children: [
            const ProfileCard(),
            verticalSpace(24),
            const PreferencesPanel(),
            verticalSpace(24),
            AppCard(
              radius: 16,
              color: colorScheme.surfaceContainerHighest,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notifications_none_rounded, color: colorScheme.primary),
                  horizontalSpace(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('settings.reminders_title'.tr(), style: AppTextStyles.font16Bold),
                        verticalSpace(2),
                        Text('settings.reminders_message'.tr(), style: AppTextStyles.font14Normal.secondary(context)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            verticalSpace(24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error.withValues(alpha: .45)),
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout_rounded),
              label: Text('auth.logout'.tr()),
            ),
          ].animateList(),
        ),
      ],
    );
  }
}
