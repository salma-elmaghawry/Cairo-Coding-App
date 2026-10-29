import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Deletes [course] after a confirmation, unless a group (archived ones too) still belongs to it.
Future<void> deleteCourse(BuildContext context, WidgetRef ref, Course course) async {
  final groups = ref.read(adminGroupsProvider).value ?? const [];
  if (groups.any((g) => g.courseId == course.id)) {
    showAppSnackBar(context, 'admin.courses.delete_blocked'.tr(args: [course.name]), isError: true);
    return;
  }
  final confirmed = await showConfirmDialog(
    context,
    title: 'admin.courses.delete_title'.tr(args: [course.name]),
    message: 'admin.courses.delete_message'.tr(),
    confirmLabel: 'common.delete'.tr(),
    cancelLabel: 'common.cancel'.tr(),
    destructive: true,
  );
  if (!confirmed || !context.mounted) return;
  final result = await ref.read(academyRepositoryProvider).deleteCourse(course);
  if (!context.mounted) return;
  switch (result) {
    case Ok():
      showAppSnackBar(context, 'admin.courses.deleted'.tr());
      context.go(AdminRoutes.courses);
    case Err(:final failure):
      showAppSnackBar(context, failure.message, isError: true);
  }
}
