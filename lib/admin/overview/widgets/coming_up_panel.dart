import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/insights/group_insights.dart';
import 'package:cairo_coding_app/admin/widgets/admin_panel.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/link_launcher.dart';
import 'package:cairo_coding_app/core/helpers/pickers.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/date_badge.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/shared/session_labels.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The next session in full, with the three after it.
class ComingUpPanel extends ConsumerWidget {
  const ComingUpPanel({super.key, required this.upcoming, required this.now});

  final List<(GroupInsights, ClassSession)> upcoming;
  final DateTime now;

  String _startsIn(DateTime startsAt) {
    final left = startsAt.difference(now);
    if (left.isNegative) return 'home.live_now'.tr();
    if (left.inDays > 0) return 'admin.overview.in_days'.tr(args: ['${left.inDays}', '${left.inHours % 24}']);
    return 'admin.overview.in_hours'.tr(args: ['${left.inHours}', '${left.inMinutes % 60}']);
  }

  Future<void> _reschedule(BuildContext context, WidgetRef ref, ClassSession session) async {
    final picked = await pickDateTime(context, initial: session.startsAt);
    if (picked == null || !context.mounted) return;
    final result = await ref.read(academyRepositoryProvider).reschedule(session, picked);
    if (!context.mounted) return;
    if (result case Err(:final failure)) showAppSnackBar(context, failure.message, isError: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final first = upcoming.firstOrNull;

    return AdminPanel(
      title: 'admin.overview.coming_up'.tr(),
      trailing: TextButton(
        onPressed: () => context.go(AdminRoutes.groups),
        child: Text('admin.overview.all_groups'.tr()),
      ),
      child: first == null
          ? EmptyView(message: 'home.no_upcoming'.tr(), icon: Icons.event_available_outlined)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: .4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              [first.$1.group.name, first.$2.title].join(' · '),
                              style: AppTextStyles.monoFont12Bold.copyWith(color: colorScheme.primary),
                            ),
                          ),
                          Text(
                            _startsIn(first.$2.startsAt),
                            style: AppTextStyles.monoFont11Bold.copyWith(color: colorScheme.tertiary),
                          ),
                        ],
                      ),
                      verticalSpace(8),
                      Text(
                        first.$2.topic.isEmpty ? first.$2.title : context.bidi(first.$2.topic),
                        style: AppTextStyles.font16ExtraBold,
                      ),
                      verticalSpace(4),
                      Text(
                        '${context.shortDay(first.$2.startsAt)} · ${context.time(first.$2.startsAt)} – '
                        '${context.time(first.$2.endsAt)} · ${'admin.overview.students'.tr(args: ['${first.$1.members.length}'])}',
                        style: AppTextStyles.font13Normal.secondary(context),
                      ),
                      verticalSpace(12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
                              onPressed: () {
                                final override = first.$2.meetingLinkOverride?.trim() ?? '';
                                openExternalLink(override.isNotEmpty ? override : first.$1.group.meetingLink);
                              },
                              child: Text('admin.overview.start_meeting'.tr()),
                            ),
                          ),
                          horizontalSpace(8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                            onPressed: () => _reschedule(context, ref, first.$2),
                            child: Text('admin.schedule.reschedule'.tr()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                verticalSpace(6),
                for (final (insights, session) in upcoming.skip(1).take(3))
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => context.go(AdminRoutes.group(insights.group.id, GroupTab.schedule)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                      child: Row(
                        children: [
                          DateBadge(
                            top: context.weekdayShort(session.startsAt).toUpperCase(),
                            bottom: context.dayNumber(session.startsAt),
                            size: 42,
                          ),
                          horizontalSpace(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${insights.group.name} · ${session.title}', style: AppTextStyles.font14ExtraBold),
                                Text(
                                  '${context.time(session.startsAt)} · '
                                  '${'admin.overview.students'.tr(args: ['${insights.members.length}'])}',
                                  style: AppTextStyles.font12Normal.secondary(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
