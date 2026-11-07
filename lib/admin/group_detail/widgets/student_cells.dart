import 'package:cairo_coding_app/admin/insights/group_insights.dart';
import 'package:cairo_coding_app/admin/widgets/student_actions.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/initials_avatar.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:cairo_coding_app/data/services/attendance.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension StudentStandingLabels on StudentStanding {
  String get label => switch (this) {
    StudentStanding.active => 'admin.students.active'.tr(),
    StudentStanding.invited => 'admin.students.invited'.tr(),
    StudentStanding.inactive => 'admin.students.inactive'.tr(),
  };

  StatusTone get tone => switch (this) {
    StudentStanding.active => StatusTone.success,
    StudentStanding.invited => StatusTone.accent,
    StudentStanding.inactive => StatusTone.danger,
  };
}

/// Avatar, name and email in one cell.
class StudentNameCell extends StatelessWidget {
  const StudentNameCell({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InitialsAvatar(name: student.name),
        horizontalSpace(12),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(student.name, overflow: TextOverflow.ellipsis, style: AppTextStyles.font14ExtraBold),
              Text(
                student.email,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.font12Normal.secondary(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A short bar and the percentage; red under 70%.
class AttendanceCell extends StatelessWidget {
  const AttendanceCell({super.key, required this.rate});

  final double? rate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (rate == null) return Text('admin.students.no_data'.tr(), style: AppTextStyles.font12Normal.muted(context));
    final low = rate! < .7;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Gives way first when the column is narrow, so the percentage always shows.
        Flexible(
          child: SizedBox(
            width: 72,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: rate,
                minHeight: 6,
                color: low ? colorScheme.error : colorScheme.primary,
                backgroundColor: colorScheme.primary.withValues(alpha: .14),
              ),
            ),
          ),
        ),
        horizontalSpace(10),
        Text('${percent(rate!)}%', textDirection: TextDirection.ltr, style: AppTextStyles.monoFont12Bold),
      ],
    );
  }
}

/// Resend the set-password email, edit, and a menu for the rarer actions.
class StudentRowActions extends ConsumerWidget {
  const StudentRowActions({super.key, required this.student, required this.onRemove});

  final Student student;
  final VoidCallback onRemove;

  Future<void> _resendInvite(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(authRepositoryProvider).sendPasswordReset(student.email);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        showAppSnackBar(context, 'admin.students.invite_sent'.tr(args: [student.email]));
      case Err(:final failure):
        showAppSnackBar(context, failure.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invited = GroupInsights.standingOf(student) == StudentStanding.invited;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (invited)
          IconButton(
            tooltip: 'admin.students.resend'.tr(),
            onPressed: () => _resendInvite(context, ref),
            icon: const Icon(Icons.forward_to_inbox_outlined, size: 18),
          ),
        const SizedBox(width: 4),
        StudentEditButton(student: student),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          tooltip: 'admin.students.more'.tr(),
          icon: const Icon(Icons.more_horiz_rounded, size: 18),
          onSelected: (action) => action == 'remove' ? onRemove() : toggleStudentActive(context, ref, student),
          itemBuilder: (_) => [
            PopupMenuItem(value: 'remove', child: Text('admin.students.remove'.tr())),
            PopupMenuItem(
              value: 'active',
              child: Text((student.active ? 'admin.students.deactivate' : 'admin.students.activate').tr()),
            ),
          ],
        ),
      ],
    );
  }
}
