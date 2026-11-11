import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/eyebrow_text.dart';
import 'package:cairo_coding_app/core/widgets/progress_ring.dart';
import 'package:cairo_coding_app/student/student_activity.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:cairo_coding_app/student/student_routes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  String _greetingKey(int hour) => switch (hour) {
    < 12 => 'home.greeting_morning',
    < 17 => 'home.greeting_afternoon',
    _ => 'home.greeting_evening',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProvider.select((user) => user?.profile));
    final progress = ref.watch(courseProgressProvider);
    final hour = ref.watch(clockProvider)().hour;
    final colorScheme = Theme.of(context).colorScheme;
    final name = profile?.name ?? '';

    return Row(
      children: [
        // The ring around the avatar fills as the course goes on.
        Semantics(
          button: true,
          label: 'home.profile'.tr(),
          excludeSemantics: true,
          child: InkResponse(
            onTap: () => context.go(StudentRoutes.profile),
            customBorder: const CircleBorder(),
            child: ProgressRing(
              value: progress.total == 0 ? 0 : progress.done / progress.total,
              size: 48,
              strokeWidth: 2.5,
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.surface),
                child: Text(profile?.initials ?? '', style: AppTextStyles.font15ExtraBold),
              ),
            ),
          ),
        ),
        horizontalSpace(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EyebrowText(_greetingKey(hour).tr()),
              verticalSpace(2),
              Text(
                'home.hi'.tr(args: [name.split(' ').first]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.font22ExtraBold,
              ),
            ],
          ),
        ),
        const _AnnouncementsBell(),
      ],
    );
  }
}

class _AnnouncementsBell extends ConsumerWidget {
  const _AnnouncementsBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadAnnouncementsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: unread == 0 ? 'announcements.title'.tr() : 'announcements.unread'.tr(args: ['$unread']),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => context.push(StudentRoutes.announcements),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications_none_rounded, size: 21),
              if (unread > 0)
                PositionedDirectional(
                  top: 9,
                  end: 10,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary,
                      border: Border.all(color: colorScheme.surfaceContainer, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
