import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/progress_ring.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_format.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_summary.dart';
import 'package:cairo_coding_app/student/student_activity.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How far through the course the student is, with their quiz average and rank beside it.
class ProgressSection extends ConsumerWidget {
  const ProgressSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(courseProgressProvider);
    final average = ref.watch(quizSummaryProvider.select((summary) => summary?.average));
    final attendance = ref.watch(myAttendanceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('home.your_progress'.tr(), style: AppTextStyles.font18ExtraBold),
        verticalSpace(12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: _CourseCard(done: progress.done, total: progress.total),
              ),
              horizontalSpace(10),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'home.attendance'.tr(),
                        value: attendance == null ? '–' : '${percentOf(attendance * 100, 100)}%',
                        good: attendance != null && attendance >= .9,
                      ),
                    ),
                    verticalSpace(10),
                    Expanded(
                      child: _MiniStat(label: 'home.quiz_avg'.tr(), value: average == null ? '–' : '$average%'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percent = percentOf(done, total);

    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 20,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Row(
        children: [
          ProgressRing(
            value: total == 0 ? 0 : done / total,
            size: 60,
            semanticsLabel: '$done/$total ${'home.sessions_done'.tr()}',
            child: Text('$percent%', textDirection: TextDirection.ltr, style: AppTextStyles.monoFont12Bold),
          ),
          horizontalSpace(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('home.course'.tr(), style: AppTextStyles.font13Normal.secondary(context)),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '$done', style: AppTextStyles.monoFont18Bold),
                      TextSpan(text: '/$total', style: AppTextStyles.monoFont14Medium.muted(context)),
                    ],
                  ),
                  textDirection: TextDirection.ltr,
                ),
                Text(
                  'home.sessions_done'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font12Normal.muted(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.good = false});

  final String label;
  final String value;

  /// Shows the value in green.
  final bool good;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      radius: 16,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.font12Normal.secondary(context),
            ),
          ),
          horizontalSpace(6),
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.monoFont16Bold.copyWith(color: good ? StatusTone.success.color(context) : null),
          ),
        ],
      ),
    );
  }
}
