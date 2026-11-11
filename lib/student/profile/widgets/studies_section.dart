import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/icon_tile.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:cairo_coding_app/student/profile/profile_providers.dart';
import 'package:cairo_coding_app/student/profile/widgets/settings_section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The diploma the student is enrolled in and their group. A student in two groups sees both.
class StudiesSection extends ConsumerWidget {
  const StudiesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(profileGroupsProvider);
    final courseNames = {
      for (final course in ref.watch(profileCoursesProvider).value ?? const <Course>[]) course.id: course.name,
    };
    final diplomas = {for (final group in groups) ?courseNames[group.courseId]};

    return SettingsSection(
      title: 'profile.section_studies'.tr(context: context),
      children: [
        _InfoRow(
          icon: Icons.school_outlined,
          label: 'profile.diploma'.tr(context: context),
          value: diplomas.isEmpty ? '–' : diplomas.map(context.bidi).join(' · '),
        ),
        _InfoRow(
          icon: Icons.groups_outlined,
          label: 'profile.group'.tr(context: context),
          value: groups.isEmpty ? '–' : groups.map((group) => context.bidi(group.name)).join(' · '),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            IconTile(icon: icon, size: 38, iconSize: 18),
            horizontalSpace(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.font12Normal.secondary(context)),
                  verticalSpace(1),
                  Text(value, style: AppTextStyles.font15Bold),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
