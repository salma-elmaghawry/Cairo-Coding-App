import 'package:cairo_coding_app/core/error_handling/app_exceptions.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/data/models/quiz_attempt.dart';
import 'package:cairo_coding_app/data/models/quiz_board.dart';
import 'package:cairo_coding_app/data/models/quiz_question.dart';
import 'package:cairo_coding_app/data/sources/quiz_source.dart';

/// Refuses what `firestore.rules` refuses, so tests see the same behaviour as the real backend.
class FakeQuizSource implements QuizSource {
  FakeQuizSource(this._store, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final FakeAcademyStore _store;
  final DateTime Function() _clock;

  static const Duration _grace = Duration(seconds: 30);

  Future<void> _latency() => Future<void>.delayed(const Duration(milliseconds: 150));

  Future<T> _write<T>(T Function() change) async {
    await _latency();
    final result = change();
    _store.notify();
    return result;
  }

  Quiz _quiz(String quizId) => _store.quizzes[quizId] ?? (throw const NotAuthorizedException());

  QuizAttempt _attempt(String attemptId) => _store.quizAttempts[attemptId] ?? (throw const NotAuthorizedException());

  bool _isFinished(QuizAttempt? attempt) => attempt != null && !attempt.isInProgress;

  @override
  Stream<List<Quiz>> watchPublishedQuizzes(List<String> groupIds) => _store.watch(
    () => _store.quizzes.values.where((q) => q.isPublished && q.groupIds.any(groupIds.contains)).toList(),
  );

  @override
  Future<Quiz?> getPublishedQuiz(String groupId, String quizId) async {
    await _latency();
    final quiz = _store.quizzes[quizId];
    return quiz != null && quiz.isPublished && quiz.groupIds.contains(groupId) ? quiz : null;
  }

  @override
  Stream<List<QuizAttempt>> watchAttemptsOf(String uid) =>
      _store.watch(() => _store.quizAttempts.values.where((a) => a.uid == uid).toList());

  @override
  Future<QuizAttempt> startAttempt(QuizAttempt attempt) => _write(() {
    final quiz = _quiz(attempt.quizId);
    final now = _clock();
    final student = _store.students[attempt.uid];
    final previous = _store.quizAttempts[QuizAttempt.idOf(attempt.quizId, attempt.uid, attempt.number - 1)];
    final allowed =
        !_store.quizAttempts.containsKey(attempt.id) &&
        attempt.number >= 1 &&
        attempt.number <= quiz.maxAttempts &&
        (attempt.number == 1 || _isFinished(previous)) &&
        quiz.isPublished &&
        quiz.isOpen(now) &&
        student != null &&
        student.active &&
        attempt.groupIds.isNotEmpty &&
        attempt.groupIds.every((id) => quiz.groupIds.contains(id) && student.groupIds.contains(id));
    if (!allowed) throw const NotAuthorizedException();
    final started = attempt.copyWith(startedAt: now, lastAnswerAt: now);
    _store.quizAttempts[attempt.id] = started;
    return started;
  });

  @override
  Future<List<QuizQuestion>> getPaper(String quizId) async {
    await _latency();
    final started = _store.quizAttempts.values.any((a) => a.quizId == quizId);
    if (!started) throw const NotAuthorizedException();
    return _store.quizContents[quizId]?.questions ?? const [];
  }

  @override
  Future<QuizAnswerKey> getKey(String quizId) async {
    await _latency();
    final submitted = _store.quizAttempts.values.any((a) => a.quizId == quizId && !a.isInProgress);
    if (!submitted) throw const NotAuthorizedException();
    return _store.quizContents[quizId]?.key ?? const QuizAnswerKey();
  }

  @override
  Future<void> saveAnswer(QuizAttempt attempt, String questionId, int option) => _write(() {
    final current = _attempt(attempt.id);
    final now = _clock();
    final inTime = now.isBefore(current.deadline.add(_grace));
    if (!current.isInProgress || current.answers.containsKey(questionId) || !inTime) {
      throw const NotAuthorizedException();
    }
    _store.quizAttempts[attempt.id] = current.copyWith(
      answers: {...current.answers, questionId: option},
      lastAnswerAt: now,
    );
  });

  @override
  Future<QuizAttempt> getAttempt(String attemptId) async {
    await _latency();
    return _attempt(attemptId);
  }

  @override
  Future<void> submitAttempt(String attemptId) => _write(() {
    final current = _attempt(attemptId);
    if (!current.isInProgress) throw const NotAuthorizedException();
    _store.quizAttempts[attemptId] = current.copyWith(status: AttemptStatus.submitted, submittedAt: _clock());
  });

  @override
  Future<void> saveGrade(QuizAttempt graded) => _write(() {
    final current = _attempt(graded.id);
    final grade = _store.quizContents[graded.quizId]?.key.grade(current.answers);
    final honest = grade?.score == graded.score && grade?.correctCount == graded.correctCount;
    if (current.status != AttemptStatus.submitted || !honest) throw const NotAuthorizedException();
    final saved = current.copyWith(
      status: AttemptStatus.graded,
      score: graded.score,
      correctCount: graded.correctCount,
    );
    _store.quizAttempts[graded.id] = saved;
    if (saved.number == 1) {
      for (final groupId in saved.groupIds) {
        _store.quizBoards.putIfAbsent(groupId, () => {}).putIfAbsent(saved.quizId, () => {})[saved.uid] =
            BoardEntry.fromAttempt(saved);
      }
    }
  });

  QuizBoard _board(String groupId, String quizId) => QuizBoard(
    groupId: groupId,
    quizId: quizId,
    entries: _store.quizBoards[groupId]?[quizId]?.values.toList() ?? const [],
  );

  @override
  Stream<QuizBoard> watchBoard(String groupId, String quizId) => _store.watch(() => _board(groupId, quizId));

  @override
  Stream<List<QuizBoard>> watchBoards(String groupId) => _store.watch(
    () => [for (final quizId in _store.quizBoards[groupId]?.keys ?? const <String>[]) _board(groupId, quizId)],
  );

  @override
  Stream<List<Quiz>> watchQuizzes() => _store.watch(() => _store.quizzes.values.toList());

  @override
  Future<QuizContent> getContent(String quizId) async {
    await _latency();
    return _store.quizContents[quizId] ?? const QuizContent();
  }

  @override
  Future<Quiz> saveQuiz(Quiz quiz, {QuizContent? content, List<String> removedGroupIds = const []}) => _write(() {
    final saved = quiz.id.isEmpty ? quiz.copyWith(id: _store.newId('quiz')) : quiz;
    _store.quizzes[saved.id] = saved;
    if (content != null) _store.quizContents[saved.id] = content;
    return saved;
  });

  @override
  Future<void> deleteQuiz(Quiz quiz) => _write(() {
    _store.quizzes.remove(quiz.id);
    _store.quizContents.remove(quiz.id);
    _store.quizAttempts.removeWhere((_, attempt) => attempt.quizId == quiz.id);
    for (final boards in _store.quizBoards.values) {
      boards.remove(quiz.id);
    }
  });

  @override
  Stream<List<QuizAttempt>> watchAttemptsForQuiz(String quizId) =>
      _store.watch(() => _store.quizAttempts.values.where((a) => a.quizId == quizId).toList());

  @override
  Future<bool> hasAttempts(String quizId) async {
    await _latency();
    return _store.quizAttempts.values.any((a) => a.quizId == quizId);
  }

  @override
  Stream<List<QuizAttempt>> watchRecentSubmissions(int limit) => _store.watch(
    () =>
        (_store.quizAttempts.values.where((a) => a.submittedAt != null).toList()
              ..sort((a, b) => b.submittedAt!.compareTo(a.submittedAt!)))
            .take(limit)
            .toList(),
  );
}
