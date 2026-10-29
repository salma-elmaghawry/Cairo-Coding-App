import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/courses/widgets/course_actions.dart';
import 'package:cairo_coding_app/admin/courses/widgets/course_form_dialog.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CourseHeader extends ConsumerWidget {
  const CourseHeader({super.key, required this.course});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final groupCount = ref.watch(courseGroupsProvider(course.id)).value?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextButton(onPressed: () => context.go(AdminRoutes.courses), child: Text('admin.nav.courses'.tr())),
            Text('/', style: AppTextStyles.font14Normal.secondary(context)),
            horizontalSpace(8),
            Text(context.bidi(course.name), style: AppTextStyles.font14Normal.secondary(context)),
          ],
        ),
        verticalSpace(8),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.bidi(course.name),
                  style: AppTextStyles.monoFont28Bold.copyWith(color: colorScheme.primary),
                ),
                verticalSpace(6),
                Text(
                  [
                    'admin.courses.sessions_count'.tr(args: ['${course.sessionTitles.length}']),
                    'admin.courses.groups_count'.tr(args: ['$groupCount']),
                  ].join(' · '),
                  style: AppTextStyles.font14Normal.secondary(context),
                ),
              ],
            ),
            Wrap(
              spacing: 10,
              children: [
                OutlinedButton(
                  onPressed: () => CourseFormDialog.show(context, course: course),
                  child: Text('admin.courses.edit'.tr()),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
                  onPressed: () => deleteCourse(context, ref, course),
                  child: Text('admin.courses.delete'.tr()),
                ),
              ],
            ),
          ],
        ),
        verticalSpace(20),
      ],
    );
  }
}
