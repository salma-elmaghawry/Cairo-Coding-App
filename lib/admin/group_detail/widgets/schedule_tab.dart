import 'package:cairo_coding_app/admin/group_detail/widgets/course_timeline.dart';
import 'package:cairo_coding_app/admin/group_detail/widgets/sessions_table.dart';
import 'package:cairo_coding_app/admin/group_detail/widgets/weekly_slots_panel.dart';
import 'package:cairo_coding_app/admin/insights/group_insights.dart';
import 'package:cairo_coding_app/admin/widgets/two_pane.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScheduleTab extends ConsumerWidget {
  const ScheduleTab({super.key, required this.group});

  final AcademyGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(groupInsightsProvider(group.id));

    return TwoPane(
      sideFirst: true,
      side: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WeeklySlotsPanel(key: ValueKey(group.weeklySlots), group: group),
          if (insights != null && insights.sessions.isNotEmpty) ...[
            const SizedBox(height: 16),
            CourseTimeline(insights: insights),
          ],
        ],
      ),
      main: SessionsTable(group: group),
    );
  }
}
