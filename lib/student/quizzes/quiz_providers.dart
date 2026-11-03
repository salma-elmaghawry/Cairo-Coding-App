import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/data/models/quiz_attempt.dart';
import 'package:cairo_coding_app/data/models/quiz_board.dart';
import 'package:cairo_coding_app/data/models/quiz_question.dart';
import 'package:cairo_coding_app/data/services/leaderboard.dart';
import 'package:cairo_coding_app/data/services/quiz_progress.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final studentQuizzesProvider = StreamProvider<List<Quiz>>((ref) {
  final ids = ref.watch(studentGroupIdsProvider);
  return ref.watch(quizRepositoryProvider).watchPublishedQuizzes(ids);
});

final myAttemptsProvider = StreamProvider<List<QuizAttempt>>((ref) {
  final uid = ref.watch(currentUserProvider.select((user) => user?.uid));
  if (uid == null) return Stream.value(const []);
  return ref.watch(quizRepositoryProvider).watchAttemptsOf(uid);
});

final quizProgressListProvider = Provider<AsyncValue<List<QuizProgress>>>((ref) {
  final attempts = ref.watch(myAttemptsProvider);
  if (attempts case AsyncError(:final error, :final stackTrace)) return AsyncError(error, stackTrace);
  final quizzes = ref.watch(studentQuizzesProvider);
  if (!attempts.hasValue && !quizzes.hasError) return const AsyncLoading();
  return quizzes.whenData((list) => [for (final quiz in list) QuizProgress(quiz: quiz, attempts: attempts.value!)]);
});

final quizProgressProvider = Provider.family<AsyncValue<QuizProgress?>, String>(
  (ref, quizId) => ref
      .watch(quizProgressListProvider)
      .whenData((list) => list.where((progress) => progress.quiz.id == quizId).firstOrNull),
);

final quizFilterProvider = NotifierProvider<QuizFilter, QuizAvailability?>(QuizFilter.new);

class QuizFilter extends Notifier<QuizAvailability?> {
  @override
  QuizAvailability? build() => null;

  void select(QuizAvailability? availability) => state = availability;
}

/// Finishes attempts the app couldn't finish itself: it was closed before submitting and the time ran out, or
/// it was closed between submitting and grading. Each attempt gets one try per app run.
final quizRecoveryProvider = Provider<void>((ref) {
  final tried = <String>{};
  final repository = ref.watch(quizRepositoryProvider);
  final clock = ref.watch(clockProvider);

  void recover(List<QuizAttempt> attempts) {
    final now = clock().add(ref.read(quizClockSkewProvider));
    for (final attempt in attempts) {
      final stuck = attempt.status == AttemptStatus.submitted || attempt.isExpired(now);
      if (stuck && tried.add(attempt.id)) repository.finishAttempt(attempt.id);
    }
  }

  ref.listen(myAttemptsProvider, (_, next) => recover(next.value ?? const []), fireImmediately: true);
});

/// How far the server's clock is from this phone's, measured when an attempt starts, so a phone
/// with the wrong time doesn't show a timer that ends early or late.
final quizClockSkewProvider = NotifierProvider<QuizClockSkew, Duration>(QuizClockSkew.new);

class QuizClockSkew extends Notifier<Duration> {
  @override
  Duration build() => Duration.zero;

  void measure(DateTime serverTime) => state = serverTime.difference(ref.read(clockProvider)());
}

final quizNowProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  final clock = ref.watch(clockProvider);
  final skew = ref.watch(quizClockSkewProvider);
  yield clock().add(skew);
  yield* Stream.periodic(const Duration(seconds: 1), (_) => clock().add(skew));
});

/// The group whose leaderboard a quiz counts on for this student.
String? rankingGroupOf(QuizAttempt? attempt, Quiz? quiz, List<String> studentGroupIds) {
  if (attempt?.groupIds.firstOrNull case final groupId?) return groupId;
  return quiz?.groupIds.where(studentGroupIds.contains).firstOrNull;
}

final quizBoardProvider = StreamProvider.autoDispose.family<QuizBoard, ({String groupId, String quizId})>(
  (ref, args) => ref.watch(quizRepositoryProvider).watchBoard(args.groupId, args.quizId),
);

final groupBoardsProvider = StreamProvider.autoDispose.family<List<QuizBoard>, String>(
  (ref, groupId) => ref.watch(quizRepositoryProvider).watchBoards(groupId),
);

/// Boards of quizzes students can still see, so an unpublished quiz stops counting towards the overall ranking.
final visibleBoardsProvider = Provider.autoDispose.family<AsyncValue<List<QuizBoard>>, String>((ref, groupId) {
  final published = {for (final quiz in ref.watch(studentQuizzesProvider).value ?? const <Quiz>[]) quiz.id};
  return ref
      .watch(groupBoardsProvider(groupId))
      .whenData((boards) => boards.where((board) => published.contains(board.quizId)).toList());
});

final overallLeaderboardProvider = Provider.autoDispose.family<AsyncValue<List<RankedStudent>>, String>(
  (ref, groupId) => ref.watch(visibleBoardsProvider(groupId)).whenData(Leaderboard.overall),
);

/// Questions and answers for reviewing an attempt once the quiz has closed.
final quizReviewProvider = FutureProvider.autoDispose.family<QuizContent, String>((ref, quizId) async {
  final result = await ref.watch(quizRepositoryProvider).getReview(quizId);
  return switch (result) {
    Ok(:final value) => value,
    Err<QuizContent>(:final failure) => throw failure,
  };
}, retry: (_, _) => null);
