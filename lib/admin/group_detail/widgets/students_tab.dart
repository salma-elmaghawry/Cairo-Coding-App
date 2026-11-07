import 'package:cairo_coding_app/admin/group_detail/widgets/add_students_panel.dart';
import 'package:cairo_coding_app/admin/group_detail/widgets/student_cells.dart';
import 'package:cairo_coding_app/admin/insights/group_insights.dart';
import 'package:cairo_coding_app/admin/widgets/csv/csv_download.dart';
import 'package:cairo_coding_app/admin/widgets/table_pager.dart';
import 'package:cairo_coding_app/admin/widgets/two_pane.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_data_table.dart';
import 'package:cairo_coding_app/core/widgets/filter_pill.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:cairo_coding_app/data/services/attendance.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentsTab extends ConsumerStatefulWidget {
  const StudentsTab({super.key, required this.group});

  final AcademyGroup group;

  @override
  ConsumerState<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends ConsumerState<StudentsTab> {
  static const _pageSize = 10;

  StudentStanding? _standing;
  String _query = '';
  int _page = 0;

  Future<void> _remove(Student student) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.students.remove_title'.tr(),
      message: 'admin.students.remove_message'.tr(args: [student.name, widget.group.name]),
      confirmLabel: 'admin.students.remove'.tr(),
      cancelLabel: 'common.cancel'.tr(),
      destructive: true,
    );
    if (!confirmed) return;
    final result = await ref.read(academyRepositoryProvider).removeStudentFromGroup(student.uid, widget.group.id);
    if (!mounted) return;
    if (result case Err(:final failure)) showAppSnackBar(context, failure.message, isError: true);
  }

  void _download(GroupInsights insights) {
    String rate(double? value) => value == null ? '' : '${percent(value)}%';
    final ok = downloadCsv('${widget.group.name}-students.csv', [
      ['Name', 'Email', 'Phone', 'Attendance', 'Quiz average', 'Status'],
      for (final s in insights.students)
        [
          s.name,
          s.email,
          s.phone,
          rate(insights.attendanceOf(s.uid)),
          rate(insights.quizAverageOf(s.uid)),
          GroupInsights.standingOf(s).name,
        ],
    ]);
    if (!ok) showAppSnackBar(context, 'admin.export_failed'.tr(), isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final insights = ref.watch(groupInsightsProvider(widget.group.id));
    final side = AddStudentsPanel(group: widget.group);
    if (insights == null) return TwoPane(main: const SkeletonList(count: 5, itemHeight: 56), side: side);

    final all = insights.students;
    final counts = {
      for (final s in StudentStanding.values) s: all.where((x) => GroupInsights.standingOf(x) == s).length,
    };
    final query = _query.trim().toLowerCase();
    final filtered = all
        .where((s) => _standing == null || GroupInsights.standingOf(s) == _standing)
        .where(
          (s) => query.isEmpty || '${s.name} ${s.email} ${s.phone.replaceAll(' ', '')}'.toLowerCase().contains(query),
        )
        .toList();
    final pages = (filtered.length / _pageSize).ceil();
    final page = _page.clamp(0, pages == 0 ? 0 : pages - 1);
    final shown = filtered.skip(page * _pageSize).take(_pageSize).toList();

    void filter(StudentStanding? standing) => setState(() {
      _standing = standing;
      _page = 0;
    });

    final toolbar = Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            FilterPill(
              label: 'quizzes.all'.tr(),
              count: all.length,
              selected: _standing == null,
              onSelected: () => filter(null),
            ),
            for (final standing in StudentStanding.values)
              FilterPill(
                label: standing.label,
                count: counts[standing],
                selected: _standing == standing,
                onSelected: () => filter(standing),
              ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                onChanged: (value) => setState(() {
                  _query = value;
                  _page = 0;
                }),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'admin.students.search'.tr(),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'admin.students.download'.tr(),
              onPressed: () => _download(insights),
              icon: const Icon(Icons.download_rounded, size: 18),
            ),
          ],
        ),
      ],
    );

    final table = all.isEmpty
        ? EmptyView(message: 'admin.students.empty'.tr(), icon: Icons.person_add_alt_outlined)
        : AppDataTable(
            minWidth: 740,
            header: toolbar,
            footer: TablePager(
              page: page,
              pages: pages,
              shown: shown.length,
              total: filtered.length,
              pageSize: _pageSize,
              onPage: (value) => setState(() => _page = value),
            ),
            columns: [
              AppTableColumn('admin.students.student'.tr(), flex: 5),
              AppTableColumn('admin.students.phone'.tr(), flex: 3),
              AppTableColumn('admin.students.attendance'.tr(), flex: 3),
              AppTableColumn('admin.students.quiz_avg'.tr(), flex: 2),
              AppTableColumn('admin.students.status'.tr(), flex: 2),
              AppTableColumn('admin.students.actions'.tr(), flex: 4, alignEnd: true),
            ],
            rows: [
              for (final student in shown)
                [
                  StudentNameCell(student: student),
                  Text(
                    student.phone,
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.monoFont12Medium.secondary(context),
                  ),
                  AttendanceCell(rate: insights.attendanceOf(student.uid)),
                  Text(
                    insights.quizAverageOf(student.uid) == null
                        ? '—'
                        : '${percent(insights.quizAverageOf(student.uid)!)}%',
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.monoFont14Bold,
                  ),
                  StatusChip(
                    label: GroupInsights.standingOf(student).label,
                    tone: GroupInsights.standingOf(student).tone,
                  ),
                  StudentRowActions(student: student, onRemove: () => _remove(student)),
                ],
            ],
          );

    return TwoPane(main: table, side: side);
  }
}
