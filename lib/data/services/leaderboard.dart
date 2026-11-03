import 'package:cairo_coding_app/data/models/quiz_board.dart';
import 'package:equatable/equatable.dart';

class RankedStudent extends Equatable {
  const RankedStudent({
    required this.rank,
    required this.uid,
    required this.name,
    required this.score,
    required this.durationMs,
    this.quizCount = 1,
  });

  final int rank;
  final String uid;
  final String name;
  final int score;
  final int durationMs;
  final int quizCount;

  @override
  List<Object> get props => [rank, uid, name, score, durationMs, quizCount];
}

class Leaderboard {
  /// Higher score first, then less time. Time compares in whole seconds, the same as it's shown: students who
  /// look tied are tied, and share a rank (1, 2, 2, 4). Names only keep the listing order stable.
  static List<RankedStudent> rank(Iterable<RankedStudent> students) {
    int seconds(RankedStudent student) => student.durationMs ~/ 1000;
    final sorted = students.toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        final byTime = seconds(a).compareTo(seconds(b));
        if (byTime != 0) return byTime;
        final byName = a.name.compareTo(b.name);
        return byName != 0 ? byName : a.uid.compareTo(b.uid);
      });

    final ranked = <RankedStudent>[];
    for (final (index, student) in sorted.indexed) {
      final previous = ranked.lastOrNull;
      final tied = previous != null && previous.score == student.score && seconds(previous) == seconds(student);
      ranked.add(
        RankedStudent(
          rank: tied ? previous.rank : index + 1,
          uid: student.uid,
          name: student.name,
          score: student.score,
          durationMs: student.durationMs,
          quizCount: student.quizCount,
        ),
      );
    }
    return ranked;
  }

  static List<RankedStudent> forQuiz(QuizBoard board) => rank(
    board.entries.map(
      (e) => RankedStudent(rank: 0, uid: e.uid, name: e.name, score: e.score, durationMs: e.durationMs),
    ),
  );

  /// Adds up each student's score and time across [boards].
  static List<RankedStudent> overall(Iterable<QuizBoard> boards) {
    final totals = <String, RankedStudent>{};
    for (final entry in boards.expand((board) => board.entries)) {
      final total = totals[entry.uid];
      totals[entry.uid] = RankedStudent(
        rank: 0,
        uid: entry.uid,
        name: entry.name,
        score: (total?.score ?? 0) + entry.score,
        durationMs: (total?.durationMs ?? 0) + entry.durationMs,
        quizCount: (total?.quizCount ?? 0) + 1,
      );
    }
    return rank(totals.values);
  }
}
