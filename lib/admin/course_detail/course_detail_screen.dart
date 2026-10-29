import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/course_detail/widgets/course_groups_tab.dart';
import 'package:cairo_coding_app/admin/course_detail/widgets/course_header.dart';
import 'package:cairo_coding_app/admin/course_detail/widgets/course_instructors_tab.dart';
import 'package:cairo_coding_app/admin/course_detail/widgets/course_sessions_tab.dart';
import 'package:cairo_coding_app/admin/course_detail/widgets/course_students_tab.dart';
import 'package:cairo_coding_app/admin/widgets/admin_page.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/widgets/not_found_screen.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({super.key, required this.courseId, required this.tab});

  final String courseId;
  final CourseTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseProvider(courseId));

    return switch (course) {
      AsyncError(:final error) => ErrorView(message: error.toString()),
      AsyncData(value: null) => const NotFoundScreen(),
      AsyncData(:final value?) => AdminPage(
        header: CourseHeader(course: value),
        children: [
          DefaultTabController(
            key: ValueKey(tab),
            length: CourseTab.values.length,
            initialIndex: tab.index,
            child: TabBar(
              isScrollable: true,
              onTap: (index) => context.go(AdminRoutes.course(courseId, CourseTab.values[index])),
              tabs: [
                Tab(text: 'admin.course.tab_groups'.tr()),
                Tab(text: 'admin.course.tab_sessions'.tr()),
                Tab(text: 'admin.course.tab_instructors'.tr()),
                Tab(text: 'admin.course.tab_students'.tr()),
              ],
            ),
          ),
          verticalSpace(20),
          switch (tab) {
            CourseTab.groups => CourseGroupsTab(course: value),
            CourseTab.sessions => CourseSessionsTab(course: value),
            CourseTab.instructors => CourseInstructorsTab(course: value),
            CourseTab.students => CourseStudentsTab(course: value),
          },
        ],
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
