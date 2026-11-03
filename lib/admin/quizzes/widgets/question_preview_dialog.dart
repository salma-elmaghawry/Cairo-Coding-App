import 'package:cairo_coding_app/data/models/quiz_question.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_question_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class QuestionPreviewDialog extends StatefulWidget {
  const QuestionPreviewDialog({super.key, required this.question});

  final QuizQuestion question;

  static Future<void> show(BuildContext context, QuizQuestion question) {
    return showDialog<void>(
      context: context,
      builder: (_) => QuestionPreviewDialog(question: question),
    );
  }

  @override
  State<QuestionPreviewDialog> createState() => _QuestionPreviewDialogState();
}

class _QuestionPreviewDialogState extends State<QuestionPreviewDialog> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('admin.quiz_builder.preview_title'.tr()),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: QuizQuestionView(
            question: widget.question,
            selected: _selected,
            onSelect: (option) => setState(() => _selected = option),
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('common.close'.tr()))],
    );
  }
}
