import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/app_text_field.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/instructor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InstructorsPanel extends ConsumerStatefulWidget {
  const InstructorsPanel({super.key});

  @override
  ConsumerState<InstructorsPanel> createState() => _InstructorsPanelState();
}

class _InstructorsPanelState extends ConsumerState<InstructorsPanel> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'validation.required'.tr();
    final existing = ref.read(instructorsProvider).value ?? const [];
    if (existing.any((i) => i.name.toLowerCase() == name.toLowerCase())) return 'admin.instructors.exists'.tr();
    return null;
  }

  Future<void> _add() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final result = await ref.read(academyRepositoryProvider).addInstructor(_name.text);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        _name.clear();
      case Err(:final failure):
        showAppSnackBar(context, failure.message, isError: true);
    }
  }

  Future<void> _remove(Instructor instructor) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.instructors.remove_title'.tr(args: [instructor.name]),
      message: 'admin.instructors.remove_message'.tr(),
      confirmLabel: 'common.delete'.tr(),
      cancelLabel: 'common.cancel'.tr(),
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final result = await ref.read(academyRepositoryProvider).deleteInstructor(instructor);
    if (!mounted) return;
    if (result case Err(:final failure)) showAppSnackBar(context, failure.message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final instructors = ref.watch(instructorsProvider);

    return AppCard(
      color: colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('admin.instructors.title'.tr(), style: AppTextStyles.font18ExtraBold),
            Text('admin.instructors.hint'.tr(), style: AppTextStyles.font12Normal.secondary(context)),
            verticalSpace(14),
            switch (instructors) {
              AsyncError(:final error) => ErrorView(message: error.toString()),
              AsyncData(:final value) when value.isEmpty => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('admin.instructors.empty'.tr(), style: AppTextStyles.font14Normal.secondary(context)),
              ),
              AsyncData(:final value) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final instructor in value) ...[
                    Container(
                      padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 6, 6),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.outline),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(instructor.name, style: AppTextStyles.font14Bold)),
                          IconButton(
                            style: IconButton.styleFrom(side: BorderSide.none),
                            tooltip: 'admin.instructors.remove'.tr(),
                            onPressed: () => _remove(instructor),
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                        ],
                      ),
                    ),
                    verticalSpace(8),
                  ],
                ],
              ),
              _ => const SkeletonList(count: 2, itemHeight: 48),
            },
            verticalSpace(6),
            AppTextField(
              label: 'admin.instructors.name'.tr(),
              hint: 'admin.instructors.name_hint'.tr(),
              controller: _name,
              validator: _validate,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _add(),
            ),
            verticalSpace(12),
            PrimaryButton(label: 'admin.instructors.add'.tr(), height: 48, isLoading: _saving, onPressed: _add),
          ],
        ),
      ),
    );
  }
}
