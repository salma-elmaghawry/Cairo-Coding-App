import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/icon_tile.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/services/quiz_progress.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_format.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_image.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/quiz_labels.dart';
import 'package:cairo_coding_app/student/student_routes.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
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
    final tint = availability.tone.color(context);
    final when = switch (availability) {
      QuizAvailability.upcoming => 'quizzes.opens_on'.tr(args: [_dateTime(context, quiz.opensAt)]),
      QuizAvailability.expired => 'quizzes.closed_on'.tr(args: [_dateTime(context, quiz.closesAt)]),
      _ when quiz.hasClosed(now) => 'quizzes.closed_on'.tr(args: [_dateTime(context, quiz.closesAt)]),
      _ => 'quizzes.closes_on'.tr(args: [_dateTime(context, quiz.closesAt)]),
    };
    void open() => context.push(StudentRoutes.quiz(quiz.id));

    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 22,
      color: colorScheme.surfaceContainer,
      onTap: open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: 46,
                child: QuizImage(
                  url: quiz.coverUrl,
                  radius: 14,
                  fallback: IconTile(
                    icon: availability.icon,
                    color: tint,
                    background: availability == QuizAvailability.upcoming ? colorScheme.surfaceContainerLowest : null,
                    border: availability == QuizAvailability.upcoming ? colorScheme.outline : null,
                    size: 46,
                  ),
                ),
              ),
              horizontalSpace(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            context.bidi(quiz.title),
                            style: AppTextStyles.font16ExtraBold.copyWith(height: 1.3),
                          ),
                        ),
                        horizontalSpace(8),
                        StatusChip(label: availability.label, tone: availability.tone),
                      ],
                    ),
                    if (quiz.description.isNotEmpty) ...[
                      verticalSpace(4),
                      Text(
                        context.bidi(quiz.description),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.font13Normal.secondary(context).copyWith(height: 1.45),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          verticalSpace(14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MetaPill('quizzes.questions_count'.plural(quiz.questionCount)),
              _MetaPill(quiz.timeLabel),
              _MetaPill('quizzes.points_count'.plural(quiz.totalPoints)),
            ],
          ),
          if (best != null) ...[verticalSpace(14), _Score(score: best.score ?? 0, total: quiz.totalPoints)],
          verticalSpace(14),
          Divider(color: colorScheme.primary.withValues(alpha: .16)),
          verticalSpace(12),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 14, color: colorScheme.onSurfaceVariant),
              horizontalSpace(6),
              Expanded(child: Text(when, style: AppTextStyles.font12Normal.secondary(context))),
              horizontalSpace(12),
              _Cta(availability: availability, onPressed: open),
            ],
          ),
        ],
      ),
    );
  }

  String _dateTime(BuildContext context, DateTime date) => '${context.shortDay(date)}, ${context.time(date)}';
}

class _MetaPill extends StatelessWidget {
  const _MetaPill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.primary.withValues(alpha: .16)),
      ),
      child: Text(text, style: AppTextStyles.font12Bold.secondary(context)),
    );
  }
}

class _Score extends StatelessWidget {
  const _Score({required this.score, required this.total});

  final int score;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = percentOf(score, total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('quizzes.your_score'.tr(), style: AppTextStyles.font13Normal.secondary(context))),
            Text('$score/$total', textDirection: TextDirection.ltr, style: AppTextStyles.monoFont14Bold),
            horizontalSpace(6),
            Text('$percent%', textDirection: TextDirection.ltr, style: AppTextStyles.monoFont12Medium.muted(context)),
          ],
        ),
        verticalSpace(8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : score / total,
            minHeight: 8,
            backgroundColor: colorScheme.primary.withValues(alpha: .16),
          ),
        ),
      ],
    );
  }
}

class _Cta extends StatelessWidget {
  const _Cta({required this.availability, required this.onPressed});

  final QuizAvailability availability;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const size = Size(0, 40);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

    if (availability == QuizAvailability.available) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(minimumSize: size, shape: shape, textStyle: AppTextStyles.font14ExtraBold),
        child: Text('quizzes.start'.tr()),
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: size,
        shape: shape,
        foregroundColor: availability == QuizAvailability.completed ? colorScheme.primary : colorScheme.onSurface,
        side: BorderSide(color: colorScheme.primary.withValues(alpha: .35)),
        textStyle: AppTextStyles.font14ExtraBold,
      ),
      child: Text((availability == QuizAvailability.completed ? 'quizzes.review' : 'quizzes.details').tr()),
    );
  }
}
