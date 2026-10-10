import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('404;', style: AppTextStyles.monoFont14Medium.copyWith(color: colorScheme.primary)),
              verticalSpace(8),
              Text('not_found.title'.tr(), style: AppTextStyles.font20Bold, textAlign: TextAlign.center),
              verticalSpace(8),
              Text(
                'not_found.message'.tr(),
                style: AppTextStyles.font14Normal.secondary(context),
                textAlign: TextAlign.center,
              ),
              verticalSpace(16),
              OutlinedButton(onPressed: () => context.go('/'), child: Text('not_found.go_home'.tr())),
            ].animateList(),
          ),
        ),
      ),
    );
  }
}
