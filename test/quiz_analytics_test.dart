import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/data/models/quiz_attempt.dart';
import 'package:cairo_coding_app/data/models/quiz_question.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:cairo_coding_app/data/services/quiz_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 11, 1, 10);

  group('analytics', () {
    final quiz = Quiz(
      id: 'quiz',
      title: 'Loops',
      groupIds: const ['g1', 'g2'],
      opensAt: start,
      closesAt: start.add(const Duration(days: 1)),
    );
    const content = QuizContent(
      questions: [
        QuizQuestion(id: 'a', text: 'A?', options: ['1', '2', '3', '4'], points: 1),
        QuizQuestion(id: 'b', text: 'B?', options: ['1', '2', '3', '4'], points: 5),
      ],
      key: QuizAnswerKey(correct: {'a': 0, 'b': 1}, points: {'a': 1, 'b': 5}),
    );
    Student student(String uid, List<String> groups, {bool active = true}) =>
        Student(uid: uid, name: uid, email: '$uid@x.com', phone: '', groupIds: groups, active: active);
    QuizAttempt taken(
      String uid,
      Map<String, int> answers, {
      int number = 1,
      AttemptStatus status = AttemptStatus.graded,
      List<String> groups = const ['g1'],
    }) => QuizAttempt(
      quizId: 'quiz',
      uid: uid,
      number: number,
      studentName: uid,
      groupIds: groups,
      status: status,
      startedAt: start,
      lastAnswerAt: start.add(const Duration(minutes: 2)),
      durationMin: 0,
      closesAt: quiz.closesAt,
      questionCount: 2,
      answers: answers,
    );

    final students = [
      student('s1', ['g1']),
      student('s2', ['g1']),
      student('s3', ['g2']),
      student('s4', ['g2']),
      student('gone', ['g1'], active: false),
      student('other', ['g9']),
    ];
    final attempts = [
      taken('s1', {'a': 0, 'b': 1}),
      taken('s2', {'a': 1, 'b': 2}),
      taken('s3', {'a': 0, 'b': 2}, groups: const ['g2']),
      taken('s4', {'a': 0}, status: AttemptStatus.inProgress, groups: const ['g2']),
    ];
    final analytics = QuizAnalytics.from(quiz: quiz, content: content, students: students, attempts: attempts);

    test('counts assigned and completed, leaving out inactive and unrelated students', () {
      expect(analytics.assigned, 4);
      expect(analytics.completed, 3);
      expect(analytics.completionRate, .75);
    });

    test('summarises scores of finished attempts only', () {
      expect(analytics.highest, 6);
      expect(analytics.lowest, 0);
      expect(analytics.average, closeTo(7 / 3, .001));
    });

    test('reports each question and its most picked wrong answer', () {
      final second = analytics.questions[1];
      expect(second.optionCounts, [0, 1, 2, 0]);
      expect(second.correct, 1);
      expect(second.correctRate, closeTo(1 / 3, .001));
      expect(second.topWrongOption, 2);
    });

    test('no wrong answer picked means no top wrong answer', () {
      final perfect = QuizAnalytics.from(
        quiz: quiz,
        content: content,
        students: students,
        attempts: [
          taken('s1', {'a': 0, 'b': 1}),
        ],
      );
      expect(perfect.questions.first.topWrongOption, isNull);
    });

    test('filters to one group', () {
      final one = QuizAnalytics.from(
        quiz: quiz,
        content: content,
        students: students,
        attempts: attempts,
        groupId: 'g2',
      );
      expect(one.assigned, 2);
      expect(one.completed, 1);
      expect(one.highest, 1);
    });

    test('counts a submitted attempt that was never graded', () {
      final submitted = QuizAnalytics.from(
        quiz: quiz,
        content: content,
        students: students,
        attempts: [
          taken('s1', {'a': 0, 'b': 1}, status: AttemptStatus.submitted),
        ],
      );
      expect(submitted.completed, 1);
      expect(submitted.highest, 6);
    });

    test('scores the first attempt and also reports the best retake', () {
      final retaken = QuizAnalytics.from(
        quiz: quiz,
        content: content,
        students: students,
        attempts: [
          taken('s1', {'a': 1}),
          taken('s1', {'a': 0, 'b': 1}, number: 2),
        ],
      );
      final result = retaken.results.firstWhere((r) => r.uid == 's1');
      expect(result.score, 0);
      expect(result.bestScore, 6);
      expect(result.attemptCount, 2);
    });

    test('keeps the result of someone who has left the group', () {
      final left = QuizAnalytics.from(
        quiz: quiz,
        content: content,
        students: const [],
        attempts: [
          taken('left', {'a': 0}),
        ],
      );
      expect(left.results.single.name, 'left');
    });

    test('completed students list first, by score', () {
      expect(analytics.results.first.uid, 's1');
      expect(analytics.results.last.status, StudentQuizStatus.inProgress);
    });
  });
}
