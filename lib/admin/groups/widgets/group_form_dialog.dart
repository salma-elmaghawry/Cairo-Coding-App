import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/pickers.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_text_field.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupFormDialog extends ConsumerStatefulWidget {
  const GroupFormDialog({super.key, this.group, this.courseId});

  final AcademyGroup? group;

  /// Pre-selected course for a new group, when it's created from a course page.
  final String? courseId;

  static Future<void> show(BuildContext context, {AcademyGroup? group, String? courseId}) {
    return showDialog<void>(
      context: context,
      builder: (_) => GroupFormDialog(group: group, courseId: courseId),
    );
  }

  @override
  ConsumerState<GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends ConsumerState<GroupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.group?.name);
  late String _courseId = widget.group?.courseId ?? widget.courseId ?? '';
  late final _link = TextEditingController(text: widget.group?.meetingLink);
  late final _location = TextEditingController(text: widget.group?.location);
  late DateTime _start = widget.group?.startDate ?? DateTime.now();
  late DateTime _end = widget.group?.endDate ?? DateTime.now().add(const Duration(days: 90));
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [_name, _link, _location]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty) ? 'validation.required'.tr() : null;

  Future<void> _pick(bool start) async {
    final picked = await pickDate(context, initial: start ? _start : _end);
    if (picked == null) return;
    setState(() => start ? _start = picked : _end = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_end.isAfter(_start)) {
      showAppSnackBar(context, 'admin.group_form.dates_invalid'.tr(), isError: true);
      return;
    }
    setState(() => _saving = true);
    final base =
        widget.group ?? AcademyGroup(id: '', name: '', meetingLink: '', location: '', startDate: _start, endDate: _end);
    final result = await ref
        .read(academyRepositoryProvider)
        .saveGroup(
          base.copyWith(
            name: _name.text.trim(),
            courseId: _courseId,
            meetingLink: _link.text.trim(),
            location: _location.text.trim(),
            startDate: _start,
            endDate: _end,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        Navigator.of(context).pop();
        showAppSnackBar(context, 'admin.group_form.saved'.tr());
      case Err(:final failure):
        showAppSnackBar(context, failure.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(coursesProvider).value ?? const [];

    return AlertDialog(
      title: Text((widget.group == null ? 'admin.group_form.new_title' : 'admin.group_form.edit_title').tr()),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'admin.group_form.name'.tr(),
                  hint: 'CS140',
                  controller: _name,
                  validator: _required,
                ),
                verticalSpace(14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('admin.group_form.course'.tr(), style: AppTextStyles.font14Bold),
                    verticalSpace(8),
                    DropdownButtonFormField<String>(
                      // A course that was deleted can't be picked again, so the field asks for a new one.
                      initialValue: courses.any((c) => c.id == _courseId) ? _courseId : null,
                      isExpanded: true,
                      items: [
                        for (final course in courses)
                          DropdownMenuItem(
                            value: course.id,
                            child: Text(course.name, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      validator: _required,
                      onChanged: (value) => setState(() => _courseId = value ?? ''),
                    ),
                    if (courses.isEmpty) ...[
                      verticalSpace(8),
                      Text('admin.group_form.no_courses'.tr(), style: AppTextStyles.font12Normal.secondary(context)),
                    ],
                  ],
                ),
                verticalSpace(14),
                AppTextField(
                  label: 'admin.group_form.meeting_link'.tr(),
                  hint: 'https://',
                  controller: _link,
                  keyboardType: TextInputType.url,
                  monospace: true,
                ),
                verticalSpace(14),
                AppTextField(label: 'admin.group_form.location'.tr(), controller: _location),
                verticalSpace(14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pick(true),
                        icon: const Icon(Icons.event_outlined, size: 18),
                        label: Text('${'admin.group_form.start'.tr()}: ${context.dayMonthYear(_start)}'),
                      ),
                    ),
                    horizontalSpace(10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pick(false),
                        icon: const Icon(Icons.event_outlined, size: 18),
                        label: Text('${'admin.group_form.end'.tr()}: ${context.dayMonthYear(_end)}'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('common.cancel'.tr())),
        PrimaryButton(label: 'common.save'.tr(), isLoading: _saving, expand: false, height: 44, onPressed: _save),
      ],
    );
  }
}
