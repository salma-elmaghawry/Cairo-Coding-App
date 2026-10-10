import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/eyebrow_text.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  String _greetingKey(int hour) => switch (hour) {
    < 12 => 'home.greeting_morning',
    < 17 => 'home.greeting_afternoon',
    _ => 'home.greeting_evening',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(currentUserProvider.select((user) => user?.profile.name ?? ''));
    final groupNames = ref.watch(
      studentGroupsProvider.select((value) => value.value?.map((g) => g.name).join(' · ') ?? ''),
    );
    final hour = ref.watch(clockProvider)().hour;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EyebrowText(_greetingKey(hour).tr()),
              verticalSpace(4),
              Text('home.hi'.tr(args: [name.split(' ').first]), style: AppTextStyles.font24ExtraBold),
            ],
          ),
        ),
        if (groupNames.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colorScheme.primary.withValues(alpha: .35)),
            ),
            child: Text(groupNames, style: AppTextStyles.monoFont12Bold.copyWith(color: colorScheme.primary)),
          ),
      ],
    );
  }
}
