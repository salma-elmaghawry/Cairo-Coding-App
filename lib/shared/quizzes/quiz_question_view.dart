import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/models/quiz_question.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_image.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_option_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A question as students see it. The quiz itself and the admin's preview both draw this, so the preview can't drift.
class QuizQuestionView extends StatelessWidget {
  const QuizQuestionView({super.key, required this.question, this.selected, this.onSelect, this.trailing});

  final QuizQuestion question;
  final int? selected;
  final ValueChanged<int>? onSelect;

  /// Shown across from the points, for the question's own timer.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            StatusChip(label: 'quizzes.points_count'.plural(question.points), tone: StatusTone.gold),
            const Spacer(),
            ?trailing,
          ],
        ),
        verticalSpace(14),
        Text(context.bidi(question.text), style: AppTextStyles.font20Bold),
        if (question.imageUrl.trim().isNotEmpty) ...[
          verticalSpace(14),
          QuizImage(url: question.imageUrl, height: 180, fit: BoxFit.contain),
        ],
        verticalSpace(18),
        for (final (index, option) in question.options.indexed) ...[
          QuizOptionTile(
            index: index,
            text: option,
            state: selected == index ? QuizOptionState.selected : QuizOptionState.idle,
            onTap: onSelect == null ? null : () => onSelect!(index),
          ),
          if (index < question.options.length - 1) verticalSpace(10),
        ],
      ],
    );
  }
}
