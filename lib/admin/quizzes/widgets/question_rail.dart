import 'package:cairo_coding_app/admin/quizzes/widgets/question_draft.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The list of questions beside the editor: tap to edit, drag the handle to reorder.
class QuestionRail extends StatelessWidget {
  const QuestionRail({
    super.key,
    required this.drafts,
    required this.selected,
    required this.enabled,
    required this.showErrors,
    required this.onSelect,
    required this.onReorder,
    required this.onDuplicate,
    required this.onDelete,
  });

  final List<QuestionDraft> drafts;
  final int selected;
  final bool enabled;
  final bool showErrors;
  final ValueChanged<int> onSelect;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<int> onDuplicate;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: drafts.length,
      onReorderItem: onReorder,
      proxyDecorator: (child, _, _) => Material(color: Colors.transparent, child: child),
      itemBuilder: (context, index) => Padding(
        key: ValueKey(drafts[index].id),
        padding: const EdgeInsets.only(bottom: 8),
        child: _RailTile(
          draft: drafts[index],
          index: index,
          selected: index == selected,
          enabled: enabled,
          showErrors: showErrors,
          canDelete: drafts.length > 1,
          onTap: () => onSelect(index),
          onDuplicate: () => onDuplicate(index),
          onDelete: () => onDelete(index),
        ),
      ),
    );
  }
}

class _RailTile extends StatelessWidget {
  const _RailTile({
    required this.draft,
    required this.index,
    required this.selected,
    required this.enabled,
    required this.showErrors,
    required this.canDelete,
    required this.onTap,
    required this.onDuplicate,
    required this.onDelete,
  });

  final QuestionDraft draft;
  final int index;
  final bool selected;
  final bool enabled;
  final bool showErrors;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = draft.text.text.trim();
    final problem = showErrors && !draft.isComplete;

    return Material(
      color: selected ? colorScheme.primary.withValues(alpha: .14) : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: problem
              ? colorScheme.error
              : selected
              ? colorScheme.primary
              : colorScheme.outline,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(6, 8, 4, 8),
          child: Row(
            children: [
              if (enabled)
                ReorderableDragStartListener(
                  index: index,
                  child: Tooltip(
                    message: 'admin.quiz_builder.drag'.tr(),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.drag_indicator_rounded, size: 20, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              horizontalSpace(4),
              Text('${index + 1}', style: AppTextStyles.monoFont14Bold.copyWith(color: colorScheme.primary)),
              horizontalSpace(8),
              Expanded(
                child: Text(
                  title.isEmpty ? 'admin.quiz_builder.untitled'.tr() : context.bidi(title),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: title.isEmpty ? AppTextStyles.font14Normal.secondary(context) : AppTextStyles.font14SemiBold,
                ),
              ),
              if (problem) Icon(Icons.error_outline_rounded, size: 18, color: colorScheme.error),
              if (enabled)
                PopupMenuButton<VoidCallback>(
                  tooltip: 'admin.quiz_builder.question_actions'.tr(),
                  iconSize: 18,
                  onSelected: (action) => action(),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: onDuplicate, child: Text('admin.quiz_builder.duplicate'.tr())),
                    PopupMenuItem(value: onDelete, enabled: canDelete, child: Text('admin.quiz_builder.delete'.tr())),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
