import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/data/models/quiz_attempt.dart';
import 'package:cairo_coding_app/data/models/quiz_question.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminQuizzesProvider = StreamProvider<List<Quiz>>((ref) => ref.watch(quizRepositoryProvider).watchQuizzes());

class QuizzesView {
  const QuizzesView({this.query = '', this.status});

  final String query;

  /// Only quizzes with this status; null shows all of them.
  final QuizStatus? status;
}

final quizzesViewProvider = NotifierProvider<QuizzesViewNotifier, QuizzesView>(QuizzesViewNotifier.new);

class QuizzesViewNotifier extends Notifier<QuizzesView> {
  @override
  QuizzesView build() => const QuizzesView();

  void search(String query) => state = QuizzesView(query: query.trim().toLowerCase(), status: state.status);

  void filterStatus(QuizStatus? status) => state = QuizzesView(query: state.query, status: status);
}

final visibleQuizzesProvider = Provider<AsyncValue<List<Quiz>>>((ref) {
  final view = ref.watch(quizzesViewProvider);
  return ref
      .watch(adminQuizzesProvider)
      .whenData(
        (quizzes) => quizzes
            .where((quiz) => view.status == null || quiz.status == view.status)
            .where((quiz) => '${quiz.title} ${quiz.description}'.toLowerCase().contains(view.query))
            .toList(),
      );
});

final adminQuizProvider = Provider.family<AsyncValue<Quiz?>, String>(
  (ref, quizId) =>
      ref.watch(adminQuizzesProvider).whenData((quizzes) => quizzes.where((q) => q.id == quizId).firstOrNull),
);

final quizContentProvider = FutureProvider.autoDispose.family<QuizContent, String>((ref, quizId) async {
  final result = await ref.watch(quizRepositoryProvider).getContent(quizId);
  return switch (result) {
    Ok(:final value) => value,
    Err<QuizContent>(:final failure) => throw failure,
  };
}, retry: (_, _) => null);

/// Once a student has taken a quiz, its questions and answers can't change, or the saved scores would stop being true.
final quizHasAttemptsProvider = FutureProvider.autoDispose.family<bool, String>((ref, quizId) async {
  final result = await ref.watch(quizRepositoryProvider).hasAttempts(quizId);
  return switch (result) {
    Ok(:final value) => value,
    Err<bool>(:final failure) => throw failure,
  };
}, retry: (_, _) => null);

final quizAttemptsProvider = StreamProvider.autoDispose.family<List<QuizAttempt>, String>(
  (ref, quizId) => ref.watch(quizRepositoryProvider).watchAttemptsForQuiz(quizId),
);

final quizStudentsProvider = StreamProvider.autoDispose.family<List<Student>, String>((ref, quizId) {
  final quiz = ref.watch(adminQuizProvider(quizId)).value;
  if (quiz == null) return const Stream.empty();
  return ref.watch(academyRepositoryProvider).watchStudentsOf(quiz.groupIds);
});

/// True while the builder has changes that aren't saved, so leaving the page can ask first.
final quizBuilderDirtyProvider = NotifierProvider<QuizBuilderDirty, bool>(QuizBuilderDirty.new);

class QuizBuilderDirty extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool dirty) {
    if (state != dirty) state = dirty;
  }
}
