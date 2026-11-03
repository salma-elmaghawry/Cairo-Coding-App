import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/data/services/leaderboard.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_format.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/leaderboard_podium.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/student_avatar.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

class LeaderboardRanking extends StatelessWidget {
  const LeaderboardRanking({super.key, required this.ranked, required this.myUid, required this.showQuizCount});

  final List<RankedStudent> ranked;
  final String? myUid;
  final bool showQuizCount;

  @override
  Widget build(BuildContext context) {
    // Fewer than three students wouldn't fill the steps, so they're listed as plain rows.
    final hasPodium = ranked.length >= 3;
    final listed = hasPodium ? ranked.skip(3).toList() : ranked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasPodium) ...[LeaderboardPodium(top: ranked.take(3).toList(), myUid: myUid), verticalSpace(16)],
        for (final (index, student) in listed.indexed) ...[
          _RankTile(
            student: student,
            isMe: student.uid == myUid,
            showQuizCount: showQuizCount,
          ).fadeInSlideUp(delay: AppAnimations.staggerDelay * index.clamp(0, 8)),
          verticalSpace(8),
        ],
      ],
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({required this.student, required this.isMe, required this.showQuizCount});

  final RankedStudent student;
  final bool isMe;
  final bool showQuizCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? colorScheme.primary.withValues(alpha: .14) : colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isMe ? colorScheme.primary : colorScheme.outline, width: isMe ? 1.5 : 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${student.rank}',
              textAlign: TextAlign.center,
              style: AppTextStyles.monoFont14Bold.secondary(context),
            ),
          ),
          horizontalSpace(8),
          StudentAvatar(name: student.name, size: 38),
          horizontalSpace(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        context.bidi(student.name),
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.font14Bold,
                      ),
                    ),
                    if (isMe) ...[
                      horizontalSpace(6),
                      Text(
                        'quizzes.you'.tr(),
                        style: AppTextStyles.font12SemiBold.copyWith(color: colorScheme.primary),
                      ),
                    ],
                  ],
                ),
                if (showQuizCount)
                  Text(
                    'quizzes.quizzes_taken'.plural(student.quizCount),
                    style: AppTextStyles.font12Normal.secondary(context),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('quizzes.points_count'.plural(student.score), style: AppTextStyles.font14ExtraBold),
              Text(
                formatClock(Duration(milliseconds: student.durationMs)),
                textDirection: TextDirection.ltr,
                style: AppTextStyles.monoFont10Medium.secondary(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
