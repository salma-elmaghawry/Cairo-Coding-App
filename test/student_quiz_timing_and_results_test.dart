import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_take_screen.dart';
import 'package:cairo_coding_app/student/student_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';
import 'helpers/student_quiz_harness.dart';

void main() {
  setUpAll(setUpAppTests);

  testWidgets('the quiz submits by itself when time runs out, keeping a tapped answer', (tester) async {
    phone(tester);
    var now = DateTime.now();
    await openQuizzes(tester, clock: () => now);
    await openLoops(tester);
    await answer(tester, '5');
    await tapText(tester, 'do-while');

    now = now.add(const Duration(minutes: 10, seconds: 1));
    await tester.pump(const Duration(milliseconds: 1050));
    await tester.pump();
    expect(find.text("Time's up!"), findsOneWidget);
    await settle(tester);
    await settle(tester);

    expect(find.text('Quiz result'), findsOneWidget);
    expect(find.text('3/10'), findsOneWidget);
    expect(find.text("Time's up, so your answers were submitted."), findsOneWidget);
  });

  testWidgets('a question\'s own timer moves on and locks it unanswered', (tester) async {
    phone(tester);
    var now = DateTime.now();
    await openQuizzes(tester, clock: () => now);
    await openGit(tester);
    expect(find.text('Question 1 of 2'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);

    now = now.add(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(find.text('Question 2 of 2'), findsOneWidget);

    now = now.add(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(find.text('Ready to submit?'), findsOneWidget);
    expect(find.text('0 of 2 answered'), findsOneWidget);
    expect(find.byIcon(Icons.timer_off_outlined), findsNWidgets(2));
  });

  testWidgets('a closed quiz\'s result shows the answers, and the leaderboard ranks ties and the top three', (
    tester,
  ) async {
    phone(tester);
    await openQuizzes(tester);
    await tapPill(tester, 'Completed');
    await tapText(tester, 'Conditions in C++'.unbroken);
    await tapText(tester, 'View my result');

    expect(find.text('6/8'), findsOneWidget);
    expect(find.text('You ranked #3 of 5'), findsOneWidget);
    expect(find.text('Review your answers'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Which operator compares two values for equality?'), 200);
    expect(find.byIcon(Icons.cancel_rounded), findsWidgets);

    await tester.scrollUntilVisible(find.text('You ranked #3 of 5'), -200);
    await tapText(tester, 'You ranked #3 of 5');
    expect(find.text('Omar Khaled'), findsOneWidget);
    expect(find.text('Farida Mostafa'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
  });

  testWidgets('the leaderboard only shows the student\'s groups', (tester) async {
    phone(tester);
    await openQuizzes(tester);
    await tapText(tester, 'Leaderboard');
    expect(find.text('Overall'), findsOneWidget);
    expect(find.text('Omar Khaled'), findsOneWidget);
    expect(find.text('Ranking of CS140 only'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Workshop'));
    await settle(tester);
    expect(find.text('Omar Khaled'), findsNothing);
    expect(find.text('No results yet. Be the first!'), findsOneWidget);
  });

  testWidgets('a retake is offered while attempts remain, and doesn\'t move the rank', (tester) async {
    phone(tester);
    await openQuizzes(tester);
    await openGit(tester);
    await tapText(tester, 'git add');
    await tapText(tester, 'Next');
    await tapText(tester, 'git pull');
    await tapText(tester, 'Finish');
    await tapText(tester, 'Submit quiz');
    await settle(tester);
    expect(find.text('0/4'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Retake quiz'), 200);
    await tapText(tester, 'Retake quiz');
    await tapText(tester, 'Retake quiz');
    await tapText(tester, 'git commit');
    await tapText(tester, 'Next');
    await tapText(tester, 'git push');
    await tapText(tester, 'Finish');
    await tapText(tester, 'Submit quiz');
    await settle(tester);

    expect(find.text('4/4'), findsOneWidget);
    expect(find.text("Retakes are for practice, so they don't change your rank."), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Back to quizzes'), 200);
    expect(find.text('Retake quiz'), findsNothing);
  });

  testWidgets('the whole flow works in Arabic', (tester) async {
    phone(tester);
    var now = DateTime.now();
    await pumpApp(
      tester,
      AppFlavor.student,
      studentRouterProvider,
      overrides: [clockProvider.overrideWithValue(() => now)],
      startLocale: const Locale('ar'),
    );
    await tester.enterText(find.byType(TextFormField).at(0), FakeAcademyStore.demoStudentEmail);
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await settle(tester);
    await tester.tap(find.text('تسجيل الدخول').last);
    await settle(tester);

    await tester.tap(find.text('الاختبارات').last);
    await settle(tester);
    // In Arabic, English titles are wrapped in direction marks.
    await tester.tap(find.textContaining('Loops in C++'.unbroken).first);
    await settle(tester);
    await tapText(tester, 'ابدأ الاختبار');
    expect(find.text('السؤال 1 من 5'), findsOneWidget);
    expect(find.byType(QuizTakeScreen), findsOneWidget);
    now = now.add(const Duration(minutes: 10, seconds: 1));
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    await settle(tester);
    expect(find.text('نتيجة الاختبار'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
