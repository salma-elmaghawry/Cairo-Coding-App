import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/widgets/two_pane.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/app_data_table.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CourseInstructorsTab extends ConsumerWidget {
  const CourseInstructorsTab({super.key, required this.course});

  final Course course;

  Future<void> _remove(BuildContext context, WidgetRef ref, String instructorId) async {
    final result = await ref
        .read(academyRepositoryProvider)
        .setCourseInstructors(course, course.instructorIds.where((id) => id != instructorId).toList());
    if (!context.mounted) return;
    if (result case Err(:final failure)) showAppSnackBar(context, failure.message, isError: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instructors = ref.watch(courseInstructorsProvider(course.id));
    final colorScheme = Theme.of(context).colorScheme;

    final table = instructors.isEmpty
        ? EmptyView(message: 'admin.course.instructors_empty'.tr(), icon: Icons.person_outline_rounded)
        : AppDataTable(
            minWidth: 360,
            columns: [
              AppTableColumn('admin.instructors.name'.tr(), flex: 4),
              AppTableColumn('admin.students.actions'.tr(), alignEnd: true),
            ],
            rows: [
              for (final instructor in instructors)
                [
                  Text(instructor.name, style: AppTextStyles.font14Bold),
                  IconButton(
                    tooltip: 'admin.course.remove_instructor'.tr(),
                    style: IconButton.styleFrom(foregroundColor: colorScheme.error),
                    onPressed: () => _remove(context, ref, instructor.id),
                    icon: const Icon(Icons.person_remove_outlined, size: 18),
                  ),
                ],
            ],
          );

    return TwoPane(
      main: table,
      side: _AddCourseInstructorPanel(course: course),
    );
  }
}

class _AddCourseInstructorPanel extends ConsumerStatefulWidget {
  const _AddCourseInstructorPanel({required this.course});

  final Course course;

  @override
  ConsumerState<_AddCourseInstructorPanel> createState() => _AddCourseInstructorPanelState();
}

class _AddCourseInstructorPanelState extends ConsumerState<_AddCourseInstructorPanel> {
  String? _selected;
  bool _saving = false;

  Future<void> _add() async {
    final selected = _selected;
    if (selected == null) return;
    setState(() => _saving = true);
    final result = await ref.read(academyRepositoryProvider).setCourseInstructors(widget.course, [
      ...widget.course.instructorIds,
      selected,
    ]);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _selected = null;
    });
    if (result case Err(:final failure)) showAppSnackBar(context, failure.message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final all = ref.watch(instructorsProvider).value ?? const [];
    final available = all.where((i) => !widget.course.instructorIds.contains(i.id)).toList();

    return AppCard(
      color: colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('admin.course.add_instructor_title'.tr(), style: AppTextStyles.font18ExtraBold),
          Text('admin.course.add_instructor_hint'.tr(), style: AppTextStyles.font12Normal.secondary(context)),
          verticalSpace(14),
          if (available.isEmpty)
            Text(
              (all.isEmpty ? 'admin.course.no_instructors' : 'admin.course.all_assigned').tr(),
              style: AppTextStyles.font14Normal.secondary(context),
            )
          else ...[
            DropdownButtonFormField<String>(
              key: ValueKey(available.length),
              initialValue: _selected,
              isExpanded: true,
              hint: Text('admin.schedule.instructor'.tr()),
              items: [
                for (final instructor in available)
                  DropdownMenuItem(
                    value: instructor.id,
                    child: Text(instructor.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (value) => setState(() => _selected = value),
            ),
            verticalSpace(12),
            PrimaryButton(
              label: 'admin.course.add_instructor'.tr(),
              height: 48,
              isLoading: _saving,
              onPressed: _selected == null ? null : _add,
            ),
          ],
          verticalSpace(8),
          TextButton(
            onPressed: () => context.go(AdminRoutes.instructors),
            child: Text('admin.course.manage_instructors'.tr()),
          ),
        ],
      ),
    );
  }
}
