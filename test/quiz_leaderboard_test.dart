import 'package:cairo_coding_app/data/models/quiz_board.dart';
import 'package:cairo_coding_app/data/services/leaderboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('leaderboard', () {
    RankedStudent student(String uid, int score, int seconds) =>
        RankedStudent(rank: 0, uid: uid, name: uid, score: score, durationMs: seconds * 1000);

    List<int> ranksOf(List<RankedStudent> ranked) => ranked.map((s) => s.rank).toList();

    test('higher score first, then less time', () {
      final ranked = Leaderboard.rank([student('a', 5, 100), student('b', 8, 300), student('c', 5, 90)]);
      expect(ranked.map((s) => s.uid), ['b', 'c', 'a']);
      expect(ranksOf(ranked), [1, 2, 3]);
    });

    test('the same score and time share a rank, and the next rank is skipped', () {
      final ranked = Leaderboard.rank([
        student('a', 8, 100),
        student('b', 5, 200),
        student('c', 5, 200),
        student('d', 3, 50),
      ]);
      expect(ranksOf(ranked), [1, 2, 2, 4]);
    });

    test('times shown as the same second count as tied', () {
      final ranked = Leaderboard.rank([
        const RankedStudent(rank: 0, uid: 'a', name: 'a', score: 5, durationMs: 100900),
        const RankedStudent(rank: 0, uid: 'b', name: 'b', score: 5, durationMs: 100100),
      ]);
      expect(ranksOf(ranked), [1, 1]);
    });

    test('ties always list in the same order', () {
      final first = Leaderboard.rank([student('b', 5, 10), student('a', 5, 10)]);
      final second = Leaderboard.rank([student('a', 5, 10), student('b', 5, 10)]);
      expect(first.map((s) => s.uid), second.map((s) => s.uid));
    });

    test('overall adds up each student across quizzes', () {
      final ranked = Leaderboard.overall(const [
        QuizBoard(
          groupId: 'g',
          quizId: 'q1',
          entries: [
            BoardEntry(uid: 'a', name: 'A', score: 5, correctCount: 1, durationMs: 1000),
            BoardEntry(uid: 'b', name: 'B', score: 8, correctCount: 2, durationMs: 1000),
          ],
        ),
        QuizBoard(
          groupId: 'g',
          quizId: 'q2',
          entries: [BoardEntry(uid: 'a', name: 'A', score: 6, correctCount: 2, durationMs: 2000)],
        ),
      ]);
      expect(ranked.first.uid, 'a');
      expect(ranked.first.score, 11);
      expect(ranked.first.durationMs, 3000);
      expect(ranked.first.quizCount, 2);
      expect(ranked.last.quizCount, 1);
    });
  });
}
