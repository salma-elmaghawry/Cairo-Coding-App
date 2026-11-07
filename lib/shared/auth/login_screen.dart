import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/eyebrow_text.dart';
import 'package:cairo_coding_app/core/widgets/wordmark.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/shared/auth/widgets/login_form.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(appFlavorProvider).isAdmin;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(authStateProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        showAppSnackBar(context, error.toString(), isError: true);
      }
    });

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: AlignmentDirectional.topEnd.resolve(Directionality.of(context)),
            radius: 1.3,
            colors: [
              colorScheme.primary.withValues(alpha: isDark ? .22 : .12),
              colorScheme.primary.withValues(alpha: 0),
            ],
            stops: const [0, .7],
          ),
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              end: -14,
              top: 112,
              child: ExcludeSemantics(
                child: Text(
                  '{ ; }',
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.monoFont28Bold.copyWith(
                    fontSize: 120,
                    height: 1,
                    color: colorScheme.primary.withValues(alpha: .07),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                          child: _Content(isAdmin: isAdmin),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final header = [
      const Align(alignment: AlignmentDirectional.centerStart, child: Wordmark(fontSize: 42)),
      verticalSpace(32),
      EyebrowText('auth.login.eyebrow'.tr()),
      verticalSpace(6),
      Text(
        (isAdmin ? 'auth.login.admin_title' : 'auth.login.title').tr(),
        style: AppTextStyles.font28ExtraBold.copyWith(letterSpacing: -.5),
      ),
      verticalSpace(6),
      Text(
        (isAdmin ? 'auth.login.admin_subtitle' : 'auth.login.subtitle').tr(),
        style: AppTextStyles.font15Normal.copyWith(height: 1.45).secondary(context),
      ),
      verticalSpace(32),
      const LoginForm(),
    ].animateList();

    return Column(
      // The admin signs in on a wide web page, where the form sits in the middle.
      mainAxisAlignment: isAdmin ? MainAxisAlignment.center : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...header,
        if (!isAdmin) ...[
          const Spacer(),
          verticalSpace(32),
          const _NoAccountNote().fadeInSlideUp(delay: AppAnimations.sectionDelay * 3),
        ],
      ],
    );
  }
}

class _NoAccountNote extends StatelessWidget {
  const _NoAccountNote();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final body = AppTextStyles.font13Normal.secondary(context).copyWith(height: 1.5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.primary.withValues(alpha: .2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: colorScheme.primary),
          horizontalSpace(12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${'auth.login.no_account_title'.tr()} ',
                    style: AppTextStyles.font13ExtraBold.copyWith(color: colorScheme.onSurface),
                  ),
                  TextSpan(text: 'auth.login.no_account_body'.tr()),
                ],
              ),
              style: body,
            ),
          ),
        ],
      ),
    );
  }
}
