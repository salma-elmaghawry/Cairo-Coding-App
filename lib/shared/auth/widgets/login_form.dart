import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/app_validators.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/widgets/app_text_field.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/shared/auth/login_controller.dart';
import 'package:cairo_coding_app/shared/auth/widgets/forgot_password_sheet.dart';
import 'package:cairo_coding_app/shared/auth/widgets/login_error_banner.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  int _shakeCount = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      setState(() => _shakeCount++);
      return;
    }
    ref.read(loginControllerProvider.notifier).signIn(email: _emailController.text, password: _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loginControllerProvider.select((state) => state.isLoading));
    final errorMessage = ref.watch(loginControllerProvider.select((state) => state.hasError ? '${state.error}' : null));
    ref.listen(loginControllerProvider.select((state) => state.hasError), (_, hasError) {
      if (hasError) setState(() => _shakeCount++);
    });

    final fields = AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'auth.login.email_label'.tr(),
            hint: 'auth.login.email_hint'.tr(),
            controller: _emailController,
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: AppValidators.validateEmail,
          ),
          verticalSpace(16),
          AppTextField(
            label: 'auth.login.password_label'.tr(),
            hint: 'auth.login.password_hint'.tr(),
            controller: _passwordController,
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            validator: AppValidators.validatePassword,
            onSubmitted: (_) => _submit(),
            suffix: IconButton(
              style: IconButton.styleFrom(side: BorderSide.none),
              tooltip: (_obscure ? 'auth.login.show_password' : 'auth.login.hide_password').tr(),
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            ),
          ),
        ],
      ),
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _shakeCount == 0 ? fields : KeyedSubtree(key: ValueKey(_shakeCount), child: fields.shake()),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => ForgotPasswordSheet.show(context, initialEmail: _emailController.text),
              child: Text('auth.login.forgot_password'.tr()),
            ),
          ),
          verticalSpace(8),
          PrimaryButton(label: 'auth.login.submit'.tr(), isLoading: isLoading, onPressed: _submit),
          if (errorMessage != null && !isLoading) ...[verticalSpace(14), LoginErrorBanner(message: errorMessage)],
        ],
      ),
    );
  }
}
