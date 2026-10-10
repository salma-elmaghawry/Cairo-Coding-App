import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/date_badge.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/shared/session_labels.dart';
import 'package:flutter/material.dart';

class SessionTile extends StatelessWidget {
  const SessionTile({super.key, required this.session, this.groupName, this.badge});

  final ClassSession session;
  final String? groupName;
  final (String, StatusTone)? badge;

  @override
  Widget build(BuildContext context) {
    final cancelled = session.isCancelled;
    final effectiveBadge = badge ?? session.statusBadge;
    final subtitle = [context.time(session.startsAt), session.durationLabel, ?groupName].join(' · ');

    return Opacity(
      opacity: cancelled ? .7 : 1,
      child: Row(
        children: [
          DateBadge(
            top: context.weekdayShort(session.startsAt).toUpperCase(),
            bottom: context.dayNumber(session.startsAt),
            size: 48,
          ),
          horizontalSpace(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: AppTextStyles.font16Bold.copyWith(decoration: cancelled ? TextDecoration.lineThrough : null),
                ),
                verticalSpace(2),
                Text(subtitle, style: AppTextStyles.font14Normal.secondary(context)),
              ],
            ),
          ),
          if (effectiveBadge != null) ...[
            horizontalSpace(8),
            StatusChip(label: effectiveBadge.$1, tone: effectiveBadge.$2),
          ],
        ],
      ),
    );
  }
}
