import 'package:cairo_coding_app/admin/settings/widgets/instructors_panel.dart';
import 'package:cairo_coding_app/admin/widgets/admin_page.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/shared/preferences/preferences_panel.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'settings.eyebrow'.tr(),
      title: 'settings.title'.tr(),
      children: [
        Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [const PreferencesPanel(), verticalSpace(32), const InstructorsPanel()],
            ),
          ),
        ),
      ],
    );
  }
}
