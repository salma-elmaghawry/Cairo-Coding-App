import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/services/quiz_progress.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_image.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/quiz_labels.dart';
import 'package:cairo_coding_app/student/student_routes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuizCard extends StatelessWidget {
  const QuizCard({super.key, required this.progress, required this.now});

  final QuizProgress progress;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final quiz = progress.quiz;
    final availability = progress.availability(now);
    final best = progress.best;
    final when = switch (availability) {
      QuizAvailability.upcoming => 'quizzes.opens_on'.tr(args: [_dateTime(context, quiz.opensAt)]),
      QuizAvailability.expired => 'quizzes.closed_on'.tr(args: [_dateTime(context, quiz.closesAt)]),
      _ when quiz.hasClosed(now) => 'quizzes.closed_on'.tr(args: [_dateTime(context, quiz.closesAt)]),
      _ => 'quizzes.closes_on'.tr(args: [_dateTime(context, quiz.closesAt)]),
    };

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push(StudentRoutes.quiz(quiz.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: QuizImage(
                  url: quiz.coverUrl,
                  radius: 14,
                  fallback: ColoredBox(
                    color: colorScheme.primary.withValues(alpha: .14),
                    child: Icon(availability.icon, color: colorScheme.primary),
                  ),
                ),
              ),
              horizontalSpace(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.bidi(quiz.title), style: AppTextStyles.font16ExtraBold),
                    if (quiz.description.isNotEmpty) ...[
                      verticalSpace(2),
                      Text(
                        context.bidi(quiz.description),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.font12Normal.secondary(context),
                      ),
                    ],
                  ],
                ),
              ),
              horizontalSpace(8),
              StatusChip(label: availability.label, tone: availability.tone),
            ],
          ),
          verticalSpace(12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _Meta(icon: Icons.help_outline_rounded, text: 'quizzes.questions_count'.plural(quiz.questionCount)),
              _Meta(icon: Icons.timer_outlined, text: quiz.timeLabel),
              _Meta(icon: Icons.star_outline_rounded, text: 'quizzes.points_count'.plural(quiz.totalPoints)),
            ],
          ),
          verticalSpace(10),
          const Divider(),
          verticalSpace(10),
          Row(
            children: [
              Expanded(child: Text(when, style: AppTextStyles.font12Medium.secondary(context))),
              if (best != null)
                Text(
                  '${best.score}/${quiz.totalPoints}',
                  style: AppTextStyles.monoFont14Bold.copyWith(color: colorScheme.primary),
                )
              else
                Icon(Icons.arrow_forward_rounded, size: 18, color: colorScheme.primary),
            ],
          ),
        ],
      ),
    );
  }

  String _dateTime(BuildContext context, DateTime date) => '${context.shortDay(date)}, ${context.time(date)}';
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
        horizontalSpace(4),
        Text(text, style: AppTextStyles.font12Medium.secondary(context)),
      ],
    );
  }
}
