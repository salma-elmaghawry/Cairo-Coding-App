import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/widgets/admin_panel.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_text_field.dart';
import 'package:cairo_coding_app/core/widgets/icon_tile.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
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
  late final _url = TextEditingController(text: widget.editing?.url);
  late final _minutes = TextEditingController(
    text: (widget.editing?.durationMin ?? 0) > 0 ? '${widget.editing!.durationMin}' : '',
  );
  late int? _number = widget.editing?.sessionNumber;
  late DateTime _date = widget.editing?.recordedAt ?? ref.read(clockProvider)();
  bool _notify = true;
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [_title, _url, _minutes]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty) ? 'validation.required'.tr() : null;

  String? _validateUrl(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    return uri != null && uri.hasScheme && uri.host.isNotEmpty ? null : 'admin.recordings.url_invalid'.tr();
  }

  String? _validateMinutes(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty || (int.tryParse(text) ?? 0) > 0 ? null : 'admin.recordings.minutes_invalid'.tr();
  }

  /// Picking a session fills in its date, and its topic when the title is still empty.
  void _pick(ClassSession? session) => setState(() {
    if (session == null) return;
    _number = session.number;
    _date = session.startsAt;
    if (_title.text.trim().isEmpty && session.topic.isNotEmpty) _title.text = session.topic;
  });

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repository = ref.read(academyRepositoryProvider);
    final isNew = widget.editing == null;
    final title = _title.text.trim();
    final result = await repository.saveRecording(
      Recording(
        id: widget.editing?.id ?? '',
        groupId: widget.group.id,
        title: title,
        sessionNumber: _number!,
        url: _url.text.trim(),
        recordedAt: _date,
        durationMin: int.tryParse(_minutes.text.trim()) ?? 0,
      ),
    );
    if (result is Ok && isNew && _notify) {
      await repository.postAnnouncement(
        title: 'admin.recordings.notify_title'.tr(args: [title]),
        body: 'admin.recordings.notify_body'.tr(args: ['$_number']),
        groupIds: [widget.group.id],
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        showAppSnackBar(context, 'admin.recordings.saved'.tr());
        if (isNew) {
          for (final controller in [_title, _url, _minutes]) {
            controller.clear();
          }
          setState(() => _number = null);
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
    final colorScheme = Theme.of(context).colorScheme;
    final sessions = (ref.watch(groupSessionsProvider(widget.group.id)).value ?? const <ClassSession>[])
        .where((s) => s.number != null && !s.isCancelled)
        .toList()
        .reversed;
    final byNumber = {for (final session in sessions) session.number!: session};

    return AdminPanel(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const IconTile(icon: Icons.video_call_outlined, size: 40, iconSize: 20),
                horizontalSpace(12),
                Flexible(
                  child: Text(
                    (isEditing ? 'admin.recordings.edit' : 'admin.recordings.add').tr(),
                    style: AppTextStyles.font18ExtraBold,
                  ),
                ),
              ],
            ),
            verticalSpace(16),
            Text('admin.recordings.session'.tr(), style: AppTextStyles.font14Bold),
            verticalSpace(8),
            DropdownButtonFormField<int>(
              initialValue: _number,
              isExpanded: true,
              validator: (value) => value == null ? 'admin.recordings.session_required'.tr() : null,
              items: [
                for (final session in byNumber.values)
                  DropdownMenuItem(
                    value: session.number,
                    child: Text(
                      [
                        '#${'${session.number}'.padLeft(2, '0')}',
                        context.shortDay(session.startsAt),
                        if (session.topic.isNotEmpty) context.bidi(session.topic),
                      ].join(' · '),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (_number != null && !byNumber.containsKey(_number))
                  DropdownMenuItem(value: _number, child: Text('#${'$_number'.padLeft(2, '0')}')),
              ],
              onChanged: (number) => _pick(byNumber[number]),
            ),
            verticalSpace(12),
            AppTextField(label: 'admin.recordings.title'.tr(), controller: _title, validator: _required),
            verticalSpace(12),
            AppTextField(
              label: 'admin.recordings.url'.tr(),
              hint: 'https://',
              controller: _url,
              prefixIcon: Icons.link_rounded,
              keyboardType: TextInputType.url,
              monospace: true,
              validator: _validateUrl,
            ),
            verticalSpace(12),
            AppTextField(
              label: 'admin.recordings.minutes'.tr(),
              hint: '120',
              controller: _minutes,
              keyboardType: TextInputType.number,
              monospace: true,
              validator: _validateMinutes,
            ),
            if (!isEditing) ...[
              verticalSpace(14),
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 6, 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('admin.recordings.notify'.tr(), style: AppTextStyles.font14ExtraBold),
                    subtitle: Text(
                      'admin.recordings.notify_hint'.tr(),
                      style: AppTextStyles.font12Normal.secondary(context),
                    ),
                    value: _notify,
                    onChanged: (value) => setState(() => _notify = value),
                  ),
                ),
              ),
            ],
            verticalSpace(16),
            PrimaryButton(
              label: 'admin.recordings.save'.tr(),
              height: 46,
              glow: true,
              isLoading: _saving,
              onPressed: _save,
            ),
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
