import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/group_detail/widgets/add_students_panel.dart';
import 'package:cairo_coding_app/admin/widgets/two_pane.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_data_table.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentsTab extends ConsumerWidget {
  const StudentsTab({super.key, required this.group});

  final AcademyGroup group;

  Future<void> _remove(BuildContext context, WidgetRef ref, Student student) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.students.remove_title'.tr(),
      message: 'admin.students.remove_message'.tr(args: [student.name, group.name]),
      confirmLabel: 'admin.students.remove'.tr(),
      cancelLabel: 'common.cancel'.tr(),
      destructive: true,
    );
    if (!confirmed) return;
    final result = await ref.read(academyRepositoryProvider).removeStudentFromGroup(student.uid, group.id);
    if (!context.mounted) return;
    if (result case Err(:final failure)) showAppSnackBar(context, failure.message, isError: true);
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref, Student student) async {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(groupStudentsProvider(group.id));
    final colorScheme = Theme.of(context).colorScheme;

    final table = switch (students) {
      AsyncError(:final error) => ErrorView(message: error.toString()),
      AsyncData(:final value) when value.isEmpty => EmptyView(
        message: 'admin.students.empty'.tr(),
        icon: Icons.person_add_alt_outlined,
      ),
      AsyncData(:final value) => AppDataTable(
        columns: [
          AppTableColumn('admin.students.name'.tr(), flex: 3),
          AppTableColumn('admin.students.email'.tr(), flex: 4),
          AppTableColumn('admin.students.phone'.tr(), flex: 3),
          AppTableColumn('admin.students.status'.tr(), flex: 2),
          AppTableColumn('admin.students.actions'.tr(), flex: 2, alignEnd: true),
        ],
        rows: [
          for (final student in value)
            [
              Text(student.name, style: AppTextStyles.font14Bold),
              Text(student.email, style: AppTextStyles.font14Normal.secondary(context)),
              Text(student.phone, style: AppTextStyles.monoFont12Medium.secondary(context)),
              StatusChip(
                label: (student.active ? 'admin.students.active' : 'admin.students.inactive').tr(),
                tone: student.active ? StatusTone.accent : StatusTone.danger,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'admin.students.remove'.tr(),
                    onPressed: () => _remove(context, ref, student),
                    icon: const Icon(Icons.person_remove_outlined, size: 18),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: (student.active ? 'admin.students.deactivate' : 'admin.students.activate').tr(),
                    style: IconButton.styleFrom(
                      foregroundColor: student.active ? colorScheme.error : colorScheme.primary,
                    ),
                    onPressed: () => _toggleActive(context, ref, student),
                    icon: Icon(student.active ? Icons.block_rounded : Icons.check_circle_outline_rounded, size: 18),
                  ),
                ],
              ),
            ],
        ],
      ),
      _ => const SkeletonList(count: 5, itemHeight: 52),
    };

    return TwoPane(
      main: table,
      side: AddStudentsPanel(group: group),
    );
  }
}
