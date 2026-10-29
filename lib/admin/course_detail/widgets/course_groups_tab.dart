import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/groups/widgets/group_card.dart';
import 'package:cairo_coding_app/admin/groups/widgets/group_form_dialog.dart';
import 'package:cairo_coding_app/admin/widgets/card_grid.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CourseGroupsTab extends ConsumerWidget {
  const CourseGroupsTab({super.key, required this.course});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(courseGroupsProvider(course.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('admin.courses.groups'.tr(), style: AppTextStyles.font18ExtraBold)),
            OutlinedButton.icon(
              onPressed: () => GroupFormDialog.show(context, courseId: course.id),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('admin.groups.new'.tr()),
            ),
          ],
        ),
        verticalSpace(12),
        switch (groups) {
          AsyncError(:final error) => ErrorView(message: error.toString()),
          AsyncData(:final value) when value.isEmpty => EmptyView(
            message: 'admin.course.groups_empty'.tr(),
            icon: Icons.groups_outlined,
          ),
          AsyncData(:final value) => CardGrid(children: [for (final group in value) GroupCard(group: group)]),
          _ => const SkeletonList(count: 2, itemHeight: 120),
        },
      ],
    );
  }
}
