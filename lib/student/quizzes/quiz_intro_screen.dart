import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/error_handling/failures.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/not_found_screen.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/services/quiz_progress.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_image.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_providers.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/quiz_labels.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/quiz_stat_tile.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:cairo_coding_app/student/student_routes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class QuizIntroScreen extends ConsumerStatefulWidget {
  const QuizIntroScreen({super.key, required this.quizId});

  final String quizId;

  @override
  ConsumerState<QuizIntroScreen> createState() => _QuizIntroScreenState();
}

class _QuizIntroScreenState extends ConsumerState<QuizIntroScreen> {
  bool _starting = false;

  Future<void> _start(QuizProgress progress) async {
    final student = ref.read(currentUserProvider)?.profile;
    if (student == null) return;
    setState(() => _starting = true);
    final result = await ref
        .read(quizRepositoryProvider)
        .startAttempt(progress.quiz, student, number: progress.attempts.length + 1);
    if (!mounted) return;
    setState(() => _starting = false);
    switch (result) {
      case Ok(:final value):
        ref.read(quizClockSkewProvider.notifier).measure(value.startedAt);
        context.push(StudentRoutes.takeQuiz(widget.quizId));
      case Err(:final failure):
        showAppSnackBar(
          context,
          failure is NotAuthorizedFailure ? 'quizzes.errors.not_available'.tr() : failure.message,
          isError: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(quizProgressProvider(widget.quizId));
    final now = ref.watch(minuteTickerProvider).value ?? ref.watch(clockProvider)();

    return switch (progress) {
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: error.toString()),
      ),
      AsyncData(value: null) => const NotFoundScreen(),
      AsyncData(:final value?) => Scaffold(
        appBar: AppBar(title: Text('quizzes.intro_title'.tr())),
        body: _Details(progress: value, now: now),
        bottomNavigationBar: SafeArea(
          child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 12), child: _action(value, now)),
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }

  Widget _action(QuizProgress progress, DateTime now) {
    final inProgress = progress.inProgress;
    if (inProgress != null && !inProgress.isExpired(now)) {
      return PrimaryButton(
        label: 'quizzes.resume'.tr(),
        icon: Icons.play_arrow_rounded,
        onPressed: () => context.push(StudentRoutes.takeQuiz(widget.quizId)),
      );
    }
    if (progress.canStartNew(now)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (progress.latestFinished case final latest?) ...[
            OutlinedButton(
              onPressed: () => context.push(StudentRoutes.quizResult(widget.quizId, latest.number)),
              child: Text('quizzes.view_result'.tr()),
            ),
            verticalSpace(8),
          ],
          PrimaryButton(
            label: progress.attempts.isEmpty ? 'quizzes.start'.tr() : 'quizzes.retake'.tr(),
            icon: Icons.play_arrow_rounded,
            isLoading: _starting,
            onPressed: () => _start(progress),
          ),
        ],
      );
    }
    if (progress.latestFinished case final latest?) {
      return PrimaryButton(
        label: 'quizzes.view_result'.tr(),
        icon: Icons.bar_chart_rounded,
        onPressed: () => context.push(StudentRoutes.quizResult(widget.quizId, latest.number)),
      );
    }
    final label = switch (progress.availability(now)) {
      QuizAvailability.upcoming => 'quizzes.not_open_yet'.tr(),
      _ => 'quizzes.closed'.tr(),
    };
    return PrimaryButton(label: label);
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.progress, required this.now});

  final QuizProgress progress;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final quiz = progress.quiz;
    final availability = progress.availability(now);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        QuizImage(
          url: quiz.coverUrl,
          height: 150,
          radius: 20,
          fallback: ColoredBox(
            color: colorScheme.primary.withValues(alpha: .14),
            child: Center(child: Icon(Icons.quiz_rounded, size: 56, color: colorScheme.primary)),
          ),
        ),
        verticalSpace(16),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: StatusChip(label: availability.label, tone: availability.tone),
        ),
        verticalSpace(10),
        Text(context.bidi(quiz.title), style: AppTextStyles.font24ExtraBold),
        if (quiz.description.isNotEmpty) ...[
          verticalSpace(6),
          Text(context.bidi(quiz.description), style: AppTextStyles.font14Normal.secondary(context)),
        ],
        verticalSpace(18),
        Row(
          children: [
            Expanded(
              child: QuizStatTile(
                icon: Icons.help_outline_rounded,
                label: 'quizzes.stat_questions'.tr(),
                value: '${quiz.questionCount}',
              ),
            ),
            horizontalSpace(10),
            Expanded(
              child: QuizStatTile(icon: Icons.timer_outlined, label: 'quizzes.stat_time'.tr(), value: quiz.timeLabel),
            ),
          ],
        ),
        verticalSpace(10),
        Row(
          children: [
            Expanded(
              child: QuizStatTile(
                icon: Icons.star_outline_rounded,
                label: 'quizzes.stat_points'.tr(),
                value: '${quiz.totalPoints}',
              ),
            ),
            horizontalSpace(10),
            Expanded(
              child: QuizStatTile(
                icon: Icons.replay_rounded,
                label: 'quizzes.stat_attempts'.tr(),
                value: 'quizzes.attempts_left'.tr(args: ['${progress.attemptsLeft}', '${quiz.maxAttempts}']),
              ),
            ),
          ],
        ),
        verticalSpace(14),
        AppCard(
          padding: const EdgeInsets.all(14),
          radius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoRow(icon: Icons.event_available_outlined, text: _when(context, 'quizzes.opens_on', quiz.opensAt)),
              verticalSpace(8),
              _InfoRow(icon: Icons.event_busy_outlined, text: _when(context, 'quizzes.closes_on', quiz.closesAt)),
            ],
          ),
        ),
        verticalSpace(14),
        Text('quizzes.rules_title'.tr(), style: AppTextStyles.font14ExtraBold),
        verticalSpace(8),
        _InfoRow(icon: Icons.lock_outline_rounded, text: 'quizzes.rule_lock'.tr()),
        verticalSpace(6),
        if (quiz.hasTimeLimit) ...[
          _InfoRow(icon: Icons.timer_off_outlined, text: 'quizzes.rule_timer'.tr()),
          verticalSpace(6),
        ],
        _InfoRow(icon: Icons.emoji_events_outlined, text: 'quizzes.rule_rank'.tr()),
      ].animateList(),
    );
  }

  String _when(BuildContext context, String key, DateTime date) =>
      key.tr(args: ['${context.shortDay(date)}, ${context.time(date)}']);
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        horizontalSpace(10),
        Expanded(child: Text(text, style: AppTextStyles.font14Normal.secondary(context))),
      ],
    );
  }
}
