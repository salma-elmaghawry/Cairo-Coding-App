import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/student/reminders/reminder_providers.dart';
import 'package:cairo_coding_app/student/profile/widgets/settings_section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RemindersSection extends ConsumerWidget {
  const RemindersSection({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool enabled) async {
    final allowed = await ref.read(remindersEnabledProvider.notifier).set(enabled);
    if (!allowed && context.mounted) {
      showAppSnackBar(context, 'settings.reminders_blocked'.tr(context: context), isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(remindersEnabledProvider);

    return SettingsSection(
      title: 'settings.section_notifications'.tr(context: context),
      children: [
        MergeSemantics(
          child: SettingsRow(
            icon: Icons.notifications_none_rounded,
            title: 'settings.reminders_title'.tr(context: context),
            subtitle: 'settings.reminders_hint'.tr(context: context),
            onTap: () => _toggle(context, ref, !enabled),
            trailing: Switch(value: enabled, onChanged: (value) => _toggle(context, ref, value)),
          ),
        ),
      ],
    );
  }
}
