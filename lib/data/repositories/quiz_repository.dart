import 'dart:async';

import 'package:cairo_coding_app/core/error_handling/error_mapper.dart';
import 'package:cairo_coding_app/core/error_handling/failures.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/data/models/quiz_attempt.dart';
import 'package:cairo_coding_app/data/models/quiz_board.dart';
import 'package:cairo_coding_app/data/models/quiz_question.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:cairo_coding_app/data/services/quiz_validator.dart';
import 'package:cairo_coding_app/data/sources/quiz_source.dart';
import 'package:easy_localization/easy_localization.dart';

class QuizRepository {
  QuizRepository(this._source);

  final QuizSource _source;

  /// Firestore queues writes while offline and their futures wait, so anything the student is watching gives up
  /// here and offers a retry. The queued write still goes through once the phone is back online.
  static const Duration _writeTimeout = Duration(seconds: 12);

  final Map<String, Future<Result<QuizAttempt>>> _finishing = {};

  Stream<List<Quiz>> watchPublishedQuizzes(List<String> groupIds) => ErrorMapper.mapStream(
    _source
        .watchPublishedQuizzes(groupIds)
        .map(
          (list) =>
              {for (final quiz in list) quiz.id: quiz}.values.toList()..sort((a, b) => b.opensAt.compareTo(a.opensAt)),
        ),
  );

  Stream<List<QuizAttempt>> watchAttemptsOf(String uid) => ErrorMapper.mapStream(_source.watchAttemptsOf(uid));

  /// Checks a fresh copy of the quiz first: that needs the network, so a start can't sit in the offline queue
  /// and begin the timer later, and it catches a quiz the list on screen has stale.
  Future<Result<QuizAttempt>> startAttempt(Quiz quiz, Student student, {required int number}) => Result.guard(() async {
    final groupIds = quiz.groupIds.where(student.groupIds.contains).toList();
    if (groupIds.isEmpty) throw NotAuthorizedFailure('quizzes.errors.not_available'.tr());
    final fresh = await _source.getPublishedQuiz(groupIds.first, quiz.id);
    if (fresh == null) throw NotAuthorizedFailure('quizzes.errors.not_available'.tr());
    final now = DateTime.now();
    return _source
        .startAttempt(
          QuizAttempt(
            quizId: fresh.id,
            uid: student.uid,
            number: number,
            studentName: student.name,
            groupIds: fresh.groupIds.where(student.groupIds.contains).toList(),
            startedAt: now,
            lastAnswerAt: now,
            durationMin: fresh.durationMin,
            closesAt: fresh.closesAt,
            questionCount: fresh.questionCount,
          ),
        )
        .timeout(_writeTimeout);
  });

  Future<Result<List<QuizQuestion>>> getPaper(String quizId) => Result.guard(() => _source.getPaper(quizId));

  Future<Result<void>> saveAnswer(QuizAttempt attempt, String questionId, int option) =>
      Result.guard(() => _source.saveAnswer(attempt, questionId, option));

  /// Submits and grades an attempt, picking up from wherever it got to, so a retry or the next app open
  /// finishes the same attempt. Two calls for one attempt share the same work.
  Future<Result<QuizAttempt>> finishAttempt(String attemptId) =>
      _finishing[attemptId] ??= _finish(attemptId).whenComplete(() {
        _finishing.remove(attemptId);
      });

  Future<Result<QuizAttempt>> _finish(String attemptId) => Result.guard(() async {
    var attempt = await _source.getAttempt(attemptId);
    if (attempt.isInProgress) {
      await _source.submitAttempt(attemptId).timeout(_writeTimeout);
      attempt = await _source.getAttempt(attemptId);
    }
    if (attempt.isGraded) return attempt;
    final key = await _source.getKey(attempt.quizId);
    final grade = key.grade(attempt.answers);
    final graded = attempt.copyWith(status: AttemptStatus.graded, score: grade.score, correctCount: grade.correctCount);
    await _source.saveGrade(graded).timeout(_writeTimeout);
    return graded;
  });

  /// The questions with their answers, for reviewing a finished attempt.
  Future<Result<QuizContent>> getReview(String quizId) => Result.guard(() async {
    final results = await Future.wait([_source.getPaper(quizId), _source.getKey(quizId)]);
    return QuizContent(questions: results[0] as List<QuizQuestion>, key: results[1] as QuizAnswerKey);
  });

  Stream<QuizBoard> watchBoard(String groupId, String quizId) =>
      ErrorMapper.mapStream(_source.watchBoard(groupId, quizId));

  Stream<List<QuizBoard>> watchBoards(String groupId) => ErrorMapper.mapStream(_source.watchBoards(groupId));

  Stream<List<Quiz>> watchQuizzes() => ErrorMapper.mapStream(
    _source.watchQuizzes().map((list) => [...list]..sort((a, b) => b.opensAt.compareTo(a.opensAt))),
  );

  Stream<List<QuizAttempt>> watchAttemptsForQuiz(String quizId) =>
      ErrorMapper.mapStream(_source.watchAttemptsForQuiz(quizId));

  Future<Result<QuizContent>> getContent(String quizId) => Result.guard(() => _source.getContent(quizId));

  Future<Result<bool>> hasAttempts(String quizId) => Result.guard(() => _source.hasAttempts(quizId));

  /// [content] is left out when the questions are locked because students have already taken the quiz.
  Future<Result<Quiz>> saveQuiz(Quiz quiz, {QuizContent? content, List<String> previousGroupIds = const []}) =>
      Result.guard(() {
        final cleaned = content == null ? null : _clean(content);
        return _source.saveQuiz(
          quiz.copyWith(
            title: quiz.title.trim(),
            description: quiz.description.trim(),
            coverUrl: quiz.coverUrl.trim(),
            questionCount: cleaned?.questions.length,
            totalPoints: cleaned?.totalPoints,
          ),
          content: cleaned,
          removedGroupIds: previousGroupIds.where((id) => !quiz.groupIds.contains(id)).toList(),
        );
      });

  QuizContent _clean(QuizContent content) => QuizContent(
    key: content.key,
    questions: [
      for (final question in content.questions)
        QuizQuestion(
          id: question.id,
          text: question.text.trim(),
          imageUrl: question.imageUrl.trim(),
          options: question.options.map((option) => option.trim()).toList(),
          points: question.points,
          timeLimitSec: question.timeLimitSec,
        ),
    ],
  );

  /// Publishing checks the saved questions, so a quiz with a missing answer can't reach students from the list.
  Future<Result<void>> setPublished(Quiz quiz, bool published) => Result.guard(() async {
    if (published) {
      final content = await _source.getContent(quiz.id);
      if (findQuizProblems(quiz, content).isNotEmpty) {
        throw ValidationFailure('admin.quizzes.not_ready'.tr());
      }
    }
    await _source.saveQuiz(quiz.copyWith(status: published ? QuizStatus.published : QuizStatus.draft));
  });

  /// A copy starts as a draft with the same questions and no results.
  Future<Result<Quiz>> duplicateQuiz(Quiz quiz, {required String title}) => Result.guard(() async {
    final content = await _source.getContent(quiz.id);
    return _source.saveQuiz(
      quiz.copyWith(id: '', title: title, status: QuizStatus.draft),
      content: content,
    );
  });

  Future<Result<void>> deleteQuiz(Quiz quiz) => Result.guard(() => _source.deleteQuiz(quiz));
}
