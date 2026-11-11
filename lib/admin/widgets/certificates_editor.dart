import 'package:cairo_coding_app/admin/widgets/certificate_form_dialog.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/data/models/certificate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The student's certificates inside "Edit student": add one from a link, or remove one.
class CertificatesEditor extends StatelessWidget {
  const CertificatesEditor({
    super.key,
    required this.certificates,
    required this.suggestedTitle,
    required this.onChanged,
  });

  final List<Certificate> certificates;
  final String suggestedTitle;
  final ValueChanged<List<Certificate>> onChanged;

  Future<void> _add(BuildContext context) async {
    final added = await CertificateFormDialog.show(context, suggestedTitle: suggestedTitle);
    if (added != null) onChanged([...certificates, added]);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('admin.certificates.title'.tr(), style: AppTextStyles.font14Bold)),
            TextButton.icon(
              onPressed: () => _add(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('admin.certificates.add'.tr()),
            ),
          ],
        ),
        Text('admin.certificates.hint'.tr(), style: AppTextStyles.font12Normal.secondary(context)),
        verticalSpace(8),
        if (certificates.isEmpty)
          Text('admin.certificates.none'.tr(), style: AppTextStyles.font13Normal.muted(context))
        else
          for (final (index, certificate) in certificates.indexed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.workspace_premium_outlined, color: colorScheme.primary),
              title: Text(context.bidi(certificate.title), style: AppTextStyles.font14Bold),
              subtitle: Text(
                [
                  if (certificate.issuedOn case final date?) context.dayMonthYear(date),
                  Uri.tryParse(certificate.url)?.host ?? certificate.url,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.font12Normal.secondary(context),
              ),
              trailing: IconButton(
                tooltip: 'admin.certificates.remove'.tr(),
                style: IconButton.styleFrom(side: BorderSide.none, foregroundColor: colorScheme.error),
                onPressed: () => onChanged([...certificates]..removeAt(index)),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
              ),
            ),
      ],
    );
  }
}
