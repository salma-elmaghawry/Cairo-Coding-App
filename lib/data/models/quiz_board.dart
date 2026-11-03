import 'package:cairo_coding_app/data/models/quiz_attempt.dart';
import 'package:equatable/equatable.dart';

/// One student's row on a group's leaderboard for one quiz, copied from their first graded attempt.
class BoardEntry extends Equatable {
  const BoardEntry({
    required this.uid,
    required this.name,
    required this.score,
    required this.correctCount,
    required this.durationMs,
  });

  factory BoardEntry.fromMap(String uid, Map<String, dynamic> map) => BoardEntry(
    uid: uid,
    name: map['name'] as String? ?? '',
    score: map['score'] as int? ?? 0,
    correctCount: map['correctCount'] as int? ?? 0,
    durationMs: map['durationMs'] as int? ?? 0,
  );

  factory BoardEntry.fromAttempt(QuizAttempt attempt) => BoardEntry(
    uid: attempt.uid,
    name: attempt.studentName,
    score: attempt.score ?? 0,
    correctCount: attempt.correctCount ?? 0,
    durationMs: attempt.timeTaken.inMilliseconds,
  );

  final String uid;
  final String name;
  final int score;
  final int correctCount;
  final int durationMs;

  Map<String, dynamic> toMap() => {
    'name': name,
    'score': score,
    'correctCount': correctCount,
    'durationMs': durationMs,
  };

  @override
  List<Object> get props => [uid, name, score, correctCount, durationMs];
}

/// A group's ranking for one quiz. One document per group and quiz keeps a leaderboard to a few reads.
class QuizBoard extends Equatable {
  const QuizBoard({required this.groupId, required this.quizId, this.entries = const []});

  factory QuizBoard.fromMap(String groupId, String quizId, Map<String, dynamic> map) => QuizBoard(
    groupId: groupId,
    quizId: quizId,
    entries: [
      for (final MapEntry(key: uid, :value) in map.entries)
        if (value is Map) BoardEntry.fromMap(uid, Map<String, dynamic>.from(value)),
    ],
  );

  final String groupId;
  final String quizId;
  final List<BoardEntry> entries;

  @override
  List<Object> get props => [groupId, quizId, entries];
}
