import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/data/services/quiz_progress.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

extension QuizAvailabilityLabels on QuizAvailability {
  String get label => switch (this) {
    QuizAvailability.available => 'quizzes.status.available'.tr(),
    QuizAvailability.upcoming => 'quizzes.status.upcoming'.tr(),
    QuizAvailability.completed => 'quizzes.status.completed'.tr(),
    QuizAvailability.expired => 'quizzes.status.expired'.tr(),
  };

  StatusTone get tone => switch (this) {
    QuizAvailability.available => StatusTone.accent,
    QuizAvailability.upcoming => StatusTone.neutral,
    QuizAvailability.completed => StatusTone.success,
    QuizAvailability.expired => StatusTone.danger,
  };

  IconData get icon => switch (this) {
    QuizAvailability.available => Icons.play_circle_outline_rounded,
    QuizAvailability.upcoming => Icons.lock_outline_rounded,
    QuizAvailability.completed => Icons.check_circle_outline_rounded,
    QuizAvailability.expired => Icons.history_rounded,
  };
}

extension QuizLabels on Quiz {
  /// "15 min", or "No limit" for a quiz that only ends when it closes.
  String get timeLabel => hasTimeLimit ? 'quizzes.minutes'.tr(args: ['$durationMin']) : 'quizzes.no_limit'.tr();
}
