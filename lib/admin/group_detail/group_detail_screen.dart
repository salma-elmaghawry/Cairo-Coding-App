import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/group_detail/widgets/group_header.dart';
import 'package:cairo_coding_app/admin/group_detail/widgets/recordings_tab.dart';
import 'package:cairo_coding_app/admin/group_detail/widgets/schedule_tab.dart';
import 'package:cairo_coding_app/admin/group_detail/widgets/students_tab.dart';
import 'package:cairo_coding_app/admin/widgets/admin_page.dart';
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

    return switch (group) {
      AsyncError(:final error) => ErrorView(message: error.toString()),
      AsyncData(value: null) => const NotFoundScreen(),
      AsyncData(:final value?) => AdminPage(
        header: GroupHeader(group: value),
        children: [
          DefaultTabController(
            key: ValueKey(tab),
            length: GroupTab.values.length,
            initialIndex: tab.index,
            child: TabBar(
              isScrollable: true,
              onTap: (index) => context.go(AdminRoutes.group(groupId, GroupTab.values[index])),
              tabs: [
                Tab(text: 'admin.group.tab_students'.tr()),
                Tab(text: 'admin.group.tab_schedule'.tr()),
                Tab(text: 'admin.group.tab_recordings'.tr()),
              ],
            ),
          ),
          verticalSpace(20),
          switch (tab) {
            GroupTab.students => StudentsTab(group: value),
            GroupTab.schedule => ScheduleTab(group: value),
            GroupTab.recordings => RecordingsTab(group: value),
          },
        ],
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
