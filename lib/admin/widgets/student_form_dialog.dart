import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/app_validators.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_text_field.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentFormDialog extends ConsumerStatefulWidget {
  const StudentFormDialog({super.key, required this.student});

  final Student student;

  static Future<void> show(BuildContext context, Student student) {
    return showDialog<void>(
      context: context,
      builder: (_) => StudentFormDialog(student: student),
    );
  }

  @override
  ConsumerState<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends ConsumerState<StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.student.name);
  late final _email = TextEditingController(text: widget.student.email);
  late final _phone = TextEditingController(text: widget.student.phone);

  // Archived groups aren't listed below, but they stay on the student when saving.
  late final Set<String> _groupIds = {...widget.student.groupIds};
  late bool _active = widget.student.active;
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [_name, _email, _phone]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final result = await ref
        .read(academyRepositoryProvider)
        .updateStudent(
          widget.student.copyWith(name: _name.text, phone: _phone.text, groupIds: _groupIds.toList(), active: _active),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        Navigator.of(context).pop();
        showAppSnackBar(context, 'admin.students.saved'.tr());
      case Err(:final failure):
        showAppSnackBar(context, failure.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseNames = {
      for (final course in ref.watch(coursesProvider).value ?? const <Course>[]) course.id: course.name,
    };
    final groups = (ref.watch(adminGroupsProvider).value ?? const <AcademyGroup>[]).where((g) => !g.archived);

    return AlertDialog(
      title: Text('admin.students.edit_title'.tr()),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'admin.students.name'.tr(),
                  controller: _name,
                  validator: AppValidators.validateName,
                ),
                verticalSpace(14),
                AppTextField(
                  label: 'admin.students.email'.tr(),
                  controller: _email,
                  readOnly: true,
                  prefixIcon: Icons.lock_outline_rounded,
                ),
                verticalSpace(6),
                Text('admin.students.email_locked'.tr(), style: AppTextStyles.font12Normal.secondary(context)),
                verticalSpace(14),
                AppTextField(label: 'admin.students.phone'.tr(), controller: _phone, keyboardType: TextInputType.phone),
                verticalSpace(18),
                Text('admin.students.groups_label'.tr(), style: AppTextStyles.font14Bold),
                verticalSpace(8),
                if (groups.isEmpty)
                  Text('admin.instructors.no_active_groups'.tr(), style: AppTextStyles.font12Normal.secondary(context))
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final group in groups)
                        ChoiceChip(
                          label: Text([group.name, ?courseNames[group.courseId]].map(context.bidi).join(' · ')),
                          selected: _groupIds.contains(group.id),
                          onSelected: (selected) =>
                              setState(() => selected ? _groupIds.add(group.id) : _groupIds.remove(group.id)),
                        ),
                    ],
                  ),
                verticalSpace(10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('admin.students.active_label'.tr(), style: AppTextStyles.font14Bold),
                  subtitle: Text(
                    'admin.students.active_hint'.tr(),
                    style: AppTextStyles.font12Normal.secondary(context),
                  ),
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
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
