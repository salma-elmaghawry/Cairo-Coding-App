import 'package:cairo_coding_app/admin/insights/group_insights.dart';
import 'package:cairo_coding_app/admin/widgets/admin_panel.dart';
import 'package:cairo_coding_app/core/helpers/link_launcher.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/initials_avatar.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// WhatsApp for an Egyptian number such as "010 1234 5678", or email when there's no phone.
String contactLinkOf(Student student) {
  final digits = student.phone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return 'mailto:${student.email}';
  return 'https://wa.me/${digits.startsWith('0') ? '2$digits' : digits}';
}

/// Students who missed the last two sessions or more in a row.
class NeedsAttentionPanel extends StatelessWidget {
  const NeedsAttentionPanel({super.key, required this.groups});

  final List<GroupInsights> groups;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rows = [
      for (final group in groups)
        for (final (student, missed) in group.fallingBehind) (group, student, missed),
    ];

    return AdminPanel(
      title: 'admin.overview.attention_title'.tr(),
      subtitle: 'admin.overview.attention_hint'.tr(),
      trailing: rows.isEmpty ? null : StatusChip(label: '${rows.length}', tone: StatusTone.danger),
      child: rows.isEmpty
          ? EmptyView(message: 'admin.overview.attention_empty'.tr(), icon: Icons.verified_outlined)
          : Column(
              children: [
                for (final (group, student, missed) in rows.take(6))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        InitialsAvatar(name: student.name),
                        horizontalSpace(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(student.name, style: AppTextStyles.font14ExtraBold),
                              Text(
                                missed.length > 3
                                    ? 'admin.overview.missed_count'.tr(args: [group.group.name, '${missed.length}'])
                                    : 'admin.overview.missed'.tr(
                                        args: [
                                          group.group.name,
                                          missed
                                              .map((s) => s.number == null ? 'X' : '#${'${s.number}'.padLeft(2, '0')}')
                                              .join(', '),
                                        ],
                                      ),
                                style: AppTextStyles.font12Normal.secondary(context),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'admin.overview.message'.tr(args: [student.name]),
                          style: IconButton.styleFrom(foregroundColor: colorScheme.primary),
                          onPressed: () => openExternalLink(contactLinkOf(student)),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
