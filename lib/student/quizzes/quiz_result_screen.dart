import 'package:cairo_coding_app/core/error_handling/failures.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/not_found_screen.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/quiz_attempt.dart';
import 'package:cairo_coding_app/data/services/quiz_progress.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_format.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_providers.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/quiz_answer_review.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/quiz_result_summary.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/quiz_score_hero.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/quiz_stat_tile.dart';
import 'package:cairo_coding_app/student/student_routes.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class QuizResultScreen extends ConsumerWidget {
  const QuizResultScreen({super.key, required this.quizId, required this.attemptNumber});

  final String quizId;
  final int attemptNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(quizProgressProvider(quizId));

    return Scaffold(
      appBar: AppBar(
        title: Text('quizzes.result_title'.tr()),
        leading: const SizedBox.shrink(),
        leadingWidth: 0,
        actions: [
          IconButton(
            tooltip: 'common.close'.tr(),
            onPressed: () => context.go(StudentRoutes.quizzes),
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
          horizontalSpace(12),
        ],
      ),
      body: switch (progress) {
        AsyncError(:final error) => ErrorView(message: error.toString()),
        AsyncData(value: null) => const NotFoundScreen(),
        AsyncData(:final value?) => _attemptBody(value),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _attemptBody(QuizProgress progress) {
    final attempt = progress.attempts.where((a) => a.number == attemptNumber).firstOrNull;
    if (attempt == null) return const NotFoundScreen();
    if (!attempt.isGraded) return _Grading(attempt: attempt);
    return _Result(progress: progress, attempt: attempt);
  }
}

/// The attempt was submitted but the grade hasn't been saved, usually a dropped connection. This finishes it.
class _Grading extends ConsumerStatefulWidget {
  const _Grading({required this.attempt});

  final QuizAttempt attempt;

  @override
  ConsumerState<_Grading> createState() => _GradingState();
}

class _GradingState extends ConsumerState<_Grading> {
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _finish();
  }

  Future<void> _finish() async {
    setState(() => _failure = null);
    final result = await ref.read(quizRepositoryProvider).finishAttempt(widget.attempt.id);
    if (!mounted) return;
    if (result case Err(:final failure)) setState(() => _failure = failure);
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    if (failure != null) return ErrorView(message: failure.message, onRetry: _finish);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          verticalSpace(14),
          Text('quizzes.submitting'.tr(), style: AppTextStyles.font14Normal.secondary(context)),
        ],
      ),
    );
  }
}

class _Result extends ConsumerWidget {
  const _Result({required this.progress, required this.attempt});

  final QuizProgress progress;
  final QuizAttempt attempt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiz = progress.quiz;
    final now = ref.watch(minuteTickerProvider).value ?? ref.watch(clockProvider)();
    final percent = percentOf(attempt.score ?? 0, quiz.totalPoints);
    final correct = attempt.correctCount ?? 0;
    final canRetake = progress.canStartNew(now);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        QuizScoreHero(percent: percent),
        verticalSpace(12),
        Text(_headline(percent).tr(), textAlign: TextAlign.center, style: AppTextStyles.font24ExtraBold),
        verticalSpace(4),
        Text(
          'quizzes.summary'.tr(args: ['$correct', '${quiz.questionCount}', context.bidi(quiz.title)]),
          textAlign: TextAlign.center,
          style: AppTextStyles.font14Normal.secondary(context),
        ),
        verticalSpace(18),
        QuizCountsRow(total: quiz.questionCount, correct: correct, wrong: attempt.wrongCount),
        verticalSpace(16),
        QuizRankRow(progress: progress, attempt: attempt),
        verticalSpace(20),
        Text('quizzes.performance'.tr(), style: AppTextStyles.font18Bold),
        verticalSpace(10),
        Row(
          children: [
            Expanded(
              child: QuizStatTile(
                icon: Icons.star_outline_rounded,
                label: 'quizzes.stat_score'.tr(),
                value: '${attempt.score}/${quiz.totalPoints}',
              ),
            ),
            horizontalSpace(10),
            Expanded(
              child: QuizStatTile(icon: Icons.percent_rounded, label: 'quizzes.stat_percent'.tr(), value: '$percent%'),
            ),
          ],
        ),
        verticalSpace(10),
        Row(
          children: [
            Expanded(
              child: QuizStatTile(
                icon: Icons.quiz_outlined,
                label: 'quizzes.stat_answered'.tr(),
                value: '${attempt.answeredCount}/${quiz.questionCount}',
              ),
            ),
            horizontalSpace(10),
            Expanded(
              child: QuizStatTile(
                icon: Icons.timer_outlined,
                label: 'quizzes.stat_time_taken'.tr(),
                value: formatClock(attempt.timeTaken),
              ),
            ),
          ],
        ),
        verticalSpace(20),
        if (quiz.hasClosed(now))
          QuizAnswerReview(attempt: attempt)
        else
          AppCard(
            padding: const EdgeInsets.all(14),
            radius: 16,
            child: Row(
              children: [
                Icon(Icons.lock_clock_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                horizontalSpace(10),
                Expanded(
                  child: Text('quizzes.review_locked'.tr(), style: AppTextStyles.font12Medium.secondary(context)),
                ),
              ],
            ),
          ),
        verticalSpace(20),
        if (canRetake) ...[
          OutlinedButton.icon(
            onPressed: () => context.go(StudentRoutes.quiz(quiz.id)),
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: Text('quizzes.retake'.tr()),
          ),
          verticalSpace(10),
        ],
        PrimaryButton(
          label: 'quizzes.back_to_quizzes'.tr(),
          icon: Icons.arrow_back_rounded,
          onPressed: () => context.go(StudentRoutes.quizzes),
        ),
      ],
    );
  }

  String _headline(int percent) => switch (percent) {
    >= 90 => 'quizzes.headline_top',
    >= 70 => 'quizzes.headline_great',
    >= 50 => 'quizzes.headline_good',
    _ => 'quizzes.headline_keep_going',
  };
}
