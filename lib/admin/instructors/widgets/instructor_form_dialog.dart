import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/instructors/widgets/instructor_validators.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_text_field.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:cairo_coding_app/data/models/instructor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InstructorFormDialog extends ConsumerStatefulWidget {
  const InstructorFormDialog({super.key, required this.instructor});

  final Instructor instructor;

  static Future<void> show(BuildContext context, Instructor instructor) {
    return showDialog<void>(
      context: context,
      builder: (_) => InstructorFormDialog(instructor: instructor),
    );
  }

  @override
  ConsumerState<InstructorFormDialog> createState() => _InstructorFormDialogState();
}

class _InstructorFormDialogState extends ConsumerState<InstructorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.instructor.name);
  late final _email = TextEditingController(text: widget.instructor.email);
  late final Set<String> _courseIds = {
    for (final course in ref.read(coursesProvider).value ?? const <Course>[])
      if (course.instructorIds.contains(widget.instructor.id)) course.id,
  };

  // Archived groups aren't listed below, but they stay on the instructor when saving.
  late final Set<String> _groupIds = {...widget.instructor.groupIds};
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final result = await ref
        .read(academyRepositoryProvider)
        .updateInstructor(
          widget.instructor,
          widget.instructor.copyWith(name: _name.text, email: _email.text, groupIds: _groupIds.toList()),
          courses: ref.read(coursesProvider).value ?? const [],
          courseIds: _courseIds,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        Navigator.of(context).pop();
        showAppSnackBar(context, 'admin.instructors.saved'.tr());
      case Err(:final failure):
        showAppSnackBar(context, failure.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final others = (ref.watch(instructorsProvider).value ?? const <Instructor>[]).where(
      (i) => i.id != widget.instructor.id,
    );
    final courses = ref.watch(coursesProvider).value ?? const <Course>[];
    final courseNames = {for (final course in courses) course.id: course.name};
    final groups = (ref.watch(adminGroupsProvider).value ?? const <AcademyGroup>[]).where((g) => !g.archived);

    return AlertDialog(
      title: Text('admin.instructors.edit_title'.tr()),
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
                  label: 'admin.instructors.name'.tr(),
                  hint: 'admin.instructors.name_hint'.tr(),
                  controller: _name,
                  validator: (value) => validateInstructorName(value, others),
                ),
                ListenableBuilder(
                  listenable: _name,
                  builder: (context, _) => _name.text.trim() == widget.instructor.name
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsetsDirectional.only(top: 6),
                          child: Text(
                            'admin.instructors.rename_note'.tr(),
                            style: AppTextStyles.font12Normal.secondary(context),
                          ),
                        ),
                ),
                verticalSpace(14),
                AppTextField(
                  label: 'admin.instructors.email'.tr(),
                  hint: 'admin.instructors.email_hint'.tr(),
                  controller: _email,
                  validator: (value) => validateInstructorEmail(value, others),
                  keyboardType: TextInputType.emailAddress,
                ),
                verticalSpace(18),
                Text('admin.instructors.courses_label'.tr(), style: AppTextStyles.font14Bold),
                verticalSpace(8),
                if (courses.isEmpty)
                  Text('admin.group_form.no_courses'.tr(), style: AppTextStyles.font12Normal.secondary(context))
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final course in courses)
                        ChoiceChip(
                          label: Text(context.bidi(course.name)),
                          selected: _courseIds.contains(course.id),
                          onSelected: (selected) =>
                              setState(() => selected ? _courseIds.add(course.id) : _courseIds.remove(course.id)),
                        ),
                    ],
                  ),
                verticalSpace(18),
                Text('admin.instructors.groups_label'.tr(), style: AppTextStyles.font14Bold),
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
