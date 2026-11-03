import 'package:cairo_coding_app/admin/quizzes/widgets/question_draft.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/theme/app_colors.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/data/models/quiz_question.dart';
import 'package:cairo_coding_app/data/services/quiz_validator.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_format.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class QuestionEditor extends StatelessWidget {
  const QuestionEditor({
    super.key,
    required this.draft,
    required this.number,
    required this.enabled,
    required this.showErrors,
    required this.onChanged,
    required this.onPreview,
  });

  final QuestionDraft draft;
  final int number;

  /// False once students have taken the quiz, when questions can only be read.
  final bool enabled;
  final bool showErrors;
  final VoidCallback onChanged;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageLink = draft.imageUrl.text.trim();
    final badImage = showErrors && !isValidImageLink(imageLink);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'admin.quiz_builder.question_number'.tr(args: ['$number']),
                  style: AppTextStyles.font18ExtraBold,
                ),
              ),
              TextButton.icon(
                onPressed: onPreview,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: Text('admin.quiz_builder.preview'.tr()),
              ),
            ],
          ),
          verticalSpace(14),
          _Field(
            label: 'admin.quiz_builder.question_text'.tr(),
            controller: draft.text,
            enabled: enabled,
            maxLines: 3,
            error: showErrors && draft.text.text.trim().isEmpty ? 'validation.required'.tr() : null,
          ),
          verticalSpace(16),
          Row(
            children: [
              Expanded(child: Text('admin.quiz_builder.options'.tr(), style: AppTextStyles.font14Bold)),
              Text('admin.quiz_builder.options_hint'.tr(), style: AppTextStyles.font12Normal.secondary(context)),
            ],
          ),
          verticalSpace(8),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              final columns = constraints.maxWidth >= 560 ? 2 : 1;
              final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final (index, controller) in draft.options.indexed)
                    SizedBox(
                      width: width,
                      child: _OptionField(
                        index: index,
                        controller: controller,
                        isCorrect: draft.correctOption == index,
                        enabled: enabled,
                        showError: showErrors && controller.text.trim().isEmpty,
                        onMarkCorrect: () {
                          draft.correctOption = index;
                          onChanged();
                        },
                      ),
                    ),
                ],
              );
            },
          ),
          if (showErrors && draft.correctOption == null) ...[
            verticalSpace(8),
            Text(
              'admin.quiz_builder.errors.no_correct'.tr(),
              style: AppTextStyles.font12SemiBold.copyWith(color: colorScheme.error),
            ),
          ],
          verticalSpace(16),
          Wrap(
            spacing: 24,
            runSpacing: 14,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('admin.quiz_builder.points'.tr(), style: AppTextStyles.font14Bold),
                  verticalSpace(8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final points in QuizQuestion.pointChoices)
                        ChoiceChip(
                          visualDensity: VisualDensity.compact,
                          label: Text('$points'),
                          selected: draft.points == points,
                          onSelected: enabled
                              ? (_) {
                                  draft.points = points;
                                  onChanged();
                                }
                              : null,
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                width: 190,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('admin.quiz_builder.question_time'.tr(), style: AppTextStyles.font14Bold),
                    verticalSpace(8),
                    DropdownButtonFormField<int>(
                      initialValue: draft.timeLimitSec,
                      isExpanded: true,
                      items: [
                        for (final seconds in QuizQuestion.timeLimitChoices)
                          DropdownMenuItem(
                            value: seconds,
                            child: Text(
                              seconds == 0
                                  ? 'admin.quiz_builder.no_question_time'.tr()
                                  : 'admin.quiz_builder.seconds'.tr(args: ['$seconds']),
                            ),
                          ),
                      ],
                      onChanged: enabled
                          ? (value) {
                              draft.timeLimitSec = value ?? 0;
                              onChanged();
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          verticalSpace(16),
          _Field(
            label: 'admin.quiz_builder.question_image'.tr(),
            hint: 'https://',
            controller: draft.imageUrl,
            enabled: enabled,
            keyboardType: TextInputType.url,
            error: badImage ? 'admin.quiz_builder.errors.bad_image'.tr() : null,
          ),
          if (imageLink.isNotEmpty && isValidImageLink(imageLink)) ...[
            verticalSpace(10),
            QuizImage(url: imageLink, height: 120, fit: BoxFit.contain),
          ],
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.enabled,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.error,
  });

  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppTextStyles.font14Bold),
        verticalSpace(8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTextStyles.font16Normal,
          decoration: InputDecoration(hintText: hint, errorText: error),
        ),
      ],
    );
  }
}

class _OptionField extends StatelessWidget {
  const _OptionField({
    required this.index,
    required this.controller,
    required this.isCorrect,
    required this.enabled,
    required this.showError,
    required this.onMarkCorrect,
  });

  final int index;
  final TextEditingController controller;
  final bool isCorrect;
  final bool enabled;
  final bool showError;
  final VoidCallback onMarkCorrect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final correctBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.success, width: 2),
    );

    return TextField(
      controller: controller,
      enabled: enabled,
      style: AppTextStyles.font16Normal,
      decoration: InputDecoration(
        hintText: 'admin.quiz_builder.option_hint'.tr(args: [optionLetter(index)]),
        errorText: showError ? 'validation.required'.tr() : null,
        enabledBorder: isCorrect ? correctBorder : null,
        disabledBorder: isCorrect ? correctBorder : null,
        focusedBorder: isCorrect ? correctBorder : null,
        prefixIcon: Tooltip(
          message: 'admin.quiz_builder.mark_correct'.tr(),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: enabled ? onMarkCorrect : null,
            child: Semantics(
              button: true,
              selected: isCorrect,
              label: 'admin.quiz_builder.mark_correct'.tr(),
              child: Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isCorrect ? AppColors.success : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
