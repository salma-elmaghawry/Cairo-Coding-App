import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/data/models/quiz_attempt.dart';

enum QuizAvailability { available, upcoming, completed, expired }

/// One student's standing on one quiz.
class QuizProgress {
  QuizProgress({required this.quiz, required Iterable<QuizAttempt> attempts})
    : attempts = attempts.where((a) => a.quizId == quiz.id).toList()..sort((a, b) => a.number.compareTo(b.number));

  final Quiz quiz;

  /// Oldest first.
  final List<QuizAttempt> attempts;

  QuizAttempt? get inProgress => attempts.where((a) => a.isInProgress).firstOrNull;

  /// The attempt that counts on the leaderboard.
  QuizAttempt? get firstAttempt => attempts.firstOrNull;

  List<QuizAttempt> get finished => attempts.where((a) => !a.isInProgress).toList();

  QuizAttempt? get latestFinished => finished.lastOrNull;

  QuizAttempt? get best {
    QuizAttempt? best;
    for (final attempt in attempts.where((a) => a.isGraded)) {
      if (best == null || (attempt.score ?? 0) > (best.score ?? 0)) best = attempt;
    }
    return best;
  }

  int get attemptsLeft {
    final left = quiz.maxAttempts - attempts.length;
    return left < 0 ? 0 : left;
  }

  bool canStartNew(DateTime now) => quiz.isOpen(now) && inProgress == null && attemptsLeft > 0;

  /// In-progress attempts count as available, so the student can go back and finish them.
  QuizAvailability availability(DateTime now) {
    if (finished.isNotEmpty) return QuizAvailability.completed;
    if (inProgress case final attempt? when !attempt.isExpired(now)) return QuizAvailability.available;
    if (!quiz.hasOpened(now)) return QuizAvailability.upcoming;
    if (quiz.hasClosed(now)) return QuizAvailability.expired;
    return QuizAvailability.available;
  }
}
