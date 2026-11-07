import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/groups/widgets/group_card.dart';
import 'package:cairo_coding_app/admin/groups/widgets/group_form_dialog.dart';
import 'package:cairo_coding_app/admin/insights/group_insights.dart';
import 'package:cairo_coding_app/admin/widgets/slot_labels.dart';
import 'package:cairo_coding_app/admin/widgets/stat_strip.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/services/attendance.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GroupHeader extends ConsumerWidget {
  const GroupHeader({super.key, required this.group});

  final AcademyGroup group;

  Future<void> _toggleArchive(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(academyRepositoryProvider).setArchived(group, !group.archived);
    if (!context.mounted) return;
    if (result case Err(:final failure)) showAppSnackBar(context, failure.message, isError: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final course = ref.watch(courseProvider(group.courseId)).value;
    final insights = ref.watch(groupInsightsProvider(group.id));
    final chevron = Icon(Icons.chevron_right_rounded, size: 16, color: colorScheme.onSurfaceVariant);
    final (status, tone) = group.archived
        ? ('admin.groups.status_archived'.tr(), StatusTone.neutral)
        : (insights?.endingSoon ?? false)
        ? ('admin.groups.status_ending'.tr(), StatusTone.accent)
        : ('admin.groups.status_active'.tr(), StatusTone.success);
    final meta = [
      context.slotsCompact(group.weeklySlots),
      context.monthRange(group.startDate, group.endDate),
      if (group.location.isNotEmpty) group.location,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (course == null)
              TextButton(onPressed: () => context.go(AdminRoutes.groups), child: Text('admin.nav.groups'.tr()))
            else ...[
              TextButton(onPressed: () => context.go(AdminRoutes.courses), child: Text('admin.nav.courses'.tr())),
              chevron,
              TextButton(
                onPressed: () => context.go(AdminRoutes.course(course.id)),
                child: Text(context.bidi(course.name)),
              ),
            ],
            chevron,
            horizontalSpace(8),
            Text(group.name, style: AppTextStyles.font13Normal.secondary(context)),
          ],
        ),
        verticalSpace(8),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: .4)),
                    gradient: RadialGradient(
                      center: AlignmentDirectional.topStart.resolve(Directionality.of(context)),
                      radius: 1.4,
                      colors: [colorScheme.primary.withValues(alpha: .45), colorScheme.primary.withValues(alpha: .12)],
                    ),
                  ),
                  child: Text(groupTileLabel(course?.name, group.name), style: AppTextStyles.monoFont18Bold),
                ),
                horizontalSpace(16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        Text(group.name, style: AppTextStyles.monoFont28Bold.copyWith(color: colorScheme.primary)),
                        Text(
                          course == null ? 'admin.groups.no_course'.tr() : context.bidi(course.name),
                          style: course == null
                              ? AppTextStyles.font24ExtraBold.secondary(context)
                              : AppTextStyles.font24ExtraBold,
                        ),
                      ],
                    ),
                    verticalSpace(4),
                    Wrap(
                      spacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(meta.join(' · '), style: AppTextStyles.font13Normal.secondary(context)),
                        StatusChip(label: status, tone: tone),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatStrip(
                  items: [
                    (insights == null ? '–' : '${insights.done}/${insights.total}', 'admin.group.stat_sessions'.tr()),
                    (
                      insights?.attendance == null ? '–' : '${percent(insights!.attendance!)}%',
                      'admin.group.stat_attendance'.tr(),
                    ),
                    (
                      insights?.quizAverage == null ? '–' : '${percent(insights!.quizAverage!)}%',
                      'admin.group.stat_quiz'.tr(),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => GroupFormDialog.show(context, group: group),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text('admin.groups.edit'.tr()),
                ),
                OutlinedButton(
                  onPressed: () => _toggleArchive(context, ref),
                  child: Text((group.archived ? 'admin.groups.unarchive' : 'admin.groups.archive').tr()),
                ),
              ],
            ),
          ],
        ),
        verticalSpace(20),
      ],
    );
  }
}
