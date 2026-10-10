import 'package:cairo_coding_app/admin/group_detail/widgets/sessions_table.dart';
import 'package:cairo_coding_app/admin/group_detail/widgets/weekly_slots_panel.dart';
import 'package:cairo_coding_app/admin/widgets/two_pane.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:flutter/material.dart';

class ScheduleTab extends StatelessWidget {
  const ScheduleTab({super.key, required this.group});

  final AcademyGroup group;

  @override
  Widget build(BuildContext context) {
    return TwoPane(
      sideFirst: true,
      side: WeeklySlotsPanel(key: ValueKey(group.weeklySlots), group: group),
      main: SessionsTable(group: group),
    );
  }
}
