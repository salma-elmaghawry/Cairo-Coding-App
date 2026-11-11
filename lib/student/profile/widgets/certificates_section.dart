import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/link_launcher.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/data/models/certificate.dart';
import 'package:cairo_coding_app/student/profile/widgets/settings_section.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Certificates the academy issued, each opening its file outside the app.
class CertificatesSection extends ConsumerWidget {
  const CertificatesSection({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final opened = await openExternalLink(url);
    if (!opened && context.mounted) {
      showAppSnackBar(context, 'errors.open_link_failed'.tr(context: context), isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final certificates =
        ref.watch(currentUserProvider.select((user) => user?.profile.certificates)) ?? const <Certificate>[];
    final external = Icon(Icons.open_in_new_rounded, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant);

    return SettingsSection(
      title: 'profile.section_certificates'.tr(context: context),
      children: [
        if (certificates.isEmpty)
          SettingsRow(
            icon: Icons.workspace_premium_outlined,
            title: 'profile.no_certificates'.tr(context: context),
            subtitle: 'profile.no_certificates_hint'.tr(context: context),
          )
        else
          for (final certificate in certificates)
            SettingsRow(
              icon: Icons.workspace_premium_outlined,
              title: context.bidi(certificate.title),
              subtitle: switch (certificate.issuedOn) {
                final date? => 'profile.issued_on'.tr(context: context, args: [context.dayMonthYear(date)]),
                null => null,
              },
              trailing: external,
              onTap: () => _open(context, certificate.url),
            ),
      ],
    );
  }
}
