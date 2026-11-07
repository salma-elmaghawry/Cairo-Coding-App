import 'package:cairo_coding_app/core/const/app_links.dart';
import 'package:cairo_coding_app/core/helpers/link_launcher.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/student/settings/widgets/settings_section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The privacy policy and the account deletion page, both on the website.
class AccountSection extends StatelessWidget {
  const AccountSection({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final opened = await openExternalLink(url);
    if (!opened && context.mounted) showAppSnackBar(context, 'errors.open_link_failed'.tr(), isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final external = Icon(Icons.open_in_new_rounded, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant);

    return SettingsSection(
      title: 'settings.section_account'.tr(),
      children: [
        SettingsRow(
          icon: Icons.shield_outlined,
          title: 'settings.privacy_policy'.tr(),
          trailing: external,
          onTap: () => _open(context, AppLinks.privacyPolicy),
        ),
        SettingsRow(
          icon: Icons.person_remove_outlined,
          title: 'settings.delete_account'.tr(),
          trailing: external,
          onTap: () => _open(context, AppLinks.deleteAccount),
        ),
      ],
    );
  }
}
