import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/instructors/widgets/instructor_validators.dart';
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
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [_name, _email, _phone]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _add() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final result = await ref
        .read(academyRepositoryProvider)
        .addInstructor(_name.text, email: _email.text, phone: _phone.text);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        for (final controller in [_name, _email, _phone]) {
          controller.clear();
        }
      case Err(:final failure):
        showAppSnackBar(context, failure.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final existing = ref.watch(instructorsProvider).value ?? const [];

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
              validator: (value) => validateInstructorName(value, existing),
              textInputAction: TextInputAction.next,
            ),
            verticalSpace(12),
            AppTextField(
              label: 'admin.instructors.email'.tr(),
              hint: 'admin.instructors.email_hint'.tr(),
              controller: _email,
              validator: (value) => validateInstructorEmail(value, existing),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            verticalSpace(12),
            AppTextField(
              label: 'admin.instructors.phone'.tr(),
              controller: _phone,
              keyboardType: TextInputType.phone,
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
