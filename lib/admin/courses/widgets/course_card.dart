import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/courses/widgets/course_actions.dart';
import 'package:cairo_coding_app/admin/courses/widgets/course_form_dialog.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _CourseAction { edit, delete }

class CourseCard extends ConsumerWidget {
  const CourseCard({super.key, required this.course});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final groupCount = ref.watch(courseGroupsProvider(course.id).select((value) => value.value?.length));
    final studentCount = ref.watch(courseStudentsProvider(course.id).select((value) => value.value?.length));
    final instructors = ref.watch(courseInstructorsProvider(course.id));

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  context.bidi(course.name),
                  style: AppTextStyles.monoFont20Bold.copyWith(color: colorScheme.primary),
                ),
              ),
              PopupMenuButton<_CourseAction>(
                tooltip: 'admin.courses.actions'.tr(),
                onSelected: (action) => switch (action) {
                  _CourseAction.edit => CourseFormDialog.show(context, course: course),
                  _CourseAction.delete => deleteCourse(context, ref, course),
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: _CourseAction.edit, child: Text('admin.courses.edit'.tr())),
                  PopupMenuItem(value: _CourseAction.delete, child: Text('admin.courses.delete'.tr())),
                ],
              ),
            ],
          ),
          Text(
            instructors.isEmpty ? 'admin.courses.no_instructors'.tr() : instructors.map((i) => i.name).join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.font14Normal.secondary(context),
          ),
          verticalSpace(16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _Stat(label: 'admin.courses.sessions'.tr(), value: '${course.sessionTitles.length}'),
              _Stat(label: 'admin.courses.groups'.tr(), value: groupCount?.toString() ?? '…'),
              _Stat(label: 'admin.courses.students'.tr(), value: studentCount?.toString() ?? '…'),
            ],
          ),
          verticalSpace(18),
          OutlinedButton.icon(
            onPressed: () => context.go(AdminRoutes.course(course.id)),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text('admin.courses.open'.tr()),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.font12Normal.secondary(context)),
        Text(value, style: AppTextStyles.monoFont16Bold),
      ],
    );
  }
}
