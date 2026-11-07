import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/icon_tile.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/services/quiz_progress.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/quiz_labels.dart';
import 'package:cairo_coding_app/student/student_routes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The open quiz that closes first, with how long is left to take it.
class DueQuizCard extends StatelessWidget {
  const DueQuizCard({super.key, required this.progress, required this.now});

  final QuizProgress progress;
  final DateTime now;

  String get _timeLeft {
    final left = progress.quiz.closesAt.difference(now);
    if (left.inDays > 0) return 'home.days_left'.tr(args: ['${left.inDays}']);
    if (left.inHours > 0) return 'home.hours_left'.tr(args: ['${left.inHours}']);
    return 'home.minutes_left'.tr(args: ['${left.inMinutes < 1 ? 1 : left.inMinutes}']);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final quiz = progress.quiz;
    final resume = progress.inProgress != null;
    final meta = [
      'quizzes.questions_count'.plural(quiz.questionCount),
      quiz.timeLabel,
      'quizzes.points_count'.plural(quiz.totalPoints),
    ].join(' · ');

    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 20,
      color: colorScheme.surfaceContainer,
      onTap: () => context.push(resume ? StudentRoutes.takeQuiz(quiz.id) : StudentRoutes.quiz(quiz.id)),
      child: Row(
        children: [
          const IconTile(icon: Icons.quiz_outlined, size: 48),
          horizontalSpace(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.bidi(quiz.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font15ExtraBold,
                ),
                verticalSpace(3),
                Text(meta, style: AppTextStyles.font13Normal.secondary(context)),
              ],
            ),
          ),
          horizontalSpace(8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusChip(label: _timeLeft, tone: StatusTone.danger),
              verticalSpace(6),
              Text(
                (resume ? 'home.resume' : 'home.start').tr(),
                style: AppTextStyles.font13ExtraBold.copyWith(color: colorScheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
