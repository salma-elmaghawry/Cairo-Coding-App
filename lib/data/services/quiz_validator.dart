import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/data/models/quiz_question.dart';

enum QuizIssue {
  noTitle,
  noGroups,
  badDates,
  noQuestions,
  noQuestionText,
  missingOption,
  noCorrectAnswer,
  badImageLink,
}

class QuizProblem {
  const QuizProblem(this.issue, {this.questionIndex});

  final QuizIssue issue;

  /// Which question it's about; null when it's about the quiz itself.
  final int? questionIndex;
}

/// Images are links (no Storage on the Spark plan), and Android blocks plain http ones.
bool isValidImageLink(String link) {
  final trimmed = link.trim();
  if (trimmed.isEmpty) return true;
  final uri = Uri.tryParse(trimmed);
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}

/// Everything that stops a quiz from being published. A draft can be saved with any of these except a title.
List<QuizProblem> findQuizProblems(Quiz quiz, QuizContent content) => [
  if (quiz.title.trim().isEmpty) const QuizProblem(QuizIssue.noTitle),
  if (!isValidImageLink(quiz.coverUrl)) const QuizProblem(QuizIssue.badImageLink),
  if (quiz.groupIds.isEmpty) const QuizProblem(QuizIssue.noGroups),
  if (!quiz.closesAt.isAfter(quiz.opensAt)) const QuizProblem(QuizIssue.badDates),
  if (content.questions.isEmpty) const QuizProblem(QuizIssue.noQuestions),
  for (final (index, question) in content.questions.indexed) ...[
    if (question.text.trim().isEmpty) QuizProblem(QuizIssue.noQuestionText, questionIndex: index),
    if (question.options.length != QuizQuestion.optionCount || question.options.any((o) => o.trim().isEmpty))
      QuizProblem(QuizIssue.missingOption, questionIndex: index),
    if (content.key.correct[question.id] == null) QuizProblem(QuizIssue.noCorrectAnswer, questionIndex: index),
    if (!isValidImageLink(question.imageUrl)) QuizProblem(QuizIssue.badImageLink, questionIndex: index),
  ],
];
