import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/services/quiz_progress.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_format.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_providers.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/quiz_card.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/quiz_labels.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/quiz_stat_tile.dart';
import 'package:cairo_coding_app/student/student_routes.dart';
import 'package:cairo_coding_app/student/widgets/tab_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class QuizzesScreen extends ConsumerWidget {
  const QuizzesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(quizRecoveryProvider);
    final progress = ref.watch(quizProgressListProvider);
    final filter = ref.watch(quizFilterProvider);
    // A quiz moves from upcoming to available to expired while the screen is open.
    final now = ref.watch(minuteTickerProvider).value ?? ref.watch(clockProvider)();

    Future<void> refresh() async {
      ref.invalidate(studentQuizzesProvider);
      ref.invalidate(myAttemptsProvider);
      await ref.read(studentQuizzesProvider.future);
    }

    return TabPage(
      eyebrow: 'quizzes.eyebrow'.tr(),
      title: 'quizzes.title'.tr(),
      onRefresh: refresh,
      slivers: switch (progress) {
        AsyncError(:final error) => [
          SliverToBoxAdapter(
            child: ErrorView(message: error.toString(), onRetry: refresh),
          ),
        ],
        AsyncData(:final value) => _content(context, ref, value, filter, now),
        _ => const [SliverToBoxAdapter(child: SkeletonList(count: 4, itemHeight: 140))],
      },
    );
  }

  List<Widget> _content(
    BuildContext context,
    WidgetRef ref,
    List<QuizProgress> all,
    QuizAvailability? filter,
    DateTime now,
  ) {
    if (all.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: EmptyView(message: 'quizzes.empty'.tr(), icon: Icons.quiz_outlined),
        ),
      ];
    }
    final visible = (filter == null ? all.toList() : all.where((p) => p.availability(now) == filter).toList())
      ..sort((a, b) {
        // What can be taken now comes first, and the quiz closing soonest leads its section.
        final bySection = a.availability(now).index.compareTo(b.availability(now).index);
        return bySection != 0 ? bySection : a.quiz.closesAt.compareTo(b.quiz.closesAt);
      });
    final inProgress = all.where((p) => p.inProgress != null && !p.inProgress!.isExpired(now)).firstOrNull;
    final graded = all.where((p) => p.best != null);
    final average = graded.isEmpty
        ? null
        : graded.map((p) => percentOf(p.best!.score ?? 0, p.quiz.totalPoints)).reduce((a, b) => a + b) ~/ graded.length;

    return [
      SliverToBoxAdapter(
        child: Row(
          children: [
            Expanded(
              child: QuizStatTile(
                icon: Icons.play_circle_outline_rounded,
                label: 'quizzes.stat_available'.tr(),
                value: '${all.where((p) => p.availability(now) == QuizAvailability.available).length}',
              ),
            ),
            horizontalSpace(10),
            Expanded(
              child: QuizStatTile(
                icon: Icons.task_alt_rounded,
                label: 'quizzes.stat_completed'.tr(),
                value: '${all.where((p) => p.availability(now) == QuizAvailability.completed).length}',
              ),
            ),
            horizontalSpace(10),
            Expanded(
              child: QuizStatTile(
                icon: Icons.insights_rounded,
                label: 'quizzes.stat_average'.tr(),
                value: average == null ? '–' : '$average%',
              ),
            ),
          ],
        ).fadeInSlideUp(),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 14)),
      if (inProgress != null) ...[
        SliverToBoxAdapter(child: _ContinueCard(progress: inProgress)),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
      ],
      const SliverToBoxAdapter(child: _LeaderboardRow()),
      const SliverToBoxAdapter(child: SizedBox(height: 18)),
      SliverToBoxAdapter(child: _FilterChips(selected: filter)),
      const SliverToBoxAdapter(child: SizedBox(height: 14)),
      if (visible.isEmpty)
        SliverToBoxAdapter(
          child: EmptyView(message: 'quizzes.empty_filter'.tr(), icon: Icons.filter_alt_off_outlined),
        )
      else
        SliverList.separated(
          itemCount: visible.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) => QuizCard(
            progress: visible[index],
            now: now,
          ).fadeInSlideUp(delay: AppAnimations.staggerDelay * (index.clamp(0, 8))),
        ),
    ];
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.progress});

  final QuizProgress progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final attempt = progress.inProgress!;
    final total = progress.quiz.questionCount;
    final answered = attempt.answers.length;

    return AppCard(
      padding: const EdgeInsets.all(16),
      color: colorScheme.primary.withValues(alpha: .12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('quizzes.continue'.tr(), style: AppTextStyles.font12SemiBold.copyWith(color: colorScheme.primary)),
          verticalSpace(4),
          Text(context.bidi(progress.quiz.title), style: AppTextStyles.font18ExtraBold),
          verticalSpace(10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : answered / total,
              minHeight: 8,
              backgroundColor: colorScheme.surface,
            ),
          ),
          verticalSpace(6),
          Text(
            'quizzes.answered_of'.tr(args: ['$answered', '$total']),
            style: AppTextStyles.font12Medium.secondary(context),
          ),
          verticalSpace(12),
          PrimaryButton(
            label: 'quizzes.resume'.tr(),
            icon: Icons.play_arrow_rounded,
            height: 46,
            onPressed: () => context.push(StudentRoutes.takeQuiz(progress.quiz.id)),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow();

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.tertiary;

    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 16,
      color: gold.withValues(alpha: .12),
      onTap: () => context.push(StudentRoutes.leaderboard),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: gold, size: 26),
          horizontalSpace(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('quizzes.leaderboard'.tr(), style: AppTextStyles.font14ExtraBold),
                Text('quizzes.leaderboard_hint'.tr(), style: AppTextStyles.font12Normal.secondary(context)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.selected});

  final QuizAvailability? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.read(quizFilterProvider.notifier);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(label: Text('quizzes.all'.tr()), selected: selected == null, onSelected: (_) => filter.select(null)),
        for (final availability in QuizAvailability.values)
          ChoiceChip(
            label: Text(availability.label),
            selected: selected == availability,
            onSelected: (_) => filter.select(availability),
          ),
      ],
    );
  }
}
