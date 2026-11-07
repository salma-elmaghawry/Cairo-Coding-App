import 'package:cairo_coding_app/admin/announcements/announcement_providers.dart';
import 'package:cairo_coding_app/admin/insights/group_insights.dart';
import 'package:cairo_coding_app/admin/widgets/admin_panel.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/quiz_attempt.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recentSubmissionsProvider = StreamProvider.autoDispose<List<QuizAttempt>>(
  (ref) => ref.watch(quizRepositoryProvider).watchRecentSubmissions(8),
);

/// The latest quiz submissions, recordings, new students and announcements, newest first.
class ActivityPanel extends ConsumerWidget {
  const ActivityPanel({super.key, required this.groups, required this.now});

  final List<GroupInsights> groups;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final you = 'admin.activity.you'.tr();
    final monthAgo = now.subtract(const Duration(days: 30));
    final quizzes = ref.watch(adminQuizzesByIdProvider);
    final items = <(String, String, DateTime)>[
      for (final attempt in ref.watch(recentSubmissionsProvider).value ?? const <QuizAttempt>[])
        (
          attempt.studentName,
          attempt.score == null
              ? 'admin.activity.submitted'.tr(args: [context.bidi(quizzes[attempt.quizId]?.title ?? '')])
              : 'admin.activity.scored'.tr(
                  args: [
                    context.bidi(quizzes[attempt.quizId]?.title ?? ''),
                    '${attempt.score}/${quizzes[attempt.quizId]?.totalPoints ?? '?'}',
                  ],
                ),
          attempt.submittedAt!,
        ),
      for (final group in groups)
        for (final recording in group.recordings)
          if (recording.addedAt case final added? when added.isAfter(monthAgo))
            (
              you,
              'admin.activity.recording'.tr(args: [group.group.name, '${recording.sessionNumber}'.padLeft(2, '0')]),
              added,
            ),
      for (final group in groups)
        for (final student in group.students)
          if (student.createdAt case final created? when created.isAfter(monthAgo))
            (student.name, 'admin.activity.joined'.tr(args: [group.group.name]), created),
      for (final announcement in ref.watch(adminAnnouncementsProvider).value ?? const [])
        (you, 'admin.activity.announced'.tr(args: [context.bidi(announcement.title)]), announcement.createdAt),
    ]..sort((a, b) => b.$3.compareTo(a.$3));

    return AdminPanel(
      title: 'admin.overview.activity_title'.tr(),
      child: items.isEmpty
          ? EmptyView(message: 'admin.overview.activity_empty'.tr(), icon: Icons.history_rounded)
          : Column(
              children: [
                for (final (index, (who, what, at)) in items.take(6).indexed)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 10,
                          child: Column(
                            children: [
                              verticalSpace(5),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.primary),
                              ),
                              if (index < 5 && index < items.length - 1)
                                Expanded(
                                  child: Container(
                                    width: 1,
                                    margin: const EdgeInsets.only(top: 4),
                                    color: colorScheme.primary.withValues(alpha: .25),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        horizontalSpace(12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(text: '$who ', style: AppTextStyles.font14ExtraBold),
                                      TextSpan(text: what, style: AppTextStyles.font14Normal),
                                    ],
                                  ),
                                ),
                                verticalSpace(2),
                                Text(
                                  context.relativeTime(at, now),
                                  style: AppTextStyles.monoFont10Medium.muted(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
