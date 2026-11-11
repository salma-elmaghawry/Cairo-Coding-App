import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/progress_ring.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_format.dart';
import 'package:cairo_coding_app/student/profile/profile_providers.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The attendance rate and the tasks rate side by side, each as a ring with "n of m" under it.
class RatesRow extends ConsumerWidget {
  const RatesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendance = ref.watch(myAttendanceTallyProvider);
    final tasks = ref.watch(myTasksTallyProvider);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _RateCard(
              label: 'profile.attendance_rate'.tr(context: context),
              tally: attendance,
              countKey: 'profile.sessions_of',
            ),
          ),
          horizontalSpace(10),
          Expanded(
            child: _RateCard(
              label: 'profile.tasks_rate'.tr(context: context),
              tally: tasks,
              countKey: 'profile.tasks_of',
            ),
          ),
        ],
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  const _RateCard({required this.label, required this.tally, required this.countKey});

  final String label;
  final Tally tally;

  /// Takes the done and total counts.
  final String countKey;

  @override
  Widget build(BuildContext context) {
    final empty = tally.total == 0;
    final percent = '${percentOf(tally.done, tally.total)}%';
    final detail = empty
        ? 'profile.no_data'.tr(context: context)
        : countKey.tr(context: context, args: ['${tally.done}', '${tally.total}']);

    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 20,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Semantics(
        label: '$label: ${empty ? detail : '$percent, $detail'}',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProgressRing(
              value: empty ? 0 : tally.done / tally.total,
              size: 56,
              strokeWidth: 6,
              child: Text(empty ? '–' : percent, textDirection: TextDirection.ltr, style: AppTextStyles.monoFont12Bold),
            ),
            verticalSpace(10),
            Text(label, style: AppTextStyles.font14ExtraBold),
            verticalSpace(2),
            Text(detail, style: AppTextStyles.font12Normal.muted(context)),
          ],
        ),
      ),
    );
  }
}
