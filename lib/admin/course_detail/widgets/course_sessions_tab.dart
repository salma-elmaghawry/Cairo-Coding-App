import 'package:cairo_coding_app/admin/courses/widgets/course_form_dialog.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_data_table.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class CourseSessionsTab extends StatelessWidget {
  const CourseSessionsTab({super.key, required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('admin.courses.sessions'.tr(), style: AppTextStyles.font18ExtraBold)),
            OutlinedButton.icon(
              onPressed: () => CourseFormDialog.show(context, course: course),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text('admin.course.edit_sessions'.tr()),
            ),
          ],
        ),
        verticalSpace(4),
        Text('admin.course_form.sessions_hint'.tr(), style: AppTextStyles.font12Normal.secondary(context)),
        verticalSpace(12),
        if (course.sessionTitles.isEmpty)
          EmptyView(message: 'admin.course.sessions_empty'.tr(), icon: Icons.format_list_numbered_rounded)
        else
          AppDataTable(
            minWidth: 420,
            columns: [const AppTableColumn('#'), AppTableColumn('admin.schedule.topic'.tr(), flex: 8)],
            rows: [
              for (final (index, title) in course.sessionTitles.indexed)
                [
                  Text(
                    '${index + 1}'.padLeft(2, '0'),
                    style: AppTextStyles.monoFont14Bold.copyWith(color: colorScheme.primary),
                  ),
                  Text(context.bidi(title), style: AppTextStyles.font14SemiBold),
                ],
            ],
          ),
      ],
    );
  }
}
