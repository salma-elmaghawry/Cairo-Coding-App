import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/pickers.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/app_text_field.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/recording.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecordingForm extends ConsumerStatefulWidget {
  const RecordingForm({super.key, required this.group, required this.onDone, this.editing});

  final AcademyGroup group;
  final Recording? editing;
  final VoidCallback onDone;

  @override
  ConsumerState<RecordingForm> createState() => _RecordingFormState();
}

class _RecordingFormState extends ConsumerState<RecordingForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.editing?.title);
  late final _number = TextEditingController(text: widget.editing?.sessionNumber.toString());
  late final _url = TextEditingController(text: widget.editing?.url);
  late DateTime _date = widget.editing?.recordedAt ?? ref.read(clockProvider)();
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [_title, _number, _url]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty) ? 'validation.required'.tr() : null;

  String? _validateNumber(String? value) =>
      (int.tryParse(value?.trim() ?? '') ?? 0) > 0 ? null : 'admin.recordings.number_invalid'.tr();

  String? _validateUrl(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    return uri != null && uri.hasScheme && uri.host.isNotEmpty ? null : 'admin.recordings.url_invalid'.tr();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final result = await ref
        .read(academyRepositoryProvider)
        .saveRecording(
          Recording(
            id: widget.editing?.id ?? '',
            groupId: widget.group.id,
            title: _title.text.trim(),
            sessionNumber: int.parse(_number.text.trim()),
            url: _url.text.trim(),
            recordedAt: _date,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        showAppSnackBar(context, 'admin.recordings.saved'.tr());
        if (widget.editing == null) {
          for (final controller in [_title, _number, _url]) {
            controller.clear();
          }
        } else {
          widget.onDone();
        }
      case Err(:final failure):
        showAppSnackBar(context, failure.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editing != null;

    return AppCard(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              (isEditing ? 'admin.recordings.edit' : 'admin.recordings.add').tr(),
              style: AppTextStyles.font18ExtraBold,
            ),
            verticalSpace(14),
            AppTextField(label: 'admin.recordings.title'.tr(), controller: _title, validator: _required),
            verticalSpace(12),
            AppTextField(
              label: 'admin.recordings.number'.tr(),
              controller: _number,
              keyboardType: TextInputType.number,
              monospace: true,
              validator: _validateNumber,
            ),
            verticalSpace(12),
            Text('admin.recordings.date'.tr(), style: AppTextStyles.font14Bold),
            verticalSpace(8),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await pickDate(context, initial: _date);
                if (picked != null) setState(() => _date = picked);
              },
              icon: const Icon(Icons.event_outlined, size: 18),
              label: Text(context.dayMonthYear(_date)),
            ),
            verticalSpace(12),
            AppTextField(
              label: 'admin.recordings.url'.tr(),
              hint: 'https://',
              controller: _url,
              keyboardType: TextInputType.url,
              monospace: true,
              validator: _validateUrl,
            ),
            verticalSpace(16),
            PrimaryButton(label: 'admin.recordings.save'.tr(), height: 48, isLoading: _saving, onPressed: _save),
            if (isEditing) ...[
              verticalSpace(8),
              TextButton(onPressed: widget.onDone, child: Text('common.cancel'.tr())),
            ],
          ],
        ),
      ),
    );
  }
}
