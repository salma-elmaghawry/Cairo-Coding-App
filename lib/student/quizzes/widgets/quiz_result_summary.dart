import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/theme/app_colors.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/data/models/quiz_attempt.dart';
import 'package:cairo_coding_app/data/services/leaderboard.dart';
import 'package:cairo_coding_app/data/services/quiz_progress.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_providers.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:cairo_coding_app/student/student_routes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class QuizCountsRow extends StatelessWidget {
  const QuizCountsRow({super.key, required this.total, required this.correct, required this.wrong});

  final int total;
  final int correct;
  final int wrong;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget count(String label, int value, Color? color) => Expanded(
      child: Column(
        children: [
          AnimatedCounter(
            value: value,
            style: AppTextStyles.monoFont20Bold.copyWith(color: color),
          ),
          verticalSpace(2),
          Text(label, style: AppTextStyles.font12Normal.secondary(context)),
        ],
      ),
    );

    return IntrinsicHeight(
      child: Row(
        children: [
          count('quizzes.total'.tr(), total, null),
          const VerticalDivider(),
          count('quizzes.correct'.tr(), correct, AppColors.success),
          const VerticalDivider(),
          count('quizzes.wrong'.tr(), wrong, colorScheme.error),
        ],
      ),
    );
  }
}

class QuizRankRow extends ConsumerWidget {
  const QuizRankRow({super.key, required this.progress, required this.attempt});

  final QuizProgress progress;
  final QuizAttempt attempt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gold = Theme.of(context).colorScheme.tertiary;
    final quiz = progress.quiz;
    final first = progress.firstAttempt;
    final groupId = rankingGroupOf(first, quiz, ref.watch(studentGroupIdsProvider));
    final board = groupId == null ? null : ref.watch(quizBoardProvider((groupId: groupId, quizId: quiz.id))).value;
    final ranked = board == null ? const <RankedStudent>[] : Leaderboard.forQuiz(board);
    final mine = ranked.where((student) => student.uid == attempt.uid).firstOrNull;

    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      color: gold.withValues(alpha: .12),
      onTap: () => context.push(StudentRoutes.quizLeaderboard(quiz.id)),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: gold, size: 26),
          horizontalSpace(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('quizzes.leaderboard'.tr(), style: AppTextStyles.font14ExtraBold),
                Text(
                  mine == null
                      ? 'quizzes.leaderboard_hint'.tr()
                      : 'quizzes.ranked'.tr(args: ['${mine.rank}', '${ranked.length}']),
                  style: AppTextStyles.font12Normal.secondary(context),
                ),
                if (attempt.number > 1)
                  Text('quizzes.retake_note'.tr(), style: AppTextStyles.font12Normal.secondary(context)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
