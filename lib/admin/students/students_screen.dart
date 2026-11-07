import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/group_detail/widgets/student_cells.dart';
import 'package:cairo_coding_app/admin/insights/group_insights.dart';
import 'package:cairo_coding_app/admin/students/widgets/add_students_dialog.dart';
import 'package:cairo_coding_app/admin/widgets/admin_page.dart';
import 'package:cairo_coding_app/admin/widgets/student_actions.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_data_table.dart';
import 'package:cairo_coding_app/core/widgets/filter_pill.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  // Starts from the current search, so a student picked in the top bar's search shows up filtered.
  late final _search = TextEditingController(text: ref.read(studentsViewProvider).query);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _lastSeen(BuildContext context, Student student, DateTime now) {
    final seen = student.lastSeenAt;
    if (seen == null) return 'admin.students_page.never'.tr();
    return context.relativeTime(seen, now);
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    final students = ref.watch(visibleStudentsProvider);
    final view = ref.watch(studentsViewProvider);
    final viewNotifier = ref.read(studentsViewProvider.notifier);
    final courses = ref.watch(coursesProvider).value ?? const <Course>[];
    final groups = {
      for (final group in ref.watch(adminGroupsProvider).value ?? const <AcademyGroup>[]) group.id: group,
    };

    final table = switch (students) {
      AsyncError(:final error) => ErrorView(message: error.toString()),
      AsyncData(:final value) when value.isEmpty => EmptyView(
        message: 'admin.students_page.empty'.tr(),
        icon: Icons.school_outlined,
      ),
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('admin.students_page.count'.plural(value.length), style: AppTextStyles.font14Normal.secondary(context)),
          verticalSpace(10),
          AppDataTable(
            minWidth: 900,
            columns: [
              AppTableColumn('admin.students.student'.tr(), flex: 5),
              AppTableColumn('admin.students.phone'.tr(), flex: 3),
              AppTableColumn('admin.courses.groups'.tr(), flex: 3),
              AppTableColumn('admin.students_page.last_seen'.tr(), flex: 2),
              AppTableColumn('admin.students.status'.tr(), flex: 2),
              AppTableColumn('admin.students.actions'.tr(), flex: 2, alignEnd: true),
            ],
            rows: [
              for (final student in value)
                [
                  StudentNameCell(student: student),
                  Text(
                    student.phone,
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.monoFont12Medium.secondary(context),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final group in [for (final id in student.groupIds) ?groups[id]])
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                          label: Text(group.name),
                          onPressed: () => context.go(AdminRoutes.group(group.id)),
                        ),
                      if (student.groupIds.isEmpty)
                        Text('admin.students_page.no_group'.tr(), style: AppTextStyles.font12Normal.secondary(context)),
                    ],
                  ),
                  Text(_lastSeen(context, student, now), style: AppTextStyles.font12Normal.secondary(context)),
                  StatusChip(
                    label: GroupInsights.standingOf(student).label,
                    tone: GroupInsights.standingOf(student).tone,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StudentEditButton(student: student),
                      StudentActiveButton(student: student),
                    ],
                  ),
                ],
            ],
          ),
        ],
      ),
      _ => const SkeletonList(count: 6, itemHeight: 52),
    };

    return AdminPage(
      eyebrow: 'admin.students_page.eyebrow'.tr(),
      title: 'admin.students_page.title'.tr(),
      actions: [
        SizedBox(
          width: 300,
          child: TextField(
            controller: _search,
            onChanged: viewNotifier.search,
            decoration: InputDecoration(
              hintText: 'admin.students_page.search'.tr(),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
            ),
          ),
        ),
        PrimaryButton(
          label: 'admin.students_page.add_title'.tr(),
          icon: Icons.person_add_alt_rounded,
          height: 46,
          expand: false,
          onPressed: () => AddStudentsDialog.show(context),
        ),
      ],
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterPill(
              label: 'admin.students_page.all_courses'.tr(),
              selected: view.courseId == null,
              onSelected: () => viewNotifier.filterCourse(null),
            ),
            for (final course in courses)
              FilterPill(
                label: context.bidi(course.name),
                selected: view.courseId == course.id,
                onSelected: () => viewNotifier.filterCourse(course.id),
              ),
          ],
        ),
        verticalSpace(20),
        table,
      ],
    );
  }
}
