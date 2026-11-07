import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/widgets/hero_card.dart';
import 'package:cairo_coding_app/core/widgets/section_header.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/student/home/widgets/due_quiz_card.dart';
import 'package:cairo_coding_app/student/home/widgets/home_header.dart';
import 'package:cairo_coding_app/student/home/widgets/next_session_card.dart';
import 'package:cairo_coding_app/student/home/widgets/progress_section.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_providers.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_summary.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:cairo_coding_app/student/student_routes.dart';
import 'package:cairo_coding_app/student/widgets/recording_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingSessionsProvider);
    final next = ref.watch(nextSessionProvider);
    final groups = ref.watch(groupsByIdProvider);
    final latestRecording = ref.watch(studentRecordingsProvider.select((value) => value.value?.firstOrNull));
    final dueQuiz = ref.watch(dueQuizProvider);
    final now = ref.watch(minuteTickerProvider).value ?? ref.watch(clockProvider)();

    Future<void> refresh() async {
      ref.invalidate(studentSessionsProvider);
      ref.invalidate(studentRecordingsProvider);
      ref.invalidate(studentQuizzesProvider);
      await ref.read(studentSessionsProvider.future);
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: refresh,
        child: switch (upcoming) {
          AsyncError(:final error) => ErrorView(message: error.toString(), onRetry: refresh),
          AsyncData() => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              const HomeHeader(),
              verticalSpace(22),
              if (next.value case final ClassSession session)
                NextSessionCard(session: session, group: groups[session.groupId])
              else
                HeroCard(
                  child: EmptyView(message: 'home.no_upcoming'.tr(), icon: Icons.event_available_outlined),
                ),
              verticalSpace(24),
              const ProgressSection(),
              if (dueQuiz != null) ...[
                verticalSpace(20),
                SectionHeader(
                  title: 'home.due_soon'.tr(),
                  actionLabel: 'home.all_quizzes'.tr(),
                  onAction: () => context.go(StudentRoutes.quizzes),
                ),
                verticalSpace(4),
                DueQuizCard(progress: dueQuiz, now: now),
              ],
              if (latestRecording != null) ...[
                verticalSpace(20),
                SectionHeader(
                  title: 'home.latest_recording'.tr(),
                  actionLabel: 'home.all_recordings'.tr(),
                  onAction: () => context.go(StudentRoutes.recordings),
                ),
                verticalSpace(4),
                RecordingTile(recording: latestRecording, groupName: groups[latestRecording.groupId]?.name),
              ],
            ].animateList(),
          ),
          _ => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: const [SkeletonList(count: 1, itemHeight: 380), SkeletonList(count: 3)],
          ),
        },
      ),
    );
  }
}
