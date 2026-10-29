import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/instructors/widgets/add_instructor_panel.dart';
import 'package:cairo_coding_app/admin/instructors/widgets/instructor_form_dialog.dart';
import 'package:cairo_coding_app/admin/widgets/admin_page.dart';
import 'package:cairo_coding_app/admin/widgets/two_pane.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_data_table.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:cairo_coding_app/data/models/instructor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class InstructorsScreen extends ConsumerWidget {
  const InstructorsScreen({super.key});

  Future<void> _remove(BuildContext context, WidgetRef ref, Instructor instructor) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.instructors.remove_title'.tr(args: [instructor.name]),
      message: 'admin.instructors.remove_message'.tr(),
      confirmLabel: 'common.delete'.tr(),
      cancelLabel: 'common.cancel'.tr(),
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final result = await ref.read(academyRepositoryProvider).deleteInstructor(instructor);
    if (!context.mounted) return;
    if (result case Err(:final failure)) showAppSnackBar(context, failure.message, isError: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instructors = ref.watch(instructorsProvider);
    final courses = ref.watch(coursesProvider).value ?? const <Course>[];
    final activeGroups = {
      for (final group in ref.watch(adminGroupsProvider).value ?? const <AcademyGroup>[])
        if (!group.archived) group.id: group,
    };
    final colorScheme = Theme.of(context).colorScheme;

    final table = switch (instructors) {
      AsyncError(:final error) => ErrorView(message: error.toString()),
      AsyncData(:final value) when value.isEmpty => EmptyView(
        message: 'admin.instructors.empty'.tr(),
        icon: Icons.person_add_alt_outlined,
      ),
      AsyncData(:final value) => AppDataTable(
        minWidth: 600,
        columns: [
          AppTableColumn('admin.instructors.name'.tr(), flex: 4),
          AppTableColumn('admin.courses.title'.tr(), flex: 3),
          AppTableColumn('admin.instructors.groups'.tr(), flex: 4),
          AppTableColumn('admin.students.actions'.tr(), flex: 2, alignEnd: true),
        ],
        rows: [
          for (final instructor in value)
            () {
              final teaches = courses.where((c) => c.instructorIds.contains(instructor.id)).toList();
              final groups = [for (final id in instructor.groupIds) ?activeGroups[id]];
              return [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(instructor.name, style: AppTextStyles.font14Bold),
                    Text(
                      instructor.email.isEmpty ? 'admin.instructors.no_email'.tr() : instructor.email,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.font12Normal.secondary(context),
                    ),
                  ],
                ),
                teaches.isEmpty
                    ? Text('admin.instructors.no_courses'.tr(), style: AppTextStyles.font12Normal.secondary(context))
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final course in teaches)
                            ActionChip(
                              label: Text(context.bidi(course.name)),
                              onPressed: () => context.go(AdminRoutes.course(course.id, CourseTab.instructors)),
                            ),
                        ],
                      ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'admin.instructors.groups_count'.plural(groups.length),
                      style: groups.isEmpty
                          ? AppTextStyles.font12Normal.secondary(context)
                          : AppTextStyles.font12SemiBold.secondary(context),
                    ),
                    if (groups.isNotEmpty) ...[
                      verticalSpace(6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final group in groups)
                            ActionChip(
                              label: Text(context.bidi(group.name)),
                              onPressed: () => context.go(AdminRoutes.group(group.id)),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'admin.instructors.edit'.tr(),
                      onPressed: () => InstructorFormDialog.show(context, instructor),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                    IconButton(
                      tooltip: 'admin.instructors.remove'.tr(),
                      style: IconButton.styleFrom(foregroundColor: colorScheme.error),
                      onPressed: () => _remove(context, ref, instructor),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    ),
                  ],
                ),
              ];
            }(),
        ],
      ),
      _ => const SkeletonList(count: 3, itemHeight: 52),
    };

    return AdminPage(
      eyebrow: 'admin.instructors.eyebrow'.tr(),
      title: 'admin.instructors.title'.tr(),
      children: [TwoPane(main: table, side: const AddInstructorPanel())],
    );
  }
}
