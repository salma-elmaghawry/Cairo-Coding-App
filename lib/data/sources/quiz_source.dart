import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/data/models/quiz_attempt.dart';
import 'package:cairo_coding_app/data/models/quiz_board.dart';
import 'package:cairo_coding_app/data/models/quiz_question.dart';

abstract class QuizSource {
  // What students see.

  /// Published quizzes of each group, without their questions. A quiz in two of the groups appears twice.
  Stream<List<Quiz>> watchPublishedQuizzes(List<String> groupIds);

  /// A fresh copy of a published quiz from the server, or null if it's gone. Fails when offline.
  Future<Quiz?> getPublishedQuiz(String groupId, String quizId);

  Stream<List<QuizAttempt>> watchAttemptsOf(String uid);

  /// Creates the attempt and returns it with the server's start time.
  Future<QuizAttempt> startAttempt(QuizAttempt attempt);

  Future<List<QuizQuestion>> getPaper(String quizId);

  Future<QuizAnswerKey> getKey(String quizId);

  Future<void> saveAnswer(QuizAttempt attempt, String questionId, int option);

  /// The attempt as the server has it.
  Future<QuizAttempt> getAttempt(String attemptId);

  Future<void> submitAttempt(String attemptId);

  /// Saves the grade and, for a first attempt, its leaderboard rows, all together.
  Future<void> saveGrade(QuizAttempt graded);

  Stream<QuizBoard> watchBoard(String groupId, String quizId);

  Stream<List<QuizBoard>> watchBoards(String groupId);

  // What admins manage.

  Stream<List<Quiz>> watchQuizzes();

  Future<QuizContent> getContent(String quizId);

  /// Saves the quiz, and [content] when given, and updates the copies students read: one per group while
  /// published, none otherwise, and none left behind in [removedGroupIds].
  Future<Quiz> saveQuiz(Quiz quiz, {QuizContent? content, List<String> removedGroupIds = const []});

  Future<void> deleteQuiz(Quiz quiz);

  Stream<List<QuizAttempt>> watchAttemptsForQuiz(String quizId);

  Future<bool> hasAttempts(String quizId);

  /// The latest submitted attempts across every quiz, newest first, for the dashboard's activity.
  Stream<List<QuizAttempt>> watchRecentSubmissions(int limit);
}
