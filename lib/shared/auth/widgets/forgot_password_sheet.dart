import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/app_validators.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_text_field.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordSheet extends ConsumerStatefulWidget {
  const ForgotPasswordSheet({super.key, required this.initialEmail});

  final String initialEmail;

  static Future<void> show(BuildContext context, {required String initialEmail}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ForgotPasswordSheet(initialEmail: initialEmail),
    );
  }

  @override
  ConsumerState<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(text: widget.initialEmail);
  bool _sending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    final result = await ref.read(authRepositoryProvider).sendPasswordReset(_emailController.text);
    if (!mounted) return;
    setState(() => _sending = false);
    switch (result) {
      case Ok():
        Navigator.of(context).pop();
        showAppSnackBar(context, 'auth.forgot.sent'.tr());
      case Err(:final failure):
        showAppSnackBar(context, failure.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('auth.forgot.title'.tr(), style: AppTextStyles.font20Bold),
            verticalSpace(6),
            Text('auth.forgot.message'.tr(), style: AppTextStyles.font14Normal.secondary(context)),
            verticalSpace(20),
            AppTextField(
              label: 'auth.login.email_label'.tr(),
              controller: _emailController,
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: AppValidators.validateEmail,
              onSubmitted: (_) => _send(),
            ),
            verticalSpace(20),
            PrimaryButton(label: 'auth.forgot.submit'.tr(), isLoading: _sending, onPressed: _send),
          ],
        ),
      ),
    );
  }
}
