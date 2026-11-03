import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/data/models/quiz_attempt.dart';
import 'package:cairo_coding_app/data/models/quiz_board.dart';
import 'package:cairo_coding_app/data/models/quiz_question.dart';

/// One quiz in each state a student can see, for the demo apps and tests.
void seedFakeQuizzes(FakeAcademyStore store, DateTime now) {
  DateTime days(int count) => now.add(Duration(days: count));

  void add(Quiz quiz, List<(QuizQuestion, int)> questions) {
    final content = QuizContent(
      questions: [for (final (question, _) in questions) question],
      key: QuizAnswerKey(
        correct: {
          for (final (question, correct) in questions)
            if (correct >= 0) question.id: correct,
        },
        points: {for (final (question, _) in questions) question.id: question.points},
      ),
    );
    store.quizzes[quiz.id] = quiz.copyWith(questionCount: questions.length, totalPoints: content.totalPoints);
    store.quizContents[quiz.id] = content;
  }

  void took(String quizId, String email, List<int> answers, {required int seconds}) {
    final quiz = store.quizzes[quizId]!;
    final content = store.quizContents[quizId]!;
    final student = store.studentByEmail(email)!;
    final byQuestion = {
      for (final (index, question) in content.questions.indexed)
        if (index < answers.length && answers[index] != QuizAttempt.noAnswer) question.id: answers[index],
    };
    final grade = content.key.grade(byQuestion);
    final startedAt = quiz.opensAt.add(const Duration(hours: 1));
    final attempt = QuizAttempt(
      quizId: quizId,
      uid: student.uid,
      number: 1,
      studentName: student.name,
      groupIds: quiz.groupIds.where(student.groupIds.contains).toList(),
      status: AttemptStatus.graded,
      startedAt: startedAt,
      lastAnswerAt: startedAt.add(Duration(seconds: seconds)),
      submittedAt: startedAt.add(Duration(seconds: seconds + 2)),
      durationMin: quiz.durationMin,
      closesAt: quiz.closesAt,
      questionCount: quiz.questionCount,
      answers: byQuestion,
      score: grade.score,
      correctCount: grade.correctCount,
    );
    store.quizAttempts[attempt.id] = attempt;
    for (final groupId in attempt.groupIds) {
      store.quizBoards.putIfAbsent(groupId, () => {}).putIfAbsent(quizId, () => {})[attempt.uid] =
          BoardEntry.fromAttempt(attempt);
    }
  }

  add(
    Quiz(
      id: 'quiz_loops',
      title: 'Loops in C++',
      description: 'for, while and do-while: when to use each one, and how to read them.',
      groupIds: const ['cs140'],
      durationMin: 10,
      opensAt: days(-1),
      closesAt: days(3),
      status: QuizStatus.published,
    ),
    const [
      (
        QuizQuestion(
          id: 'loops1',
          text: 'How many times does for (int i = 0; i < 5; i++) run its body?',
          options: ['4', '5', '6', 'Forever'],
          points: 1,
        ),
        1,
      ),
      (
        QuizQuestion(
          id: 'loops2',
          text: 'Which loop always runs its body at least once?',
          options: ['for', 'while', 'do-while', 'None of them'],
          points: 2,
        ),
        2,
      ),
      (
        QuizQuestion(
          id: 'loops3',
          text: 'What does break do inside a loop?',
          options: ['Skips to the next iteration', 'Leaves the loop', 'Restarts the loop', 'Ends the program'],
          points: 2,
        ),
        1,
      ),
      (
        QuizQuestion(
          id: 'loops4',
          text: 'What does continue do inside a loop?',
          options: ['Skips to the next iteration', 'Leaves the loop', 'Restarts the loop', 'Ends the program'],
          points: 2,
        ),
        0,
      ),
      (
        QuizQuestion(
          id: 'loops5',
          text: 'What does this print?  int i = 3; while (i > 0) i--; cout << i;',
          options: ['3', '1', '0', '-1'],
          points: 3,
        ),
        2,
      ),
    ],
  );

  add(
    Quiz(
      id: 'quiz_conditions',
      title: 'Conditions in C++',
      description: 'if, else and switch.',
      groupIds: const ['cs140'],
      durationMin: 8,
      opensAt: days(-10),
      closesAt: days(-3),
      status: QuizStatus.published,
    ),
    const [
      (
        QuizQuestion(
          id: 'cond1',
          text: 'Which operator compares two values for equality?',
          options: ['=', '==', '!=', '=>'],
          points: 1,
        ),
        1,
      ),
      (
        QuizQuestion(
          id: 'cond2',
          text: 'What happens when a switch case has no break?',
          options: ['A compile error', 'It runs into the next case', 'The program ends', 'Nothing runs'],
          points: 2,
        ),
        1,
      ),
      (
        QuizQuestion(
          id: 'cond3',
          text: 'Which value counts as false in an if?',
          options: ['0', '1', '-1', '100'],
          points: 2,
        ),
        0,
      ),
      (
        QuizQuestion(
          id: 'cond4',
          text: 'What does the ?: operator choose between?',
          options: ['Two types', 'Two variables only', 'Two values', 'Two loops'],
          points: 3,
        ),
        2,
      ),
    ],
  );
  took('quiz_conditions', 'omar.k@example.com', [1, 1, 0, 2], seconds: 252);
  took('quiz_conditions', 'nour.h@example.com', [1, 1, 0, 0], seconds: 302);
  took('quiz_conditions', 'youssef.s@example.com', [0, 1, 0, 2], seconds: 302);
  took('quiz_conditions', FakeAcademyStore.demoStudentEmail, [1, 0, 0, 2], seconds: 345);
  took('quiz_conditions', 'farida.m@example.com', [1, 1, QuizAttempt.noAnswer, 1], seconds: 410);

  add(
    Quiz(
      id: 'quiz_arrays',
      title: 'Arrays and strings',
      description: 'Declaring, reading and looping over arrays and strings.',
      groupIds: const ['cs140'],
      durationMin: 15,
      opensAt: days(2),
      closesAt: days(5),
      status: QuizStatus.published,
    ),
    const [
      (
        QuizQuestion(
          id: 'arr1',
          text: 'What is the index of the first element of an array?',
          options: ['0', '1', '-1', 'It depends'],
          points: 1,
        ),
        0,
      ),
    ],
  );

  add(
    Quiz(
      id: 'quiz_operators',
      title: 'Operators in C++',
      description: 'Arithmetic, comparison and logical operators.',
      groupIds: const ['cs140'],
      durationMin: 10,
      opensAt: days(-14),
      closesAt: days(-5),
      status: QuizStatus.published,
    ),
    const [
      (QuizQuestion(id: 'op1', text: 'What is 7 % 3?', options: ['1', '2', '3', '0'], points: 1), 0),
      (QuizQuestion(id: 'op2', text: 'What is 7 / 2 with two ints?', options: ['3.5', '3', '4', '2'], points: 2), 1),
    ],
  );
  took('quiz_operators', 'omar.k@example.com', [0, 1], seconds: 95);

  add(
    Quiz(
      id: 'quiz_git',
      title: 'Git basics',
      description: 'Commits, branches and pushing your work. Beat the clock on every question.',
      groupIds: const ['workshop'],
      opensAt: days(-2),
      closesAt: days(6),
      maxAttempts: 2,
      status: QuizStatus.published,
    ),
    const [
      (
        QuizQuestion(
          id: 'git1',
          text: 'Which command saves your staged changes?',
          options: ['git add', 'git commit', 'git push', 'git save'],
          points: 2,
          timeLimitSec: 30,
        ),
        1,
      ),
      (
        QuizQuestion(
          id: 'git2',
          text: 'Which command sends your commits to GitHub?',
          options: ['git pull', 'git fetch', 'git push', 'git send'],
          points: 2,
          timeLimitSec: 30,
        ),
        2,
      ),
    ],
  );

  add(
    Quiz(
      id: 'quiz_pointers',
      title: 'Pointers',
      description: 'Still being written.',
      groupIds: const ['cs140'],
      durationMin: 20,
      opensAt: days(7),
      closesAt: days(9),
    ),
    const [
      (
        QuizQuestion(
          id: 'ptr1',
          text: 'What does a pointer store?',
          options: ['A value', 'An address', 'A type', 'A function'],
          points: 5,
        ),
        1,
      ),
      (QuizQuestion(id: 'ptr2', text: ''), -1),
    ],
  );
}
