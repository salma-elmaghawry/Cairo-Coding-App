import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/student/reminders/reminder_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RemindersCard extends ConsumerWidget {
  const RemindersCard({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool enabled) async {
    final allowed = await ref.read(remindersEnabledProvider.notifier).set(enabled);
    if (!allowed && context.mounted) showAppSnackBar(context, 'settings.reminders_blocked'.tr(), isError: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      radius: 16,
      color: colorScheme.surfaceContainerHighest,
      child: Material(
        type: MaterialType.transparency,
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          secondary: Icon(Icons.notifications_none_rounded, color: colorScheme.primary),
          title: Text('settings.reminders_title'.tr(), style: AppTextStyles.font16Bold),
          subtitle: Text('settings.reminders_message'.tr(), style: AppTextStyles.font14Normal.secondary(context)),
          value: ref.watch(remindersEnabledProvider),
          onChanged: (enabled) => _toggle(context, ref, enabled),
        ),
      ),
    );
  }
}
