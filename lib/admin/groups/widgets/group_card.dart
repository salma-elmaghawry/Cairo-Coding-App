import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/groups/widgets/group_form_dialog.dart';
import 'package:cairo_coding_app/admin/insights/group_insights.dart';
import 'package:cairo_coding_app/admin/widgets/slot_labels.dart';
import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/initials_avatar.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/services/attendance.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _GroupAction { edit, archive }

/// The short label on a group's tile: its course's name, cut to fit.
String groupTileLabel(String? courseName, String groupName) {
  final source = (courseName == null || courseName.isEmpty) ? groupName : courseName;
  if (source.length <= 4) return source;
  final words = source.split(RegExp(r'\s+')).where((word) => word.length > 3).toList();
  if (words.length > 1) return words.take(3).map((word) => word[0].toUpperCase()).join();
  return source.substring(0, 3);
}

class GroupCard extends ConsumerWidget {
  const GroupCard({super.key, required this.group});

  final AcademyGroup group;

  Future<void> _onAction(BuildContext context, WidgetRef ref, _GroupAction action) async {
    switch (action) {
      case _GroupAction.edit:
        await GroupFormDialog.show(context, group: group);
      case _GroupAction.archive:
        final result = await ref.read(academyRepositoryProvider).setArchived(group, !group.archived);
        if (!context.mounted) return;
        if (result case Err(:final failure)) showAppSnackBar(context, failure.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final insights = ref.watch(groupInsightsProvider(group.id));
    final course = ref.watch(courseProvider(group.courseId)).value;
    final (status, tone) = group.archived
        ? ('admin.groups.status_archived'.tr(), StatusTone.neutral)
        : (insights?.endingSoon ?? false)
        ? ('admin.groups.status_ending'.tr(), StatusTone.accent)
        : ('admin.groups.status_active'.tr(), StatusTone.success);
    final progress = insights == null || insights.total == 0 ? 0.0 : insights.done / insights.total;

    return AnimatedTap(
      onTap: () => context.go(AdminRoutes.group(group.id)),
      scaleDown: .99,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: .3)),
                  ),
                  child: Text(groupTileLabel(course?.name, group.name), style: AppTextStyles.monoFont14Bold),
                ),
                horizontalSpace(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name, style: AppTextStyles.font18ExtraBold),
                      Text(
                        course == null ? 'admin.groups.no_course'.tr() : context.bidi(course.name),
                        style: AppTextStyles.font13Normal.secondary(context),
                      ),
                    ],
                  ),
                ),
                StatusChip(label: status, tone: tone),
                PopupMenuButton<_GroupAction>(
                  tooltip: 'admin.groups.actions'.tr(),
                  icon: const Icon(Icons.more_vert_rounded, size: 18),
                  style: IconButton.styleFrom(side: BorderSide.none),
                  onSelected: (action) => _onAction(context, ref, action),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: _GroupAction.edit, child: Text('admin.groups.edit'.tr())),
                    PopupMenuItem(
                      value: _GroupAction.archive,
                      child: Text((group.archived ? 'admin.groups.unarchive' : 'admin.groups.archive').tr()),
                    ),
                  ],
                ),
              ],
            ),
            verticalSpace(16),
            Row(
              children: [
                Expanded(
                  child: Text('admin.groups.progress'.tr(), style: AppTextStyles.font12SemiBold.secondary(context)),
                ),
                Text(
                  insights == null ? '–' : '${insights.done} / ${insights.total}',
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.monoFont12Bold,
                ),
              ],
            ),
            verticalSpace(8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: colorScheme.primary.withValues(alpha: .14),
              ),
            ),
            verticalSpace(16),
            Wrap(
              runSpacing: 12,
              children: [
                _Fact(label: 'admin.groups.weekly'.tr(), value: context.slotsCompact(group.weeklySlots)),
                _Fact(
                  label: 'admin.groups.next_session'.tr(),
                  value: insights?.next == null ? '—' : context.shortDay(insights!.next!.startsAt),
                ),
                _Fact(
                  label: 'admin.groups.attendance'.tr(),
                  value: insights?.attendance == null ? '—' : '${percent(insights!.attendance!)}%',
                ),
                _Fact(label: 'admin.groups.runs'.tr(), value: context.monthRange(group.startDate, group.endDate)),
              ],
            ),
            verticalSpace(16),
            Divider(color: colorScheme.primary.withValues(alpha: .14)),
            verticalSpace(12),
            Row(
              children: [
                AvatarStack(
                  names: [for (final student in insights?.members ?? const []) student.name],
                  ring: colorScheme.surfaceContainer,
                ),
                horizontalSpace(10),
                Expanded(
                  child: Text(
                    'admin.overview.students'.tr(args: ['${insights?.members.length ?? '…'}']),
                    style: AppTextStyles.font13Normal.secondary(context),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.go(AdminRoutes.group(group.id)),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text('admin.groups.open'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: .5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.font12Normal.secondary(context)),
          verticalSpace(2),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.font14ExtraBold),
        ],
      ),
    );
  }
}
