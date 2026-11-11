import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/hero_card.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The student's initials, name and sign-in email.
class ProfileCard extends ConsumerWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProvider.select((user) => user?.profile));
    final colorScheme = Theme.of(context).colorScheme;
    if (profile == null) return const SizedBox.shrink();

    return HeroCard(
      padding: const EdgeInsets.all(18),
      child: Row(
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
            child: Text(profile.initials, style: AppTextStyles.font22ExtraBold.copyWith(color: colorScheme.onPrimary)),
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
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.font13Normal.secondary(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
