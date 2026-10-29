import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_text_field.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CourseFormDialog extends ConsumerStatefulWidget {
  const CourseFormDialog({super.key, this.course});

  final Course? course;

  static Future<void> show(BuildContext context, {Course? course}) {
    return showDialog<void>(
      context: context,
      builder: (_) => CourseFormDialog(course: course),
    );
  }

  @override
  ConsumerState<CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends ConsumerState<CourseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.course?.name);
  late final _sessions = TextEditingController(text: widget.course?.sessionTitles.join('\n'));
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _sessions.dispose();
    super.dispose();
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty) ? 'validation.required'.tr() : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final base = widget.course ?? const Course(id: '', name: '');
    final result = await ref
        .read(academyRepositoryProvider)
        .saveCourse(base.copyWith(name: _name.text, sessionTitles: _sessions.text.split('\n')));
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        Navigator.of(context).pop();
        showAppSnackBar(context, 'admin.course_form.saved'.tr());
      case Err(:final failure):
        showAppSnackBar(context, failure.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text((widget.course == null ? 'admin.course_form.new_title' : 'admin.course_form.edit_title').tr()),
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
                  label: 'admin.course_form.name'.tr(),
                  hint: 'admin.course_form.name_hint'.tr(),
                  controller: _name,
                  validator: _required,
                ),
                verticalSpace(14),
                AppTextField(
                  label: 'admin.course_form.sessions'.tr(),
                  hint: 'Intro To Programming & Datatypes\nOperators In C++\nConditions In C++',
                  controller: _sessions,
                  maxLines: 12,
                ),
                verticalSpace(8),
                Text('admin.course_form.sessions_hint'.tr(), style: AppTextStyles.font12Normal.secondary(context)),
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
