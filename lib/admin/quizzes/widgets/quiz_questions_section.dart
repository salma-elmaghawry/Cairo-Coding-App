import 'package:cairo_coding_app/admin/quizzes/widgets/question_draft.dart';
import 'package:cairo_coding_app/admin/quizzes/widgets/question_editor.dart';
import 'package:cairo_coding_app/admin/quizzes/widgets/question_preview_dialog.dart';
import 'package:cairo_coding_app/admin/quizzes/widgets/question_rail.dart';
import 'package:cairo_coding_app/admin/widgets/two_pane.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/widgets/section_header.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The list of questions and the editor for the selected one.
class QuizQuestionsSection extends StatelessWidget {
  const QuizQuestionsSection({
    super.key,
    required this.drafts,
    required this.selected,
    required this.editable,
    required this.showErrors,
    required this.onAdd,
    required this.onSelect,
    required this.onReorder,
    required this.onDuplicate,
    required this.onDelete,
    required this.onChanged,
  });

  final List<QuestionDraft> drafts;
  final int selected;

  /// False once students have taken the quiz, when questions can only be read.
  final bool editable;
  final bool showErrors;
  final VoidCallback onAdd;
  final ValueChanged<int> onSelect;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<int> onDuplicate;
  final ValueChanged<int> onDelete;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final draft = drafts[selected];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'admin.quiz_builder.questions_title'.tr(args: ['${drafts.length}']),
          actionLabel: editable ? 'admin.quiz_builder.add_question'.tr() : null,
          onAction: editable ? onAdd : null,
        ),
        verticalSpace(10),
        TwoPane(
          sideFirst: true,
          side: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              QuestionRail(
                drafts: drafts,
                selected: selected,
                enabled: editable,
                showErrors: showErrors,
                onSelect: onSelect,
                onReorder: onReorder,
                onDuplicate: onDuplicate,
                onDelete: onDelete,
              ),
              if (editable)
                OutlinedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text('admin.quiz_builder.add_question'.tr()),
                ),
            ],
          ),
          main: QuestionEditor(
            key: ValueKey(draft.id),
            draft: draft,
            number: selected + 1,
            enabled: editable,
            showErrors: showErrors,
            onChanged: onChanged,
            onPreview: () => QuestionPreviewDialog.show(context, draft.toQuestion()),
          ),
        ),
      ],
    );
  }
}
