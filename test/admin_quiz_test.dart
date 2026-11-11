import 'package:cairo_coding_app/admin/admin_router.dart';
import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/data/fake/fake_academy_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

void main() {
  setUpAll(setUpAppTests);

  Future<void> openQuizzes(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester, AppFlavor.admin, adminRouterProvider);
    await signIn(tester, FakeAcademyStore.demoAdminEmail);
    await tester.tap(find.text('Quizzes').first);
    await settle(tester);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).first);
    await tester.pump();
    await tester.tap(find.text(text).first);
    await settle(tester);
  }

  Future<void> openMenuOf(WidgetTester tester, int index) async {
    await tester.tap(find.byTooltip('Quiz actions').at(index));
    await settle(tester);
  }

  int indexOfCard(WidgetTester tester, String title) {
    final y = tester.getTopLeft(find.text(title)).dy;
    final x = tester.getTopLeft(find.text(title)).dx;
    final menus = find.byTooltip('Quiz actions');
    for (var i = 0; i < menus.evaluate().length; i++) {
      final menu = tester.getTopLeft(menus.at(i));
      if ((menu.dy - y).abs() < 60 && menu.dx > x) return i;
    }
    throw StateError('no menu for $title');
  }

  testWidgets('lists quizzes, searches and filters by status', (tester) async {
    await openQuizzes(tester);
    expect(find.text('Loops in C++'.unbroken), findsOneWidget);
    expect(find.text('Pointers'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Draft'));
    await settle(tester);
    expect(find.text('Pointers'), findsOneWidget);
    expect(find.text('Loops in C++'.unbroken), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await settle(tester);
    await tester.enterText(pageField(), 'git');
    await settle(tester);
    expect(find.text('Git basics'), findsOneWidget);
    expect(find.text('Loops in C++'.unbroken), findsNothing);

    await tester.enterText(pageField(), 'nothing like this');
    await settle(tester);
    expect(find.text('No quizzes match'), findsOneWidget);
  });

  testWidgets('builds a quiz on one page and publishes it once it\'s complete', (tester) async {
    await openQuizzes(tester);
    await tapText(tester, 'New quiz');
    expect(find.text('Questions (1)'), findsOneWidget);

    // Publishing stops at each thing that's missing.
    await tapText(tester, 'Publish');
    expect(find.text('This field is required'), findsWidgets);

    await tester.enterText(find.widgetWithText(TextFormField, '').first, 'Functions');
    await settle(tester);
    await tapText(tester, 'Publish');
    expect(find.text('Pick at least one group'), findsWidgets);

    await tester.tap(find.widgetWithText(ChoiceChip, 'CS140 · C++'.unbroken));
    await settle(tester);
    await tapText(tester, 'Publish');
    expect(find.text("Question 1 isn't finished"), findsOneWidget);
    expect(find.text('Mark the correct answer'), findsOneWidget);

    final texts = find.descendant(of: find.byType(TextField), matching: find.byType(EditableText));
    final count = texts.evaluate().length;
    // Question, four answers and the image link are the last six inputs on the page.
    await tester.enterText(texts.at(count - 6), 'What does return do?');
    for (final (offset, answer) in [(5, 'Ends the function'), (4, 'Prints'), (3, 'Loops'), (2, 'Nothing')]) {
      await tester.enterText(texts.at(count - offset), answer);
    }
    await settle(tester);
    await tester.tap(find.byIcon(Icons.radio_button_unchecked_rounded).first);
    await settle(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, '5'));
    await settle(tester);
    expect(find.text('What does return do?'), findsWidgets);
    expect(find.text('Mark the correct answer'), findsNothing);

    await tapText(tester, 'Preview');
    expect(find.text('As students will see it'), findsOneWidget);
    expect(find.text('5 points'), findsOneWidget);
    await tapText(tester, 'Close');

    await tapText(tester, 'Publish');
    expect(find.text('Quiz published'), findsOneWidget);
    expect(find.text('Functions'), findsOneWidget);
  });

  testWidgets('adds, duplicates, deletes and reorders questions', (tester) async {
    await openQuizzes(tester);
    await tapText(tester, 'New quiz');
    final texts = find.descendant(of: find.byType(TextField), matching: find.byType(EditableText));

    Future<void> writeQuestion(String text) async {
      await tester.enterText(texts.at(texts.evaluate().length - 6), text);
      await settle(tester);
    }

    await writeQuestion('First question');
    await tapText(tester, 'Add question');
    expect(find.text('Questions (2)'), findsOneWidget);
    await writeQuestion('Second question');
    expect(find.text('Question 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Question actions').first);
    await settle(tester);
    await tester.tap(find.text('Duplicate').last);
    await settle(tester);
    expect(find.text('Questions (3)'), findsOneWidget);
    expect(find.text('First question'), findsWidgets);

    await tester.tap(find.byTooltip('Question actions').at(1));
    await settle(tester);
    await tester.tap(find.text('Delete').last);
    await settle(tester);
    expect(find.text('Questions (2)'), findsOneWidget);

    final handle = find.byIcon(Icons.drag_indicator_rounded).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 150));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await settle(tester);
    final firstY = tester.getTopLeft(find.text('First question').first).dy;
    final secondY = tester.getTopLeft(find.text('Second question').first).dy;
    expect(secondY, lessThan(firstY));
  });

  testWidgets('leaving with unsaved changes asks first', (tester) async {
    await openQuizzes(tester);
    await tapText(tester, 'New quiz');
    await tester.enterText(find.widgetWithText(TextFormField, '').first, 'Half written');
    await settle(tester);

    await tester.tap(find.text('Students').first);
    await settle(tester);
    expect(find.text('Leave without saving?'), findsOneWidget);
    await tapText(tester, 'Stay');
    expect(find.text('New quiz'), findsWidgets);

    await tester.tap(find.text('Students').first);
    await settle(tester);
    await tapText(tester, 'Leave');
    expect(find.text('10 students'), findsOneWidget);
  });

  testWidgets('a draft saves without being complete, and edits come back', (tester) async {
    await openQuizzes(tester);
    await tapText(tester, 'New quiz');
    await tester.enterText(find.widgetWithText(TextFormField, '').first, 'Rough idea');
    await settle(tester);
    await tapText(tester, 'Save draft');
    expect(find.text('Draft saved'), findsOneWidget);
    expect(find.text('Rough idea'), findsOneWidget);
    await tester.enterText(pageField(), 'rough');
    await settle(tester);
    await tester.tap(find.text('Edit').first);
    await settle(tester);
    expect(find.text('Edit quiz'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is EditableText && w.controller.text == 'Rough idea'), findsOneWidget);
  });

  testWidgets('a quiz students have taken keeps its questions locked', (tester) async {
    await openQuizzes(tester);
    await openMenuOf(tester, indexOfCard(tester, 'Conditions in C++'.unbroken));
    await tapText(tester, 'Unpublish');
    expect(find.text('Quiz unpublished'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Draft'));
    await settle(tester);
    await tester.tap(find.text('Edit').last);
    await settle(tester);
    expect(find.textContaining('its questions are locked'), findsOneWidget);
    expect(find.text('Add question'), findsNothing);
    expect(find.byIcon(Icons.drag_indicator_rounded), findsNothing);
  });

  testWidgets('duplicates, unpublishes and deletes from the list', (tester) async {
    await openQuizzes(tester);

    await openMenuOf(tester, indexOfCard(tester, 'Loops in C++'.unbroken));
    await tapText(tester, 'Duplicate');
    expect(find.text('Copy of Loops in C++'.unbroken), findsOneWidget);

    await openMenuOf(tester, indexOfCard(tester, 'Git basics'));
    await tapText(tester, 'Delete');
    expect(find.text('Delete Git basics?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await settle(tester);
    expect(find.text('Git basics'), findsNothing);
    expect(find.text('Quiz deleted'), findsOneWidget);

    await openMenuOf(tester, indexOfCard(tester, 'Pointers'));
    await tapText(tester, 'Publish');
    expect(find.text("This quiz isn't finished yet. Open it to see what's missing."), findsOneWidget);
  });

  testWidgets('analytics shows totals, question performance and each student', (tester) async {
    tester.view.physicalSize = const Size(1440, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester, AppFlavor.admin, adminRouterProvider);
    await signIn(tester, FakeAcademyStore.demoAdminEmail);
    await tester.tap(find.text('Quizzes').first);
    await settle(tester);

    final title = tester.getTopLeft(find.text('Conditions in C++'.unbroken));
    final buttons = find.text('Analytics');
    var closest = buttons.first;
    var best = double.infinity;
    for (var i = 0; i < buttons.evaluate().length; i++) {
      final at = tester.getTopLeft(buttons.at(i));
      final distance = (at - title).distance;
      if (at.dy > title.dy && distance < best) {
        best = distance;
        closest = buttons.at(i);
      }
    }
    await tester.tap(closest);
    await settle(tester);

    // CS140 has five active students. Scores: Omar 8, Youssef 7, Mariam 6, Nour 5, Farida 3.
    expect(find.text('Students assigned'), findsOneWidget);
    expect(find.text('5'), findsWidgets);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('5.8/8'), findsOneWidget);
    expect(find.text('8/8'), findsWidgets);
    expect(find.text('3/8'), findsWidgets);

    expect(find.text('Which operator compares two values for equality?'), findsOneWidget);
    expect(find.text('Most picked wrong answer'), findsWidgets);
    expect(find.text('1 didn\'t answer'), findsOneWidget);

    expect(find.text('Omar Khaled'), findsOneWidget);
    expect(find.text('8/8 · 100%'), findsOneWidget);
    expect(find.text('Karim Ashraf'), findsNothing);
  });
}
