import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';
import 'helpers/student_quiz_harness.dart';

void main() {
  setUpAll(setUpAppTests);

  testWidgets('the list shows every status and filters by it', (tester) async {
    phone(tester);
    await openQuizzes(tester);

    expect(find.text('Loops in C++'), findsOneWidget);
    expect(find.text('Available'), findsWidgets);
    expect(find.text('Leaderboard'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Upcoming'));
    await settle(tester);
    expect(find.text('Arrays and strings'), findsOneWidget);
    expect(find.text('Loops in C++'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Completed'));
    await settle(tester);
    expect(find.text('Conditions in C++'), findsOneWidget);
    expect(find.text('6/8'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Expired'));
    await settle(tester);
    expect(find.text('Operators in C++'), findsOneWidget);
  });

  testWidgets('a draft quiz and another group\'s quiz never appear', (tester) async {
    phone(tester);
    await openQuizzes(tester);
    expect(find.text('Pointers'), findsNothing);
  });

  testWidgets('an upcoming quiz can\'t be started', (tester) async {
    phone(tester);
    await openQuizzes(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Upcoming'));
    await settle(tester);
    await tapText(tester, 'Arrays and strings');
    expect(find.text('Not open yet'), findsOneWidget);
    expect(find.text('Start quiz'), findsNothing);
  });

  testWidgets('takes a quiz from start to result to leaderboard', (tester) async {
    phone(tester);
    await openQuizzes(tester);

    await tapText(tester, 'Loops in C++');
    expect(find.text('Quiz details'), findsOneWidget);
    expect(find.text('10 min'), findsOneWidget);
    await tapText(tester, 'Start quiz');

    expect(find.text('Question 1 of 5'), findsOneWidget);
    final next = find.ancestor(of: find.text('Next'), matching: find.byType(Semantics)).first;
    expect(tester.widget<Semantics>(next).properties.enabled, isFalse);

    // Correct: 1, 2, 3 points. Wrong on question 4. Question 5 is skipped, then answered from the confirm screen.
    await answer(tester, '5');
    expect(find.text('Question 2 of 5'), findsOneWidget);
    await answer(tester, 'do-while');
    await answer(tester, 'Leaves the loop');
    await answer(tester, 'Leaves the loop');
    await tapText(tester, 'Skip');

    expect(find.text('Ready to submit?'), findsOneWidget);
    expect(find.text('4 of 5 answered'), findsOneWidget);
    await tapText(tester, '5');
    expect(find.text('Question 5 of 5'), findsOneWidget);
    await tapText(tester, '0');
    await tapText(tester, 'Finish');
    expect(find.text('5 of 5 answered'), findsOneWidget);

    await tapText(tester, 'Submit quiz');
    await settle(tester);

    expect(find.text('Quiz result'), findsOneWidget);
    expect(find.text('Good effort!'), findsNothing);
    expect(find.text('Great job!'), findsOneWidget);
    expect(find.text('8/10'), findsOneWidget);
    expect(find.text('80%'), findsWidgets);
    expect(find.text('5/5'), findsOneWidget);
    expect(find.text('You ranked #1 of 1'), findsOneWidget);

    await tapText(tester, 'You ranked #1 of 1');
    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
  });

  testWidgets('answers stay hidden while the quiz is open', (tester) async {
    phone(tester);
    await openQuizzes(tester);
    await openLoops(tester);
    await answer(tester, '4');
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    expect(find.byIcon(Icons.cancel_rounded), findsNothing);
    await tapText(tester, 'Skip');
    await tapText(tester, 'Skip');
    await tapText(tester, 'Skip');
    await tapText(tester, 'Skip');
    await tapText(tester, 'Submit quiz');
    await settle(tester);
    expect(find.text('You can review the correct answers once the quiz closes.'), findsOneWidget);
    expect(find.text('Review your answers'), findsNothing);
  });

  testWidgets('a locked answer isn\'t offered again', (tester) async {
    phone(tester);
    await openQuizzes(tester);
    await openLoops(tester);
    await answer(tester, '5');
    for (var i = 0; i < 4; i++) {
      await tapText(tester, 'Skip');
    }
    expect(find.text('Ready to submit?'), findsOneWidget);
    await tapText(tester, '1');
    expect(find.text('Ready to submit?'), findsOneWidget);
  });

  testWidgets('leaving keeps the attempt, and it resumes at the next open question', (tester) async {
    phone(tester);
    await openQuizzes(tester);
    await openLoops(tester);
    await answer(tester, '5');

    await tester.tap(find.byIcon(Icons.close_rounded));
    await settle(tester);
    expect(find.text('Leave the quiz?'), findsOneWidget);
    await tapText(tester, 'Leave quiz');
    expect(find.text('Resume quiz'), findsOneWidget);
    await tapText(tester, 'Resume quiz');

    expect(find.text('Question 2 of 5'), findsOneWidget);
  });
}
