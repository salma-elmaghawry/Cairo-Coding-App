import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/data/models/quiz_board.dart';

/// Quiz averages from the groups' leaderboards, which hold each student's first graded attempt.
class QuizAverages {
  const QuizAverages._();

  static double? _ratio(BoardEntry entry, Quiz? quiz) =>
      quiz == null || quiz.totalPoints <= 0 ? null : entry.score / quiz.totalPoints;

  /// The mean score of every entry on [boards], from 0 to 1; null when nobody has a result.
  static double? group(Iterable<QuizBoard> boards, Map<String, Quiz> quizzes) {
    final ratios = [
      for (final board in boards)
        for (final entry in board.entries) ?_ratio(entry, quizzes[board.quizId]),
    ];
    return ratios.isEmpty ? null : ratios.reduce((a, b) => a + b) / ratios.length;
  }

  /// The mean score of [uid]'s entries; null when they have no result yet.
  static double? student(String uid, Iterable<QuizBoard> boards, Map<String, Quiz> quizzes) {
    final ratios = [
      for (final board in boards)
        for (final entry in board.entries)
          if (entry.uid == uid) ?_ratio(entry, quizzes[board.quizId]),
    ];
    return ratios.isEmpty ? null : ratios.reduce((a, b) => a + b) / ratios.length;
  }

  /// How many results [boards] hold in all.
  static int submissions(Iterable<QuizBoard> boards) => boards.fold(0, (sum, board) => sum + board.entries.length);
}
