import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/hero_card.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_summary.dart';
import 'package:cairo_coding_app/student/student_activity.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileCard extends ConsumerWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProvider.select((user) => user?.profile));
    final groupCount = ref.watch(studentGroupIdsProvider).length;
    final attended = ref.watch(myAttendedCountProvider);
    final rank = ref.watch(myRankProvider.select((student) => student?.rank));
    final colorScheme = Theme.of(context).colorScheme;
    if (profile == null) return const SizedBox.shrink();

    return HeroCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary,
                  boxShadow: [BoxShadow(color: colorScheme.primary.withValues(alpha: .2), spreadRadius: 4)],
                ),
                child: Text(
                  profile.initials,
                  style: AppTextStyles.font22ExtraBold.copyWith(color: colorScheme.onPrimary),
                ),
              ),
              horizontalSpace(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name, style: AppTextStyles.font18ExtraBold),
                    verticalSpace(2),
                    Text(
                      profile.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.font13Normal.secondary(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          verticalSpace(16),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _Stat(value: '$groupCount', label: 'settings.stat_groups'.tr()),
                  ),
                  VerticalDivider(width: 1, color: colorScheme.outline),
                  Expanded(
                    child: _Stat(value: '$attended', label: 'settings.stat_attended'.tr()),
                  ),
                  VerticalDivider(width: 1, color: colorScheme.outline),
                  Expanded(
                    child: _Stat(value: rank == null ? '–' : '#$rank', label: 'settings.stat_rank'.tr()),
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

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, textDirection: TextDirection.ltr, style: AppTextStyles.monoFont16Bold),
          verticalSpace(2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.font12Normal.secondary(context),
          ),
        ],
      ),
    );
  }
}
