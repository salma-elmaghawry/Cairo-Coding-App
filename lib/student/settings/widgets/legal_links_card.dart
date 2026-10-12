import 'package:cairo_coding_app/core/const/app_links.dart';
import 'package:cairo_coding_app/core/helpers/link_launcher.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LegalLinksCard extends StatelessWidget {
  const LegalLinksCard({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final opened = await openExternalLink(url);
    if (!opened && context.mounted) showAppSnackBar(context, 'errors.open_link_failed'.tr(), isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget row(IconData icon, String label, String url) => Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(label, style: AppTextStyles.font16Bold),
        trailing: Icon(Icons.open_in_new_rounded, size: 18, color: colorScheme.onSurfaceVariant),
        onTap: () => _open(context, url),
      ),
    );

    return AppCard(
      padding: EdgeInsets.zero,
      radius: 16,
      child: Column(
        children: [
          row(Icons.privacy_tip_outlined, 'settings.privacy_policy'.tr(), AppLinks.privacyPolicy),
          const Divider(),
          row(Icons.person_remove_outlined, 'settings.delete_account'.tr(), AppLinks.deleteAccount),
        ],
      ),
    );
  }
}
