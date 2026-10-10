import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlockedScreen extends ConsumerWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(appFlavorProvider).isAdmin;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_person_outlined, size: 48, color: colorScheme.primary),
                  verticalSpace(16),
                  Text(
                    (isAdmin ? 'auth.blocked.admin_title' : 'auth.blocked.title').tr(),
                    style: AppTextStyles.font22ExtraBold,
                    textAlign: TextAlign.center,
                  ),
                  verticalSpace(8),
                  Text(
                    (isAdmin ? 'auth.blocked.admin_message' : 'auth.blocked.message').tr(),
                    style: AppTextStyles.font16Normal.secondary(context),
                    textAlign: TextAlign.center,
                  ),
                  verticalSpace(24),
                  OutlinedButton.icon(
                    onPressed: () => ref.read(authRepositoryProvider).signOut(),
                    icon: const Icon(Icons.logout_rounded),
                    label: Text('auth.logout'.tr()),
                  ),
                ].animateList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
