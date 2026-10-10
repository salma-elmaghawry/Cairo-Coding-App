import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/link_launcher.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/eyebrow_text.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/student/home/widgets/countdown_text.dart';
import 'package:cairo_coding_app/shared/session_labels.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class NextSessionCard extends StatelessWidget {
  const NextSessionCard({super.key, required this.session, required this.group});

  final ClassSession session;
  final AcademyGroup? group;

  Future<void> _join(BuildContext context) async {
    final link = session.meetingLinkOverride ?? group?.meetingLink ?? '';
    final opened = await openExternalLink(link);
    if (!opened && context.mounted) {
      showAppSnackBar(context, 'errors.open_link_failed'.tr(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeRange = '${context.time(session.startsAt)} – ${context.time(session.endsAt)}';

    return AppCard(
      padding: const EdgeInsets.all(20),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: EyebrowText('home.next_session'.tr())),
              Text(
                [?group?.name, session.title].join(' · '),
                style: AppTextStyles.monoFont12Medium.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          verticalSpace(14),
          Text(context.fullDay(session.startsAt), style: AppTextStyles.font22ExtraBold),
          verticalSpace(4),
          Text(timeRange, style: AppTextStyles.font16Normal.secondary(context)),
          verticalSpace(16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Row(
              children: [
                Text('home.starts_in'.tr(), style: AppTextStyles.font14Normal.secondary(context)),
                horizontalSpace(12),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: CountdownText(session: session),
                    ),
                  ),
                ),
              ],
            ),
          ),
          verticalSpace(14),
          _InfoRow(icon: Icons.videocam_outlined, text: group?.location ?? ''),
          verticalSpace(8),
          _InfoRow(icon: Icons.notifications_none_rounded, text: 'home.reminders'.tr()),
          verticalSpace(18),
          PrimaryButton(label: 'home.join'.tr(), icon: Icons.videocam_rounded, onPressed: () => _join(context)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        horizontalSpace(10),
        Expanded(child: Text(text, style: AppTextStyles.font14Normal.secondary(context))),
      ],
    );
  }
}
