import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/widgets/filter_pill.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/services/quiz_progress.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_providers.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_summary.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/continue_quiz_card.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/leaderboard_row.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/quiz_card.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/quiz_labels.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/quiz_performance_card.dart';
import 'package:cairo_coding_app/student/widgets/tab_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        AsyncData(:final value) => _content(ref, value, filter, now),
        _ => const [SliverToBoxAdapter(child: SkeletonList(count: 4, itemHeight: 160))],
      },
    );
  }

  List<Widget> _content(WidgetRef ref, List<QuizProgress> all, QuizAvailability? filter, DateTime now) {
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
    final counts = {
      for (final availability in QuizAvailability.values)
        availability: all.where((p) => p.availability(now) == availability).length,
    };
    final select = ref.read(quizFilterProvider.notifier).select;

    return [
      SliverToBoxAdapter(child: QuizPerformanceCard(summary: QuizSummary.of(all, now)).fadeInSlideUp()),
      const SliverToBoxAdapter(child: SizedBox(height: 14)),
      if (inProgress != null) ...[
        SliverToBoxAdapter(child: ContinueQuizCard(progress: inProgress)),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
      ],
      const SliverToBoxAdapter(child: LeaderboardRow()),
      const SliverToBoxAdapter(child: SizedBox(height: 20)),
      SliverToBoxAdapter(
        child: FilterPillBar(
          children: [
            FilterPill(
              label: 'quizzes.all'.tr(),
              count: all.length,
              selected: filter == null,
              onSelected: () => select(null),
            ),
            for (final availability in QuizAvailability.values)
              FilterPill(
                label: availability.label,
                count: counts[availability],
                selected: filter == availability,
                onSelected: () => select(availability),
              ),
          ],
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 16)),
      if (visible.isEmpty)
        SliverToBoxAdapter(
          child: EmptyView(message: 'quizzes.empty_filter'.tr(), icon: Icons.filter_alt_off_outlined),
        )
      else
        SliverList.separated(
          itemCount: visible.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => QuizCard(
            progress: visible[index],
            now: now,
          ).fadeInSlideUp(delay: AppAnimations.staggerDelay * (index.clamp(0, 8))),
        ),
    ];
  }
}
