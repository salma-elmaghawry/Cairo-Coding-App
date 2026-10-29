import 'package:cairo_coding_app/admin/widgets/student_form_dialog.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Deactivates [student]'s account after a confirmation, or activates it straight away.
Future<void> toggleStudentActive(BuildContext context, WidgetRef ref, Student student) async {
  if (student.active) {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.students.deactivate_title'.tr(),
      message: 'admin.students.deactivate_message'.tr(args: [student.name]),
      confirmLabel: 'admin.students.deactivate'.tr(),
      cancelLabel: 'common.cancel'.tr(),
      destructive: true,
    );
    if (!confirmed) return;
  }
  final result = await ref.read(academyRepositoryProvider).setStudentActive(student.uid, !student.active);
  if (!context.mounted) return;
  if (result case Err(:final failure)) showAppSnackBar(context, failure.message, isError: true);
}

class StudentEditButton extends StatelessWidget {
  const StudentEditButton({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'admin.students.edit'.tr(),
      onPressed: () => StudentFormDialog.show(context, student),
      icon: const Icon(Icons.edit_outlined, size: 18),
    );
  }
}

class StudentActiveButton extends ConsumerWidget {
  const StudentActiveButton({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: (student.active ? 'admin.students.deactivate' : 'admin.students.activate').tr(),
      style: IconButton.styleFrom(foregroundColor: student.active ? colorScheme.error : colorScheme.primary),
      onPressed: () => toggleStudentActive(context, ref, student),
      icon: Icon(student.active ? Icons.block_rounded : Icons.check_circle_outline_rounded, size: 18),
    );
  }
}
