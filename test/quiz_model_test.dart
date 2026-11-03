import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/data/models/quiz_attempt.dart';
import 'package:cairo_coding_app/data/models/quiz_question.dart';
import 'package:cairo_coding_app/data/services/quiz_progress.dart';
import 'package:cairo_coding_app/data/services/quiz_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 11, 1, 10);

  QuizAttempt attempt({
    String quizId = 'quiz',
    int number = 1,
    AttemptStatus status = AttemptStatus.graded,
    int durationMin = 10,
    DateTime? closesAt,
    Map<String, int> answers = const {},
    int? score,
  }) => QuizAttempt(
    quizId: quizId,
    uid: 'u1',
    number: number,
    studentName: 'Mariam',
    groupIds: const ['g1'],
    status: status,
    startedAt: start,
    lastAnswerAt: start.add(const Duration(minutes: 3)),
    durationMin: durationMin,
    closesAt: closesAt ?? start.add(const Duration(days: 1)),
    questionCount: 3,
    answers: answers,
    score: score,
  );

  group('answer key', () {
    const key = QuizAnswerKey(correct: {'a': 0, 'b': 1, 'c': 2}, points: {'a': 1, 'b': 2, 'c': 5});

    test('weighs each correct answer by its points', () {
      expect(key.grade({'a': 0, 'b': 1, 'c': 0}), (score: 3, correctCount: 2));
      expect(key.grade({'a': 0, 'b': 1, 'c': 2}), (score: 8, correctCount: 3));
      expect(key.grade({}), (score: 0, correctCount: 0));
    });

    test('a timed-out question scores nothing', () {
      expect(key.grade({'a': QuizAttempt.noAnswer}), (score: 0, correctCount: 0));
    });

    test('survives being stored by point value, the shape the security rules read', () {
      final stored = key.toMap();
      expect(stored['p1'], {'a': 0});
      expect(stored['p5'], {'c': 2});
      expect(stored['p20'], <String, int>{});
      expect(QuizAnswerKey.fromMap(stored), key);
    });
  });

  group('attempt deadline', () {
    test('is the time limit when the quiz stays open longer', () {
      expect(attempt().deadline, start.add(const Duration(minutes: 10)));
    });

    test('is the closing time when that comes first', () {
      final closes = start.add(const Duration(minutes: 4));
      expect(attempt(closesAt: closes).deadline, closes);
    });

    test('with no time limit is the closing time', () {
      final closes = start.add(const Duration(hours: 5));
      expect(attempt(durationMin: 0, closesAt: closes).deadline, closes);
    });

    test('only in-progress attempts expire', () {
      final late = start.add(const Duration(hours: 1));
      expect(attempt(status: AttemptStatus.inProgress).isExpired(late), isTrue);
      expect(attempt().isExpired(late), isFalse);
    });

    test('counts timed-out questions as not answered', () {
      final a = attempt(answers: {'a': 0, 'b': QuizAttempt.noAnswer});
      expect(a.answeredCount, 1);
    });
  });

  group('quiz availability', () {
    final quiz = Quiz(
      id: 'quiz',
      title: 'Loops',
      opensAt: start,
      closesAt: start.add(const Duration(days: 2)),
      maxAttempts: 2,
    );
    final before = start.subtract(const Duration(hours: 1));
    final during = start.add(const Duration(hours: 1));
    final after = start.add(const Duration(days: 3));

    test('follows the window when nothing was taken', () {
      final progress = QuizProgress(quiz: quiz, attempts: const []);
      expect(progress.availability(before), QuizAvailability.upcoming);
      expect(progress.availability(during), QuizAvailability.available);
      expect(progress.availability(after), QuizAvailability.expired);
    });

    test('a finished attempt is completed even after the quiz closes', () {
      final progress = QuizProgress(quiz: quiz, attempts: [attempt(score: 3)]);
      expect(progress.availability(during), QuizAvailability.completed);
      expect(progress.availability(after), QuizAvailability.completed);
    });

    test('ignores attempts at other quizzes', () {
      final progress = QuizProgress(
        quiz: quiz,
        attempts: [attempt(quizId: 'other', score: 3)],
      );
      expect(progress.attempts, isEmpty);
    });

    test('counts attempts left and allows a retake only inside the window', () {
      final progress = QuizProgress(quiz: quiz, attempts: [attempt(score: 3)]);
      expect(progress.attemptsLeft, 1);
      expect(progress.canStartNew(during), isTrue);
      expect(progress.canStartNew(after), isFalse);
    });

    test('blocks a new attempt once the limit is used or one is running', () {
      final used = QuizProgress(quiz: quiz, attempts: [attempt(score: 3), attempt(number: 2, score: 5)]);
      expect(used.attemptsLeft, 0);
      expect(used.canStartNew(during), isFalse);
      final running = QuizProgress(
        quiz: quiz,
        attempts: [attempt(status: AttemptStatus.inProgress)],
      );
      expect(running.canStartNew(during), isFalse);
    });

    test('the best attempt can be a later one, while the first stays the ranked one', () {
      final progress = QuizProgress(quiz: quiz, attempts: [attempt(number: 2, score: 5), attempt(score: 3)]);
      expect(progress.best?.number, 2);
      expect(progress.firstAttempt?.number, 1);
    });
  });

  group('publishing checks', () {
    final quiz = Quiz(
      id: 'quiz',
      title: 'Loops',
      groupIds: const ['g1'],
      opensAt: start,
      closesAt: start.add(const Duration(days: 1)),
    );
    const question = QuizQuestion(id: 'a', text: 'Q?', options: ['1', '2', '3', '4']);
    const content = QuizContent(
      questions: [question],
      key: QuizAnswerKey(correct: {'a': 0}, points: {'a': 1}),
    );

    Iterable<QuizIssue> issues(Quiz quiz, QuizContent content) => findQuizProblems(quiz, content).map((p) => p.issue);

    test('a finished quiz has no problems', () {
      expect(issues(quiz, content), isEmpty);
    });

    test('finds problems with the quiz itself', () {
      expect(issues(quiz.copyWith(title: ' '), content), [QuizIssue.noTitle]);
      expect(issues(quiz.copyWith(groupIds: []), content), [QuizIssue.noGroups]);
      expect(issues(quiz.copyWith(closesAt: start), content), [QuizIssue.badDates]);
      expect(issues(quiz, const QuizContent()), [QuizIssue.noQuestions]);
    });

    test('finds problems with a question and says which', () {
      final problems = findQuizProblems(
        quiz,
        const QuizContent(
          questions: [
            question,
            QuizQuestion(id: 'b', text: '', options: ['1', '', '3', '4'], imageUrl: 'http://x.com/a.png'),
          ],
          key: QuizAnswerKey(correct: {'a': 0}, points: {'a': 1, 'b': 1}),
        ),
      );
      expect(problems.map((p) => p.issue), [
        QuizIssue.noQuestionText,
        QuizIssue.missingOption,
        QuizIssue.noCorrectAnswer,
        QuizIssue.badImageLink,
      ]);
      expect(problems.every((p) => p.questionIndex == 1), isTrue);
    });

    test('image links must be https, and empty is fine', () {
      expect(isValidImageLink(''), isTrue);
      expect(isValidImageLink('https://x.com/a.png'), isTrue);
      expect(isValidImageLink('http://x.com/a.png'), isFalse);
      expect(isValidImageLink('not a link'), isFalse);
    });
  });
}
