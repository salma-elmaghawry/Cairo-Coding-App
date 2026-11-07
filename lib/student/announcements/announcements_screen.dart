import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/icon_tile.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/student/student_activity.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Messages from the academy to the student's groups, newest first. Opening it marks them all read.
class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  // The unread ones stay highlighted while the screen is open, even though they're marked read.
  late final DateTime _readBefore = ref.read(announcementsReadAtProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(announcementsReadAtProvider.notifier).markRead());
  }

  @override
  Widget build(BuildContext context) {
    final announcements = ref.watch(studentAnnouncementsProvider);
    final groups = ref.watch(groupsByIdProvider);
    final now = ref.watch(clockProvider)();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('announcements.title'.tr())),
      body: switch (announcements) {
        AsyncError(:final error) => ErrorView(message: error.toString()),
        AsyncData(:final value) when value.isEmpty => EmptyView(
          message: 'announcements.empty'.tr(),
          icon: Icons.notifications_none_rounded,
        ),
        AsyncData(:final value) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: value.length,
          separatorBuilder: (_, _) => verticalSpace(12),
          itemBuilder: (context, index) {
            final announcement = value[index];
            final unread = announcement.createdAt.isAfter(_readBefore);
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: unread ? colorScheme.surface : colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: unread ? colorScheme.primary.withValues(alpha: .5) : colorScheme.outline),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IconTile(icon: Icons.campaign_outlined, size: 42),
                  horizontalSpace(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.bidi(announcement.title), style: AppTextStyles.font16ExtraBold),
                        verticalSpace(4),
                        Text(
                          context.bidi(announcement.body),
                          style: AppTextStyles.font14Normal.secondary(context).copyWith(height: 1.45),
                        ),
                        verticalSpace(8),
                        Text(
                          [
                            context.relativeTime(announcement.createdAt, now),
                            ...[for (final id in announcement.groupIds) ?groups[id]?.name],
                          ].join(' · '),
                          style: AppTextStyles.font12Normal.muted(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).fadeInSlideUp(delay: AppAnimations.staggerDelay * index.clamp(0, 8));
          },
        ),
        _ => const Padding(padding: EdgeInsets.all(20), child: SkeletonList(count: 3, itemHeight: 110)),
      },
    );
  }
}
