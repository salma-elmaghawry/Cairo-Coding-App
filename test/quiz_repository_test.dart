import 'package:cairo_coding_app/core/error_handling/failures.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:cairo_coding_app/data/fake/fake_quiz_source.dart';
import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/data/models/quiz_attempt.dart';
import 'package:cairo_coding_app/data/models/quiz_question.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:cairo_coding_app/data/repositories/quiz_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

T unwrap<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw failure,
};

void main() {
  setUpAll(setUpAppTests);

  final start = DateTime(2026, 11, 1, 10);

  group('taking a quiz on the repository', () {
    late FakeAcademyStore store;
    late QuizRepository repository;
    late Student mariam;
    late Quiz quiz;

    setUp(() {
      store = FakeAcademyStore();
      repository = QuizRepository(FakeQuizSource(store));
      mariam = store.studentByEmail(FakeAcademyStore.demoStudentEmail)!;
      quiz = store.quizzes['quiz_loops']!;
    });

    test('scores the attempt and posts it to the group leaderboard', () async {
      final attempt = unwrap(await repository.startAttempt(quiz, mariam, number: 1));
      await repository.saveAnswer(attempt, 'loops1', 1);
      await repository.saveAnswer(attempt, 'loops2', 2);
      await repository.saveAnswer(attempt, 'loops3', 0);

      final graded = unwrap(await repository.finishAttempt(attempt.id));

      expect(graded.isGraded, isTrue);
      expect(graded.score, 3);
      expect(graded.correctCount, 2);
      expect(graded.wrongCount, 1);
      expect(store.quizBoards['cs140']!['quiz_loops']![mariam.uid]!.score, 3);
    });

    test('questions and answers stay hidden until the right step', () async {
      expect(await repository.getPaper(quiz.id), isA<Err<List<QuizQuestion>>>());
      final attempt = unwrap(await repository.startAttempt(quiz, mariam, number: 1));
      expect(await repository.getPaper(quiz.id), isA<Ok<List<QuizQuestion>>>());
      expect(await repository.getReview(quiz.id), isA<Err<QuizContent>>());
      unwrap(await repository.finishAttempt(attempt.id));
      expect(await repository.getReview(quiz.id), isA<Ok<QuizContent>>());
    });

    test('an answer can\'t be changed', () async {
      final attempt = unwrap(await repository.startAttempt(quiz, mariam, number: 1));
      await repository.saveAnswer(attempt, 'loops1', 0);
      final second = await repository.saveAnswer(attempt, 'loops1', 1);
      expect(second, isA<Err<void>>());
      expect(unwrap(await repository.finishAttempt(attempt.id)).score, 0);
    });

    test('starting twice with the same number is refused', () async {
      unwrap(await repository.startAttempt(quiz, mariam, number: 1));
      final second = await repository.startAttempt(quiz, mariam, number: 1);
      expect(second, isA<Err<QuizAttempt>>());
      expect((second as Err<QuizAttempt>).failure, isA<NotAuthorizedFailure>());
    });

    test('attempts stop at the limit', () async {
      final attempt = unwrap(await repository.startAttempt(quiz, mariam, number: 1));
      unwrap(await repository.finishAttempt(attempt.id));
      expect(await repository.startAttempt(quiz, mariam, number: 2), isA<Err<QuizAttempt>>());
    });

    test('a student outside the quiz\'s groups can\'t start', () async {
      final outsider = store.studentByEmail('hana.i@example.com')!;
      expect(await repository.startAttempt(quiz, outsider, number: 1), isA<Err<QuizAttempt>>());
    });

    test('an upcoming or closed quiz can\'t be started', () async {
      expect(await repository.startAttempt(store.quizzes['quiz_arrays']!, mariam, number: 1), isA<Err<QuizAttempt>>());
      expect(
        await repository.startAttempt(store.quizzes['quiz_operators']!, mariam, number: 1),
        isA<Err<QuizAttempt>>(),
      );
    });

    test('finishing twice at once does the work once', () async {
      final attempt = unwrap(await repository.startAttempt(quiz, mariam, number: 1));
      final results = await Future.wait([repository.finishAttempt(attempt.id), repository.finishAttempt(attempt.id)]);
      expect(results.every((r) => r is Ok<QuizAttempt>), isTrue);
    });

    test('finishing again later returns the same grade', () async {
      final attempt = unwrap(await repository.startAttempt(quiz, mariam, number: 1));
      await repository.saveAnswer(attempt, 'loops2', 2);
      final first = unwrap(await repository.finishAttempt(attempt.id));
      final second = unwrap(await repository.finishAttempt(attempt.id));
      expect(second, first);
    });

    test('a retake doesn\'t change the leaderboard', () async {
      final git = store.quizzes['quiz_git']!;
      final first = unwrap(await repository.startAttempt(git, mariam, number: 1));
      unwrap(await repository.finishAttempt(first.id));
      final second = unwrap(await repository.startAttempt(git, mariam, number: 2));
      await repository.saveAnswer(second, 'git1', 1);
      expect(unwrap(await repository.finishAttempt(second.id)).score, 2);
      expect(store.quizBoards['workshop']!['quiz_git']![mariam.uid]!.score, 0);
    });

    test('publishing an unfinished quiz from the list is refused', () async {
      final draft = store.quizzes['quiz_pointers']!;
      final result = await repository.setPublished(draft, true);
      expect((result as Err<void>).failure, isA<ValidationFailure>());
      expect(store.quizzes['quiz_pointers']!.isPublished, isFalse);
    });

    test('a duplicate is a new draft with the same questions and no results', () async {
      final source = store.quizzes['quiz_conditions']!;
      final copy = unwrap(await repository.duplicateQuiz(source, title: 'Copy'));
      expect(copy.id, isNot(source.id));
      expect(copy.isPublished, isFalse);
      expect(store.quizContents[copy.id], store.quizContents[source.id]);
      expect(store.quizAttempts.values.where((a) => a.quizId == copy.id), isEmpty);
    });

    test('saving keeps the question count and total points in step', () async {
      final saved = unwrap(
        await repository.saveQuiz(
          Quiz(id: '', title: '  New  ', opensAt: start, closesAt: start),
          content: const QuizContent(
            questions: [
              QuizQuestion(id: 'a', text: ' Q ', options: [' 1 ', '2', '3', '4'], points: 5),
            ],
          ),
        ),
      );
      expect(saved.title, 'New');
      expect(saved.questionCount, 1);
      expect(saved.totalPoints, 5);
      expect(store.quizContents[saved.id]!.questions.single.options.first, '1');
    });

    test('deleting removes results and leaderboard rows too', () async {
      unwrap(await repository.deleteQuiz(store.quizzes['quiz_conditions']!));
      expect(store.quizzes.containsKey('quiz_conditions'), isFalse);
      expect(store.quizAttempts.values.where((a) => a.quizId == 'quiz_conditions'), isEmpty);
      expect(store.quizBoards['cs140']!.containsKey('quiz_conditions'), isFalse);
    });
  });
}
