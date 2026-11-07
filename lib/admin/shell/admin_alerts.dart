import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/insights/group_insights.dart';
import 'package:cairo_coding_app/admin/quizzes/quiz_admin_providers.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum AlertKind { noRecording, fallingBehind, quizClosing }

/// Something that needs the admin's attention, kept as data so it's worded in the current language.
class AdminAlert {
  const AdminAlert(this.kind, this.args, this.route);

  final AlertKind kind;
  final List<String> args;
  final String route;

  IconData get icon => switch (kind) {
    AlertKind.noRecording => Icons.videocam_off_outlined,
    AlertKind.fallingBehind => Icons.person_off_outlined,
    AlertKind.quizClosing => Icons.timer_outlined,
  };

  String get text => switch (kind) {
    AlertKind.noRecording => 'admin.alerts.no_recording'.tr(args: args),
    AlertKind.fallingBehind => 'admin.alerts.falling_behind'.tr(args: args),
    AlertKind.quizClosing => 'admin.alerts.quiz_closing'.tr(args: args),
  };
}

final adminAlertsProvider = Provider.autoDispose<List<AdminAlert>>((ref) {
  final now = ref.watch(clockProvider)();
  final quizzes = ref.watch(adminQuizzesProvider).value ?? const <Quiz>[];
  return [
    for (final insights in ref.watch(activeInsightsProvider)) ...[
      for (final session in insights.missingRecordings)
        AdminAlert(AlertKind.noRecording, [
          insights.group.name,
          '${session.number}'.padLeft(2, '0'),
        ], AdminRoutes.group(insights.group.id, GroupTab.recordings)),
      if (insights.fallingBehind.isNotEmpty)
        AdminAlert(AlertKind.fallingBehind, [
          '${insights.fallingBehind.length}',
          insights.group.name,
        ], AdminRoutes.group(insights.group.id)),
    ],
    for (final quiz in quizzes)
      if (quiz.isPublished && quiz.isOpen(now) && quiz.closesAt.difference(now).inHours < 24)
        AdminAlert(AlertKind.quizClosing, [
          quiz.title,
          '${quiz.closesAt.difference(now).inHours}',
        ], AdminRoutes.quizAnalytics(quiz.id)),
  ];
});

/// The bell in the top bar, with how many alerts there are and a menu listing them.
class AlertsButton extends ConsumerWidget {
  const AlertsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(adminAlertsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: 'admin.alerts.title'.tr(),
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 360),
      onSelected: (route) => context.go(route),
      itemBuilder: (context) => alerts.isEmpty
          ? [PopupMenuItem<String>(enabled: false, child: Text('admin.alerts.none'.tr()))]
          : [
              for (final alert in alerts)
                PopupMenuItem(
                  value: alert.route,
                  child: Row(
                    children: [
                      Icon(alert.icon, size: 18, color: colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(child: Text(alert.text, style: AppTextStyles.font13Normal)),
                    ],
                  ),
                ),
            ],
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_none_rounded, size: 20),
            if (alerts.isNotEmpty)
              PositionedDirectional(
                top: -6,
                end: -6,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                  ),
                  child: Text(
                    '${alerts.length}',
                    style: AppTextStyles.monoFont10Medium.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Today's date for the top bar.
class TodayLabel extends ConsumerWidget {
  const TodayLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(minuteTickerProvider).value ?? ref.watch(clockProvider)();
    return Text(context.shortDay(now), style: AppTextStyles.font13ExtraBold.secondary(context));
  }
}
