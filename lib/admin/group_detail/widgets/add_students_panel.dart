import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/app_validators.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/app_text_field.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _AddMode { one, bulk }

class AddStudentsPanel extends ConsumerStatefulWidget {
  const AddStudentsPanel({super.key, required this.group});

  final AcademyGroup group;

  @override
  ConsumerState<AddStudentsPanel> createState() => _AddStudentsPanelState();
}

class _AddStudentsPanelState extends ConsumerState<AddStudentsPanel> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _bulk = TextEditingController();
  _AddMode _mode = _AddMode.one;
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [_name, _email, _phone, _bulk]) {
      controller.dispose();
    }
    super.dispose();
  }

  List<String> get _bulkEmails => _bulk.text
      .split(RegExp(r'[\s,;]+'))
      .map((e) => e.trim().toLowerCase())
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList();

  String? _validateBulk(String? _) {
    final emails = _bulkEmails;
    if (emails.isEmpty) return 'admin.students.bulk_empty'.tr();
    final invalid = emails.where((e) => !AppValidators.isValidEmail(e)).toList();
    return invalid.isEmpty ? null : 'admin.students.bulk_invalid'.tr(args: [invalid.join(', ')]);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final students = _mode == _AddMode.one
        ? [NewStudent(email: _email.text.trim(), name: _name.text.trim(), phone: _phone.text.trim())]
        : _bulkEmails.map((email) => NewStudent(email: email)).toList();
    setState(() => _saving = true);
    final result = await ref.read(academyRepositoryProvider).addStudents(widget.group.id, students);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok(:final value):
        for (final controller in [_name, _email, _phone, _bulk]) {
          controller.clear();
        }
        final summary = 'admin.students.added'.tr(args: ['${value.created}', '${value.linked}']);
        final skipped = value.skipped.isEmpty
            ? ''
            : '\n${'admin.students.skipped'.tr(args: [value.skipped.join(', ')])}';
        showAppSnackBar(context, '$summary$skipped', isError: value.skipped.isNotEmpty);
      case Err(:final failure):
        showAppSnackBar(context, failure.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<_AddMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: _AddMode.one, label: Text('admin.students.mode_one'.tr())),
                ButtonSegment(value: _AddMode.bulk, label: Text('admin.students.mode_bulk'.tr())),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) => setState(() => _mode = selection.first),
            ),
            verticalSpace(16),
            Text('admin.students.add_title'.tr(args: [widget.group.name]), style: AppTextStyles.font18ExtraBold),
            verticalSpace(14),
            if (_mode == _AddMode.one) ...[
              AppTextField(label: 'admin.students.name'.tr(), controller: _name, validator: AppValidators.validateName),
              verticalSpace(12),
              AppTextField(
                label: 'admin.students.email'.tr(),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: AppValidators.validateEmail,
              ),
              verticalSpace(12),
              AppTextField(label: 'admin.students.phone'.tr(), controller: _phone, keyboardType: TextInputType.phone),
            ] else
              AppTextField(
                label: 'admin.students.bulk_label'.tr(),
                hint: 'student1@example.com\nstudent2@example.com',
                controller: _bulk,
                maxLines: 7,
                monospace: true,
                validator: _validateBulk,
              ),
            verticalSpace(12),
            Text('admin.students.add_hint'.tr(), style: AppTextStyles.font12Normal.secondary(context)),
            verticalSpace(16),
            PrimaryButton(
              label: (_mode == _AddMode.one ? 'admin.students.add_one' : 'admin.students.add_all').tr(),
              isLoading: _saving,
              height: 48,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
