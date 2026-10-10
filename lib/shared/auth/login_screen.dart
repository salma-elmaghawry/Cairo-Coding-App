import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/eyebrow_text.dart';
import 'package:cairo_coding_app/core/widgets/wordmark.dart';
import 'package:cairo_coding_app/shared/auth/login_controller.dart';
import 'package:cairo_coding_app/shared/auth/widgets/login_form.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(appFlavorProvider).isAdmin;

    ref.listen(loginControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        showAppSnackBar(context, error.toString(), isError: true);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(alignment: AlignmentDirectional.centerStart, child: Wordmark(fontSize: 44)),
                  verticalSpace(40),
                  EyebrowText('auth.login.eyebrow'.tr()),
                  verticalSpace(6),
                  Text(
                    (isAdmin ? 'auth.login.admin_title' : 'auth.login.title').tr(),
                    style: AppTextStyles.font24ExtraBold,
                  ),
                  verticalSpace(6),
                  Text(
                    (isAdmin ? 'auth.login.admin_subtitle' : 'auth.login.subtitle').tr(),
                    style: AppTextStyles.font16Normal.secondary(context),
                  ),
                  verticalSpace(32),
                  const LoginForm(),
                  if (!isAdmin) ...[
                    verticalSpace(32),
                    Text(
                      'auth.login.no_account'.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.font14Normal.secondary(context),
                    ),
                  ],
                ].animateList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
