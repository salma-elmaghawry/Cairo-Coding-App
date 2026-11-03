import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/app_text_field.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:cairo_coding_app/data/services/quiz_validator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The quiz's own settings, everything above its questions.
class QuizDetailsCard extends ConsumerWidget {
  const QuizDetailsCard({
    super.key,
    required this.formKey,
    required this.title,
    required this.description,
    required this.cover,
    required this.duration,
    required this.groupIds,
    required this.maxAttempts,
    required this.opensAt,
    required this.closesAt,
    required this.showErrors,
    required this.onGroupToggled,
    required this.onMaxAttemptsChanged,
    required this.onPickOpens,
    required this.onPickCloses,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController title;
  final TextEditingController description;
  final TextEditingController cover;
  final TextEditingController duration;
  final Set<String> groupIds;
  final int maxAttempts;
  final DateTime opensAt;
  final DateTime closesAt;
  final bool showErrors;
  final void Function(String groupId, bool selected) onGroupToggled;
  final ValueChanged<int> onMaxAttemptsChanged;
  final VoidCallback onPickOpens;
  final VoidCallback onPickCloses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseNames = {
      for (final course in ref.watch(coursesProvider).value ?? const <Course>[]) course.id: course.name,
    };
    final groups = (ref.watch(adminGroupsProvider).value ?? const <AcademyGroup>[]).where((g) => !g.archived);
    final datesBad = showErrors && !closesAt.isAfter(opensAt);
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: formKey,
      child: AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('admin.quiz_builder.details'.tr(), style: AppTextStyles.font18ExtraBold),
            verticalSpace(14),
            AppTextField(
              label: 'admin.quiz_builder.quiz_title'.tr(),
              controller: title,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'validation.required'.tr() : null,
            ),
            verticalSpace(14),
            AppTextField(label: 'admin.quiz_builder.description'.tr(), controller: description, maxLines: 2),
            verticalSpace(14),
            AppTextField(
              label: 'admin.quiz_builder.cover'.tr(),
              hint: 'https://',
              controller: cover,
              keyboardType: TextInputType.url,
              validator: (value) => isValidImageLink(value ?? '') ? null : 'admin.quiz_builder.errors.bad_image'.tr(),
            ),
            verticalSpace(16),
            Text('admin.quiz_builder.groups'.tr(), style: AppTextStyles.font14Bold),
            verticalSpace(8),
            if (groups.isEmpty)
              Text('admin.instructors.no_active_groups'.tr(), style: AppTextStyles.font12Normal.secondary(context))
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final group in groups)
                    ChoiceChip(
                      label: Text([group.name, ?courseNames[group.courseId]].map(context.bidi).join(' · ')),
                      selected: groupIds.contains(group.id),
                      onSelected: (on) => onGroupToggled(group.id, on),
                    ),
                ],
              ),
            if (showErrors && groupIds.isEmpty) ...[
              verticalSpace(6),
              Text(
                'admin.quiz_builder.errors.no_groups'.tr(),
                style: AppTextStyles.font12SemiBold.copyWith(color: colorScheme.error),
              ),
            ],
            verticalSpace(16),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(
                  width: 200,
                  child: AppTextField(
                    label: 'admin.quiz_builder.duration'.tr(),
                    hint: 'admin.quiz_builder.duration_hint'.tr(),
                    controller: duration,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return null;
                      final minutes = int.tryParse(text);
                      return minutes == null || minutes < 0 ? 'admin.quiz_builder.errors.bad_number'.tr() : null;
                    },
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('admin.quiz_builder.attempts'.tr(), style: AppTextStyles.font14Bold),
                      verticalSpace(8),
                      DropdownButtonFormField<int>(
                        initialValue: maxAttempts,
                        isExpanded: true,
                        items: [
                          for (final count in {1, 2, 3, 5, maxAttempts})
                            DropdownMenuItem(value: count, child: Text('$count')),
                        ],
                        onChanged: (value) => onMaxAttemptsChanged(value ?? 1),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onPickOpens,
                  icon: const Icon(Icons.event_available_outlined, size: 18),
                  label: Text('${'admin.quiz_builder.opens'.tr()}: ${_dateTime(context, opensAt)}'),
                ),
                OutlinedButton.icon(
                  onPressed: onPickCloses,
                  icon: const Icon(Icons.event_busy_outlined, size: 18),
                  label: Text('${'admin.quiz_builder.closes'.tr()}: ${_dateTime(context, closesAt)}'),
                ),
              ],
            ),
            if (datesBad) ...[
              verticalSpace(6),
              Text(
                'admin.quiz_builder.errors.bad_dates'.tr(),
                style: AppTextStyles.font12SemiBold.copyWith(color: colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _dateTime(BuildContext context, DateTime date) => '${context.shortDay(date)}, ${context.time(date)}';
}
