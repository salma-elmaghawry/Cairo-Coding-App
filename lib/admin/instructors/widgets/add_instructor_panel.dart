import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/app_text_field.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddInstructorPanel extends ConsumerStatefulWidget {
  const AddInstructorPanel({super.key});

  @override
  ConsumerState<AddInstructorPanel> createState() => _AddInstructorPanelState();
}

class _AddInstructorPanelState extends ConsumerState<AddInstructorPanel> {
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      color: colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('admin.instructors.add_title'.tr(), style: AppTextStyles.font18ExtraBold),
            Text('admin.instructors.hint'.tr(), style: AppTextStyles.font12Normal.secondary(context)),
            verticalSpace(14),
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
