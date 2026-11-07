import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/shared/session_labels.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// One session on the schedule's timeline: a node on the rail and a card beside it.
class TimelineSession extends StatelessWidget {
  const TimelineSession({
    super.key,
    required this.session,
    required this.focused,
    required this.isLast,
    this.badge,
    this.groupName,
    this.onTap,
  });

  final ClassSession session;

  /// On the day picked in the week strip.
  final bool focused;
  final bool isLast;
  final (String, StatusTone)? badge;
  final String? groupName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 14,
            child: Column(
              children: [
                verticalSpace(20),
                AnimatedContainer(
                  duration: AppAnimations.fast,
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: focused ? colorScheme.primary : Theme.of(context).scaffoldBackgroundColor,
                    border: focused ? null : Border.all(color: colorScheme.primary.withValues(alpha: .55), width: 2),
                    boxShadow: [
                      if (focused) BoxShadow(color: colorScheme.primary.withValues(alpha: .25), spreadRadius: 4),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 4),
                      color: colorScheme.primary.withValues(alpha: .18),
                    ),
                  ),
              ],
            ),
          ),
          horizontalSpace(14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Opacity(opacity: session.isCancelled ? .65 : 1, child: _card(context, colorScheme)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, ColorScheme colorScheme) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final when = [context.shortDay(session.startsAt).toUpperCase(), ?groupName].join(' · ');
    final title = [session.title, if (session.topic.isNotEmpty) context.bidi(session.topic)].join(' · ');
    final time = '${context.time(session.startsAt)} – ${context.time(session.endsAt)} · ${session.durationLabel}';

    return AnimatedContainer(
      duration: AppAnimations.fast,
      decoration: BoxDecoration(
        color: focused ? colorScheme.surface : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: focused ? colorScheme.primary.withValues(alpha: .55) : colorScheme.outline),
        boxShadow: [
          if (focused)
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: .35),
              blurRadius: 28,
              spreadRadius: -16,
              offset: const Offset(0, 12),
            ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        when,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: (isRtl ? AppTextStyles.font12Bold : AppTextStyles.monoFont12Medium).copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    if (badge case (final label, final tone)) ...[
                      horizontalSpace(8),
                      StatusChip(label: label, tone: tone),
                    ],
                  ],
                ),
                verticalSpace(6),
                Text(
                  title,
                  style: AppTextStyles.font15ExtraBold.copyWith(
                    height: 1.3,
                    decoration: session.isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                verticalSpace(6),
                _Line(icon: Icons.schedule_rounded, text: time),
                if (session.instructor.isNotEmpty) ...[
                  verticalSpace(4),
                  _Line(
                    icon: Icons.person_outline_rounded,
                    text: 'session.with'.tr(args: [session.instructor.isolated]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        horizontalSpace(6),
        Expanded(child: Text(text, style: AppTextStyles.font13Normal.secondary(context))),
      ],
    );
  }
}
