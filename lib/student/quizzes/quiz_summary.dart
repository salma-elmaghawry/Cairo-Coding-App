import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/data/services/leaderboard.dart';
import 'package:cairo_coding_app/data/services/quiz_progress.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_format.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_providers.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The numbers at the top of the quizzes tab and on home.
class QuizSummary {
  const QuizSummary({required this.open, required this.done, required this.points, this.average});

  factory QuizSummary.of(List<QuizProgress> all, DateTime now) {
    final graded = all.where((p) => p.best != null).toList();
    return QuizSummary(
      open: all.where((p) => p.availability(now) == QuizAvailability.available).length,
      done: all.where((p) => p.availability(now) == QuizAvailability.completed).length,
      points: graded.fold(0, (sum, p) => sum + (p.best!.score ?? 0)),
      average: graded.isEmpty
          ? null
          : graded.map((p) => percentOf(p.best!.score ?? 0, p.quiz.totalPoints)).reduce((a, b) => a + b) ~/
                graded.length,
    );
  }

  final int open;
  final int done;

  /// Best scores added up.
  final int points;

  /// Mean percentage of the best attempts; null before any quiz is graded.
  final int? average;
}

final quizSummaryProvider = Provider.autoDispose<QuizSummary?>((ref) {
  final all = ref.watch(quizProgressListProvider).value;
  if (all == null) return null;
  final now = ref.watch(minuteTickerProvider).value ?? ref.watch(clockProvider)();
  return QuizSummary.of(all, now);
});

/// The quiz that can be taken now and closes soonest.
final dueQuizProvider = Provider.autoDispose<QuizProgress?>((ref) {
  final all = ref.watch(quizProgressListProvider).value ?? const <QuizProgress>[];
  final now = ref.watch(minuteTickerProvider).value ?? ref.watch(clockProvider)();
  final open = all.where((p) => p.availability(now) == QuizAvailability.available).toList()
    ..sort((a, b) => a.quiz.closesAt.compareTo(b.quiz.closesAt));
  return open.firstOrNull;
});

/// The overall ranking of the student's first group, the one the leaderboard opens on.
final myGroupRankingProvider = Provider.autoDispose<({String groupId, List<RankedStudent> ranked})?>((ref) {
  final groupId = ref.watch(studentGroupIdsProvider).firstOrNull;
  if (groupId == null) return null;
  return (groupId: groupId, ranked: ref.watch(overallLeaderboardProvider(groupId)).value ?? const []);
});

/// This student's place in [myGroupRankingProvider], once they're on the board.
final myRankProvider = Provider.autoDispose<RankedStudent?>((ref) {
  final uid = ref.watch(currentUserProvider.select((user) => user?.uid));
  final ranked = ref.watch(myGroupRankingProvider)?.ranked ?? const [];
  return ranked.where((student) => student.uid == uid).firstOrNull;
});
