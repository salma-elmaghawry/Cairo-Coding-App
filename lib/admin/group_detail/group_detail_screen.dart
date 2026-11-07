import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/group_detail/widgets/group_header.dart';
import 'package:cairo_coding_app/admin/group_detail/widgets/group_quizzes_tab.dart';
import 'package:cairo_coding_app/admin/group_detail/widgets/recordings_tab.dart';
import 'package:cairo_coding_app/admin/group_detail/widgets/schedule_tab.dart';
import 'package:cairo_coding_app/admin/group_detail/widgets/students_tab.dart';
import 'package:cairo_coding_app/admin/insights/group_insights.dart';
import 'package:cairo_coding_app/admin/widgets/admin_page.dart';
import 'package:cairo_coding_app/admin/widgets/underline_tabs.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/widgets/not_found_screen.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.groupId, required this.tab});

  final String groupId;
  final GroupTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupProvider(groupId));
    final insights = ref.watch(groupInsightsProvider(groupId));

    return switch (group) {
      AsyncError(:final error) => ErrorView(message: error.toString()),
      AsyncData(value: null) => const NotFoundScreen(),
      AsyncData(:final value?) => AdminPage(
        header: GroupHeader(group: value),
        children: [
          UnderlineTabs(
            tabs: [
              UnderlineTab('admin.group.tab_students'.tr(), count: insights?.students.length),
              UnderlineTab('admin.group.tab_schedule'.tr(), count: insights?.sessions.length),
              UnderlineTab('admin.group.tab_recordings'.tr(), count: insights?.recordings.length),
              UnderlineTab('admin.group.tab_quizzes'.tr(), count: insights?.groupQuizzes.length),
            ],
            selected: tab.index,
            onSelect: (index) => context.go(AdminRoutes.group(groupId, GroupTab.values[index])),
          ),
          verticalSpace(20),
          switch (tab) {
            GroupTab.students => StudentsTab(group: value),
            GroupTab.schedule => ScheduleTab(group: value),
            GroupTab.recordings => RecordingsTab(group: value),
            GroupTab.quizzes => GroupQuizzesTab(group: value),
          },
        ],
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
