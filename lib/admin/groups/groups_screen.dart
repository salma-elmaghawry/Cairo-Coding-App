import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/groups/widgets/group_card.dart';
import 'package:cairo_coding_app/admin/groups/widgets/group_form_dialog.dart';
import 'package:cairo_coding_app/admin/groups/widgets/groups_summary.dart';
import 'package:cairo_coding_app/admin/insights/group_insights.dart';
import 'package:cairo_coding_app/admin/widgets/admin_page.dart';
import 'package:cairo_coding_app/admin/widgets/card_grid.dart';
import 'package:cairo_coding_app/admin/widgets/csv/csv_download.dart';
import 'package:cairo_coding_app/admin/widgets/underline_tabs.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:cairo_coding_app/data/services/attendance.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Sort { next, name, students }

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  _Sort _sort = _Sort.next;

  List<AcademyGroup> _sorted(List<AcademyGroup> groups) {
    GroupInsights? insights(AcademyGroup g) => ref.read(groupInsightsProvider(g.id));
    final far = DateTime(9999);
    return [...groups]..sort(
      (a, b) => switch (_sort) {
        _Sort.name => a.name.compareTo(b.name),
        _Sort.students => (insights(b)?.members.length ?? 0).compareTo(insights(a)?.members.length ?? 0),
        _Sort.next => (insights(a)?.next?.startsAt ?? far).compareTo(insights(b)?.next?.startsAt ?? far),
      },
    );
  }

  void _export(List<AcademyGroup> groups) {
    final courses = {for (final Course c in ref.read(coursesProvider).value ?? const []) c.id: c.name};
    final rows = <List<Object?>>[
      [
        'Group',
        'Course',
        'Students',
        'Sessions done',
        'Sessions total',
        'Attendance',
        'Quiz average',
        'Starts',
        'Ends',
      ],
      for (final group in groups)
        () {
          final insights = ref.read(groupInsightsProvider(group.id));
          return [
            group.name,
            courses[group.courseId] ?? '',
            insights?.members.length,
            insights?.done,
            insights?.total,
            insights?.attendance == null ? '' : '${percent(insights!.attendance!)}%',
            insights?.quizAverage == null ? '' : '${percent(insights!.quizAverage!)}%',
            context.dayMonthYear(group.startDate),
            context.dayMonthYear(group.endDate),
          ];
        }(),
    ];
    if (!downloadCsv('groups.csv', rows)) showAppSnackBar(context, 'admin.export_failed'.tr(), isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(visibleGroupsProvider);
    final view = ref.watch(groupsViewProvider);
    final counts = ref.watch(groupCountsProvider);
    final viewNotifier = ref.read(groupsViewProvider.notifier);
    // Sorting reads each group's numbers, so the page rebuilds as they arrive.
    for (final group in groups.value ?? const <AcademyGroup>[]) {
      ref.watch(groupInsightsProvider(group.id));
    }

    return AdminPage(
      eyebrow: 'admin.groups.eyebrow'.tr(),
      title: 'admin.groups.title'.tr(),
      subtitle: 'admin.groups.subtitle'.tr(),
      actions: [
        OutlinedButton.icon(
          onPressed: () => _export(groups.value ?? const []),
          icon: const Icon(Icons.download_rounded, size: 18),
          label: Text('admin.groups.export'.tr()),
        ),
        PrimaryButton(
          label: 'admin.groups.new'.tr(),
          icon: Icons.add_rounded,
          height: 44,
          expand: false,
          onPressed: () => GroupFormDialog.show(context),
        ),
      ],
      children: [
        const GroupsSummary(),
        verticalSpace(20),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            UnderlineTabs(
              tabs: [
                UnderlineTab('admin.groups.tab_active'.tr(), count: counts.active),
                UnderlineTab('admin.groups.tab_archived'.tr(), count: counts.archived),
              ],
              selected: view.archived ? 1 : 0,
              onSelect: (index) => viewNotifier.showArchived(index == 1),
            ),
            Wrap(
              spacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  child: TextField(
                    onChanged: viewNotifier.search,
                    decoration: InputDecoration(
                      hintText: 'admin.groups.search'.tr(),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                    ),
                  ),
                ),
                DropdownMenu<_Sort>(
                  width: 200,
                  initialSelection: _sort,
                  label: Text('admin.groups.sort'.tr()),
                  onSelected: (sort) => setState(() => _sort = sort ?? _sort),
                  dropdownMenuEntries: [
                    DropdownMenuEntry(value: _Sort.next, label: 'admin.groups.sort_next'.tr()),
                    DropdownMenuEntry(value: _Sort.name, label: 'admin.groups.sort_name'.tr()),
                    DropdownMenuEntry(value: _Sort.students, label: 'admin.groups.sort_students'.tr()),
                  ],
                ),
              ],
            ),
          ],
        ),
        verticalSpace(20),
        switch (groups) {
          AsyncError(:final error) => ErrorView(message: error.toString()),
          AsyncData(:final value) when value.isEmpty && view.archived => EmptyView(
            message: 'admin.groups.empty'.tr(),
            icon: Icons.groups_outlined,
          ),
          AsyncData(:final value) => CardGrid(
            minItemWidth: 340,
            children: [
              for (final group in _sorted(value)) GroupCard(group: group),
              if (!view.archived) const CreateGroupCard(),
            ],
          ),
          _ => const SkeletonList(count: 3, itemHeight: 120),
        },
      ],
    );
  }
}
