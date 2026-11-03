import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/data/models/quiz_attempt.dart';
import 'package:cairo_coding_app/data/models/quiz_question.dart';
import 'package:cairo_coding_app/data/models/student.dart';

enum StudentQuizStatus { notStarted, inProgress, completed }

/// One student's row in a quiz's results. Their first attempt is the one that counts, as on the leaderboard.
class StudentQuizResult {
  const StudentQuizResult({
    required this.uid,
    required this.name,
    required this.groupIds,
    required this.status,
    this.score,
    this.correctCount,
    this.answeredCount,
    this.timeTaken,
    this.bestScore,
    this.attemptCount = 0,
  });

  final String uid;
  final String name;
  final List<String> groupIds;
  final StudentQuizStatus status;
  final int? score;
  final int? correctCount;
  final int? answeredCount;
  final Duration? timeTaken;
  final int? bestScore;
  final int attemptCount;
}

class QuestionStats {
  const QuestionStats({
    required this.question,
    required this.correctOption,
    required this.optionCounts,
    required this.skipped,
  });

  final QuizQuestion question;
  final int? correctOption;

  /// How many students picked each option, in option order.
  final List<int> optionCounts;

  /// Students who finished without answering this one.
  final int skipped;

  int get answered => optionCounts.fold(0, (sum, count) => sum + count);

  int get correct => correctOption == null ? 0 : optionCounts[correctOption!];

  /// Share of everyone who reached the end, counting a skipped question as not correct.
  double get correctRate {
    final total = answered + skipped;
    return total == 0 ? 0 : correct / total;
  }

  /// The wrong option most students fell for, or null when nobody picked a wrong one.
  int? get topWrongOption {
    int? top;
    for (var option = 0; option < optionCounts.length; option++) {
      if (option == correctOption || optionCounts[option] == 0) continue;
      if (top == null || optionCounts[option] > optionCounts[top]) top = option;
    }
    return top;
  }
}

class QuizAnalytics {
  const QuizAnalytics({
    required this.assigned,
    required this.completed,
    required this.results,
    required this.questions,
    required this.totalPoints,
    this.average,
    this.highest,
    this.lowest,
  });

  /// Scores come from the key instead of the stored score, so an attempt that was submitted but never
  /// graded (the app was closed in between) still counts.
  factory QuizAnalytics.from({
    required Quiz quiz,
    required QuizContent content,
    required List<Student> students,
    required List<QuizAttempt> attempts,
    String? groupId,
  }) {
    final attemptsByStudent = <String, List<QuizAttempt>>{};
    for (final attempt in attempts) {
      attemptsByStudent.putIfAbsent(attempt.uid, () => []).add(attempt);
    }
    for (final list in attemptsByStudent.values) {
      list.sort((a, b) => a.number.compareTo(b.number));
    }

    final targetGroups = groupId == null ? quiz.groupIds : [groupId];
    bool isAssigned(Student s) => s.active && s.groupIds.any(targetGroups.contains);
    bool countedIn(QuizAttempt a) => groupId == null || a.groupIds.contains(groupId);

    final results = <StudentQuizResult>[];
    final seen = <String>{};
    for (final student in students.where(isAssigned)) {
      seen.add(student.uid);
      results.add(_resultOf(student.uid, student.name, student.groupIds, attemptsByStudent[student.uid], content.key));
    }
    // Someone who left the group or was deactivated after taking the quiz still has a result.
    for (final MapEntry(key: uid, value: list) in attemptsByStudent.entries) {
      if (seen.contains(uid) || !countedIn(list.first)) continue;
      results.add(_resultOf(uid, list.first.studentName, list.first.groupIds, list, content.key));
    }

    final scores = [
      for (final result in results)
        if (result.status == StudentQuizStatus.completed) result.score ?? 0,
    ];
    final firstAttempts = [
      for (final result in results)
        if (result.status == StudentQuizStatus.completed) attemptsByStudent[result.uid]!.first,
    ];

    results.sort((a, b) {
      final byStatus = b.status.index.compareTo(a.status.index);
      if (byStatus != 0) return byStatus;
      final byScore = (b.score ?? -1).compareTo(a.score ?? -1);
      return byScore != 0 ? byScore : a.name.compareTo(b.name);
    });

    return QuizAnalytics(
      assigned: results.length,
      completed: scores.length,
      results: results,
      totalPoints: content.totalPoints,
      questions: [for (final question in content.questions) _statsOf(question, content.key, firstAttempts)],
      average: scores.isEmpty ? null : scores.reduce((a, b) => a + b) / scores.length,
      highest: scores.isEmpty ? null : scores.reduce((a, b) => a > b ? a : b),
      lowest: scores.isEmpty ? null : scores.reduce((a, b) => a < b ? a : b),
    );
  }

  static StudentQuizResult _resultOf(
    String uid,
    String name,
    List<String> groupIds,
    List<QuizAttempt>? attempts,
    QuizAnswerKey key,
  ) {
    final first = attempts?.firstOrNull;
    if (first == null || attempts == null) {
      return StudentQuizResult(uid: uid, name: name, groupIds: groupIds, status: StudentQuizStatus.notStarted);
    }
    if (first.isInProgress) {
      return StudentQuizResult(
        uid: uid,
        name: name,
        groupIds: groupIds,
        status: StudentQuizStatus.inProgress,
        attemptCount: attempts.length,
      );
    }
    final grade = key.grade(first.answers);
    final bestScore = attempts
        .where((a) => !a.isInProgress)
        .map((a) => key.grade(a.answers).score)
        .reduce((a, b) => a > b ? a : b);
    return StudentQuizResult(
      uid: uid,
      name: name,
      groupIds: groupIds,
      status: StudentQuizStatus.completed,
      score: grade.score,
      correctCount: grade.correctCount,
      answeredCount: first.answeredCount,
      timeTaken: first.timeTaken,
      bestScore: bestScore,
      attemptCount: attempts.length,
    );
  }

  static QuestionStats _statsOf(QuizQuestion question, QuizAnswerKey key, List<QuizAttempt> attempts) {
    final counts = List<int>.filled(question.options.length, 0);
    var skipped = 0;
    for (final attempt in attempts) {
      final option = attempt.answers[question.id];
      if (option == null || option < 0 || option >= counts.length) {
        skipped++;
      } else {
        counts[option]++;
      }
    }
    return QuestionStats(
      question: question,
      correctOption: key.correct[question.id],
      optionCounts: counts,
      skipped: skipped,
    );
  }

  final int assigned;
  final int completed;
  final List<StudentQuizResult> results;
  final List<QuestionStats> questions;
  final int totalPoints;
  final double? average;
  final int? highest;
  final int? lowest;

  double get completionRate => assigned == 0 ? 0 : completed / assigned;
}
