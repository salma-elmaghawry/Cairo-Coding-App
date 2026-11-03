import 'dart:math';

import 'package:equatable/equatable.dart';

class QuizQuestion extends Equatable {
  const QuizQuestion({
    required this.id,
    required this.text,
    this.imageUrl = '',
    this.options = const ['', '', '', ''],
    this.points = 1,
    this.timeLimitSec = 0,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) => QuizQuestion(
    id: map['id'] as String,
    text: map['text'] as String? ?? '',
    imageUrl: map['imageUrl'] as String? ?? '',
    options: List<String>.from(map['options'] as List? ?? const ['', '', '', '']),
    points: map['points'] as int? ?? 1,
    timeLimitSec: map['timeLimitSec'] as int? ?? 0,
  );

  static const int optionCount = 4;

  /// The security rules can't add up arbitrary points, only count correct answers per value, so these are fixed.
  static const List<int> pointChoices = [1, 2, 3, 5, 10, 20];

  static const List<int> timeLimitChoices = [0, 10, 20, 30, 60, 90, 120];

  /// Letters and digits only, because the id is used as a map key in Firestore field paths.
  static String newId() {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return 'q${List.generate(8, (_) => alphabet[random.nextInt(alphabet.length)]).join()}';
  }

  final String id;
  final String text;
  final String imageUrl;
  final List<String> options;
  final int points;

  /// Seconds to answer this question; 0 means no limit of its own.
  final int timeLimitSec;

  bool get hasTimeLimit => timeLimitSec > 0;

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'imageUrl': imageUrl,
    'options': options,
    'points': points,
    'timeLimitSec': timeLimitSec,
  };

  @override
  List<Object> get props => [id, text, imageUrl, options, points, timeLimitSec];
}

/// How one attempt's answers score against the key.
typedef QuizGrade = ({int score, int correctCount});

/// The correct answers, kept apart from the questions so students can't read them before submitting.
class QuizAnswerKey extends Equatable {
  const QuizAnswerKey({this.correct = const {}, this.points = const {}});

  /// Stored as one map per point value, which is what lets the security rules recount a score.
  factory QuizAnswerKey.fromMap(Map<String, dynamic> map) {
    final correct = <String, int>{};
    final points = <String, int>{};
    for (final value in QuizQuestion.pointChoices) {
      for (final MapEntry(key: questionId, value: option) in Map<String, dynamic>.from(
        map['p$value'] as Map? ?? {},
      ).entries) {
        correct[questionId] = option as int;
        points[questionId] = value;
      }
    }
    return QuizAnswerKey(correct: correct, points: points);
  }

  /// Correct option by question id; a question nobody has marked yet is missing.
  final Map<String, int> correct;

  /// Points by question id.
  final Map<String, int> points;

  Map<String, dynamic> toMap() => {
    for (final value in QuizQuestion.pointChoices)
      'p$value': {
        for (final MapEntry(key: questionId, value: option) in correct.entries)
          if (points[questionId] == value) questionId: option,
      },
  };

  QuizGrade grade(Map<String, int> answers) {
    var score = 0;
    var correctCount = 0;
    for (final MapEntry(key: questionId, value: option) in answers.entries) {
      if (correct[questionId] != option) continue;
      score += points[questionId] ?? 0;
      correctCount++;
    }
    return (score: score, correctCount: correctCount);
  }

  @override
  List<Object> get props => [correct, points];
}

class QuizContent extends Equatable {
  const QuizContent({this.questions = const [], this.key = const QuizAnswerKey()});

  final List<QuizQuestion> questions;
  final QuizAnswerKey key;

  int get totalPoints => questions.fold(0, (sum, question) => sum + question.points);

  @override
  List<Object> get props => [questions, key];
}
