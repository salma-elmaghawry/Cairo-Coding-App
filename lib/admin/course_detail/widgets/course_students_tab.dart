import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_data_table.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Everyone in the course's groups. Adding and removing students stays on each group's page.
class CourseStudentsTab extends ConsumerWidget {
  const CourseStudentsTab({super.key, required this.course});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(courseStudentsProvider(course.id));
    final groupNames = {
      for (final group in ref.watch(courseGroupsProvider(course.id)).value ?? const []) group.id: group.name,
    };

    return switch (students) {
      AsyncError(:final error) => ErrorView(message: error.toString()),
      AsyncData(:final value) when value.isEmpty => EmptyView(
        message: 'admin.course.students_empty'.tr(),
        icon: Icons.school_outlined,
      ),
      AsyncData(:final value) => AppDataTable(
        columns: [
          AppTableColumn('admin.students.name'.tr(), flex: 3),
          AppTableColumn('admin.students.email'.tr(), flex: 4),
          AppTableColumn('admin.students.phone'.tr(), flex: 3),
          AppTableColumn('admin.courses.groups'.tr(), flex: 2),
          AppTableColumn('admin.students.status'.tr(), flex: 2),
        ],
        rows: [
          for (final student in value)
            [
              Text(student.name, style: AppTextStyles.font14Bold),
              Text(student.email, style: AppTextStyles.font14Normal.secondary(context)),
              Text(student.phone, style: AppTextStyles.monoFont12Medium.secondary(context)),
              Text(
                [for (final id in student.groupIds) ?groupNames[id]].join(' · '),
                style: AppTextStyles.monoFont12Medium,
              ),
              StatusChip(
                label: (student.active ? 'admin.students.active' : 'admin.students.inactive').tr(),
                tone: student.active ? StatusTone.accent : StatusTone.danger,
              ),
            ],
        ],
      ),
      _ => const SkeletonList(count: 5, itemHeight: 52),
    };
  }
}
