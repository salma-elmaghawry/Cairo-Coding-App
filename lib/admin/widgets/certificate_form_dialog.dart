import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/pickers.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/widgets/app_text_field.dart';
import 'package:cairo_coding_app/data/models/certificate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks for a certificate's diploma name, link and date, and returns it. Nothing is saved until the student is.
class CertificateFormDialog extends ConsumerStatefulWidget {
  const CertificateFormDialog({super.key, required this.suggestedTitle});

  /// The course of the student's group, so the usual case needs no typing.
  final String suggestedTitle;

  static Future<Certificate?> show(BuildContext context, {required String suggestedTitle}) => showDialog<Certificate>(
    context: context,
    builder: (_) => CertificateFormDialog(suggestedTitle: suggestedTitle),
  );

  @override
  ConsumerState<CertificateFormDialog> createState() => _CertificateFormDialogState();
}

class _CertificateFormDialogState extends ConsumerState<CertificateFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.suggestedTitle);
  final _url = TextEditingController();
  final _date = TextEditingController();
  late DateTime _issuedOn = () {
    final now = ref.read(clockProvider)();
    return DateTime(now.year, now.month, now.day);
  }();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _date.text = context.dayMonthYear(_issuedOn);
  }

  @override
  void dispose() {
    for (final controller in [_title, _url, _date]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) => (value?.trim().isEmpty ?? true) ? 'validation.required'.tr() : null;

  String? _validateUrl(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    return uri != null && uri.isScheme('https') && uri.host.isNotEmpty ? null : 'admin.certificates.link_invalid'.tr();
  }

  Future<void> _pickDate() async {
    final picked = await pickDate(context, initial: _issuedOn);
    if (picked == null || !mounted) return;
    setState(() {
      _issuedOn = picked;
      _date.text = context.dayMonthYear(picked);
    });
  }

  void _add() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(Certificate(title: _title.text.trim(), url: _url.text.trim(), issuedOn: _issuedOn));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('admin.certificates.add'.tr()),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(label: 'admin.certificates.name'.tr(), controller: _title, validator: _required),
              verticalSpace(14),
              AppTextField(
                label: 'admin.certificates.link'.tr(),
                hint: 'https://',
                controller: _url,
                keyboardType: TextInputType.url,
                validator: _validateUrl,
              ),
              verticalSpace(14),
              AppTextField(
                label: 'admin.certificates.date'.tr(),
                controller: _date,
                readOnly: true,
                prefixIcon: Icons.event_outlined,
                onTap: _pickDate,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('common.cancel'.tr())),
        ElevatedButton(onPressed: _add, child: Text('common.add'.tr())),
      ],
    );
  }
}
