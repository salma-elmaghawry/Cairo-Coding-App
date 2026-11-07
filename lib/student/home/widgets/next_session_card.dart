import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/link_launcher.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/hero_card.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/shared/session_labels.dart';
import 'package:cairo_coding_app/student/home/widgets/countdown_grid.dart';
import 'package:cairo_coding_app/student/reminders/reminder_providers.dart';
import 'package:cairo_coding_app/student/student_activity.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NextSessionCard extends ConsumerWidget {
  const NextSessionCard({super.key, required this.session, required this.group});

  final ClassSession session;
  final AcademyGroup? group;

  Future<void> _join(BuildContext context, WidgetRef ref) async {
    final override = session.meetingLinkOverride?.trim() ?? '';
    final link = override.isNotEmpty ? override : group?.meetingLink ?? '';
    final opened = await openExternalLink(link);
    // Joining the call is what marks the student present.
    if (opened) ref.read(studentActivityProvider).joined(session);
    if (!opened && context.mounted) {
      showAppSnackBar(context, 'errors.open_link_failed'.tr(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasTopic = session.topic.isNotEmpty;
    final number = session.number == null ? null : '#${'${session.number}'.padLeft(2, '0')}';
    final when =
        '${context.shortDay(session.startsAt)} · '
        '${context.time(session.startsAt)} – ${context.time(session.endsAt)}';
    final location = group?.location ?? '';

    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _NextPill(),
              horizontalSpace(8),
              Expanded(
                child: Text(
                  [?group?.name, number ?? session.title].join(' · '),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.monoFont12Medium.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          verticalSpace(16),
          Text(
            hasTopic ? context.bidi(session.topic) : session.title,
            style: AppTextStyles.font22ExtraBold.copyWith(height: 1.2),
          ),
          verticalSpace(8),
          _InfoRow(icon: Icons.calendar_today_outlined, text: when),
          if (session.instructor.isNotEmpty) ...[
            verticalSpace(6),
            _InfoRow(
              icon: Icons.person_outline_rounded,
              text: 'session.with'.tr(args: [session.instructor.isolated]),
            ),
          ],
          verticalSpace(16),
          CountdownGrid(session: session),
          verticalSpace(16),
          if (location.isNotEmpty) ...[_InfoRow(icon: Icons.videocam_outlined, text: location), verticalSpace(6)],
          if (ref.watch(remindersEnabledProvider)) ...[
            _InfoRow(icon: Icons.notifications_none_rounded, text: 'home.reminders'.tr()),
            verticalSpace(6),
          ],
          verticalSpace(10),
          PrimaryButton(
            label: 'home.join'.tr(),
            icon: Icons.videocam_rounded,
            glow: true,
            onPressed: () => _join(context, ref),
          ),
        ],
      ),
    );
  }
}

class _NextPill extends StatelessWidget {
  const _NextPill();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final dot = Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.primary),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.primary.withValues(alpha: .3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              if (!MediaQuery.disableAnimationsOf(context))
                dot
                    .animate(onPlay: (controller) => controller.repeat())
                    .scaleXY(begin: 1, end: 2.6, duration: 1800.ms, curve: Curves.easeOut)
                    .fadeOut(duration: 1800.ms, curve: Curves.easeOut),
              dot,
            ],
          ),
          horizontalSpace(8),
          Text(
            'home.next_session'.tr().toUpperCase(),
            style: (isRtl ? AppTextStyles.font11ExtraBold : AppTextStyles.monoFont11Bold).copyWith(
              color: colorScheme.secondary,
              letterSpacing: isRtl ? 0 : .66,
            ),
          ),
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
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        horizontalSpace(8),
        Expanded(child: Text(text, style: AppTextStyles.font14Normal.secondary(context))),
      ],
    );
  }
}
