import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileCard extends ConsumerWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProvider.select((user) => user?.profile));
    final groupNames = ref.watch(
      studentGroupsProvider.select((value) => value.value?.map((g) => g.name).join(' · ') ?? ''),
    );
    final colorScheme = Theme.of(context).colorScheme;
    if (profile == null) return const SizedBox.shrink();

    return AppCard(
      radius: 20,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfaceContainerLowest,
              border: Border.all(color: colorScheme.primary.withValues(alpha: .35)),
            ),
            child: Text(profile.initials, style: AppTextStyles.font20Bold.copyWith(color: colorScheme.primary)),
          ),
          horizontalSpace(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name, style: AppTextStyles.font18ExtraBold),
                Text(profile.email, style: AppTextStyles.font14Normal.secondary(context)),
                if (groupNames.isNotEmpty)
                  Text(groupNames, style: AppTextStyles.monoFont12Medium.copyWith(color: colorScheme.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
