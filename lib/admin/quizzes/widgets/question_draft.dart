import 'package:cairo_coding_app/data/models/quiz_question.dart';
import 'package:flutter/widgets.dart';

/// One question while it's being written in the builder.
class QuestionDraft {
  QuestionDraft({
    String? id,
    String text = '',
    String imageUrl = '',
    List<String> options = const ['', '', '', ''],
    this.points = 1,
    this.timeLimitSec = 0,
    this.correctOption,
  }) : id = id ?? QuizQuestion.newId(),
       text = TextEditingController(text: text),
       imageUrl = TextEditingController(text: imageUrl),
       options = [for (final option in options) TextEditingController(text: option)];

  factory QuestionDraft.fromQuestion(QuizQuestion question, QuizAnswerKey key) => QuestionDraft(
    id: question.id,
    text: question.text,
    imageUrl: question.imageUrl,
    options: question.options,
    points: question.points,
    timeLimitSec: question.timeLimitSec,
    correctOption: key.correct[question.id],
  );

  final String id;
  final TextEditingController text;
  final TextEditingController imageUrl;
  final List<TextEditingController> options;
  int points;
  int timeLimitSec;
  int? correctOption;

  Iterable<TextEditingController> get _controllers => [text, imageUrl, ...options];

  bool get isComplete =>
      text.text.trim().isNotEmpty && options.every((option) => option.text.trim().isNotEmpty) && correctOption != null;

  /// A copy with its own id, so its answer stays separate from the original's.
  QuestionDraft duplicate() => QuestionDraft(
    text: text.text,
    imageUrl: imageUrl.text,
    options: [for (final option in options) option.text],
    points: points,
    timeLimitSec: timeLimitSec,
    correctOption: correctOption,
  );

  QuizQuestion toQuestion() => QuizQuestion(
    id: id,
    text: text.text,
    imageUrl: imageUrl.text,
    options: [for (final option in options) option.text],
    points: points,
    timeLimitSec: timeLimitSec,
  );

  void addListener(VoidCallback listener) {
    for (final controller in _controllers) {
      controller.addListener(listener);
    }
  }

  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
  }
}

QuizContent contentOf(List<QuestionDraft> drafts) => QuizContent(
  questions: [for (final draft in drafts) draft.toQuestion()],
  key: QuizAnswerKey(
    correct: {
      for (final draft in drafts)
        if (draft.correctOption != null) draft.id: draft.correctOption!,
    },
    points: {for (final draft in drafts) draft.id: draft.points},
  ),
);
