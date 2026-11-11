import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/shared/preferences/preferences_panel.dart';
import 'package:cairo_coding_app/student/reminders/reminder_providers.dart';
import 'package:cairo_coding_app/student/profile/widgets/account_section.dart';
import 'package:cairo_coding_app/student/profile/widgets/certificates_section.dart';
import 'package:cairo_coding_app/student/profile/widgets/profile_card.dart';
import 'package:cairo_coding_app/student/profile/widgets/rates_row.dart';
import 'package:cairo_coding_app/student/profile/widgets/reminders_section.dart';
import 'package:cairo_coding_app/student/profile/widgets/settings_section.dart';
import 'package:cairo_coding_app/student/profile/widgets/studies_section.dart';
import 'package:cairo_coding_app/student/widgets/tab_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Who the student is and how they're doing (name, email, diploma, group, attendance, tasks, certificates),
/// then the app's preferences and logging out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'settings.logout_title'.tr(context: context),
      message: 'settings.logout_message'.tr(context: context),
      confirmLabel: 'auth.logout'.tr(context: context),
      cancelLabel: 'common.cancel'.tr(context: context),
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(reminderSchedulerProvider).clear();
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return TabPage(
      eyebrow: 'profile.eyebrow'.tr(context: context),
      title: 'profile.title'.tr(context: context),
      slivers: [
        SliverList.list(
          children: [
            const ProfileCard(),
            verticalSpace(24),
            const StudiesSection(),
            verticalSpace(12),
            const RatesRow(),
            verticalSpace(24),
            const CertificatesSection(),
            verticalSpace(24),
            SettingsSection(
              title: 'settings.section_appearance'.tr(context: context),
              children: const [Padding(padding: EdgeInsets.all(14), child: PreferencesPanel())],
            ),
            verticalSpace(24),
            const RemindersSection(),
            verticalSpace(24),
            const AccountSection(),
            verticalSpace(24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                backgroundColor: colorScheme.error.withValues(alpha: .08),
                side: BorderSide(color: colorScheme.error.withValues(alpha: .35)),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: AppTextStyles.font16ExtraBold,
              ),
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout_rounded),
              label: Text('auth.logout'.tr(context: context)),
            ),
          ].animateList(),
        ),
      ],
    );
  }
}
