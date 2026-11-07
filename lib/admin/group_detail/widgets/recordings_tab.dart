import 'package:cairo_coding_app/admin/group_detail/widgets/recording_card.dart';
import 'package:cairo_coding_app/admin/group_detail/widgets/recording_form.dart';
import 'package:cairo_coding_app/admin/insights/group_insights.dart';
import 'package:cairo_coding_app/admin/widgets/admin_panel.dart';
import 'package:cairo_coding_app/admin/widgets/card_grid.dart';
import 'package:cairo_coding_app/admin/widgets/two_pane.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/recording.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecordingsTab extends ConsumerStatefulWidget {
  const RecordingsTab({super.key, required this.group});

  final AcademyGroup group;

  @override
  ConsumerState<RecordingsTab> createState() => _RecordingsTabState();
}

class _RecordingsTabState extends ConsumerState<RecordingsTab> {
  Recording? _editing;
  bool _grid = true;

  Future<void> _delete(Recording recording) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.recordings.delete_title'.tr(),
      message: 'admin.recordings.delete_message'.tr(args: [recording.title]),
      confirmLabel: 'common.delete'.tr(),
      cancelLabel: 'common.cancel'.tr(),
      destructive: true,
    );
    if (!confirmed) return;
    final result = await ref.read(academyRepositoryProvider).deleteRecording(recording);
    if (!mounted) return;
    if (result case Err(:final failure)) showAppSnackBar(context, failure.message, isError: true);
    if (_editing?.id == recording.id) setState(() => _editing = null);
  }

  @override
  Widget build(BuildContext context) {
    final insights = ref.watch(groupInsightsProvider(widget.group.id));
    final colorScheme = Theme.of(context).colorScheme;
    final form = RecordingForm(
      key: ValueKey(_editing?.id),
      group: widget.group,
      editing: _editing,
      onDone: () => setState(() => _editing = null),
    );
    if (insights == null) return TwoPane(main: const SkeletonList(count: 4, itemHeight: 64), side: form);

    final recordings = insights.recordings;
    final missing = insights.missingRecordings;
    Widget toggle(bool grid, IconData icon, String tooltip) => IconButton(
      tooltip: tooltip,
      isSelected: _grid == grid,
      style: IconButton.styleFrom(
        side: BorderSide.none,
        backgroundColor: _grid == grid ? colorScheme.primary : null,
        foregroundColor: _grid == grid ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
        minimumSize: const Size(34, 30),
      ),
      onPressed: () => setState(() => _grid = grid),
      icon: Icon(icon, size: 18),
    );

    final main = AdminPanel(
      title: 'admin.recordings.count'.tr(args: ['${recordings.length}']),
      subtitle: missing.isEmpty
          ? 'admin.recordings.all_covered'.tr()
          : 'admin.recordings.missing'.tr(args: ['${missing.length}']),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          toggle(true, Icons.grid_view_rounded, 'admin.recordings.grid'.tr()),
          horizontalSpace(4),
          toggle(false, Icons.view_list_rounded, 'admin.recordings.list'.tr()),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Banner(
            text: missing.isEmpty
                ? 'admin.recordings.reminder_on'.tr()
                : 'admin.recordings.missing_list'.tr(
                    args: [
                      missing
                          .map((s) => '#${'${s.number}'.padLeft(2, '0')} ${context.shortDay(s.startsAt)}')
                          .join(', '),
                    ],
                  ),
            warning: missing.isNotEmpty,
          ),
          verticalSpace(16),
          if (recordings.isEmpty)
            EmptyView(message: 'admin.recordings.empty'.tr(), icon: Icons.smart_display_outlined)
          else if (_grid)
            CardGrid(
              minItemWidth: 260,
              children: [
                for (final recording in recordings)
                  RecordingCard(
                    recording: recording,
                    watched: insights.viewersOf(recording),
                    members: insights.members.length,
                    onEdit: () => setState(() => _editing = recording),
                    onDelete: () => _delete(recording),
                  ),
              ],
            )
          else
            for (final recording in recordings) _row(context, insights, recording),
        ],
      ),
    );

    return TwoPane(main: main, side: form);
  }

  Widget _row(BuildContext context, GroupInsights insights, Recording recording) {
    final colorScheme = Theme.of(context).colorScheme;
    final length = recordingLength(recording.durationMin);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Text(
              '${recording.sessionNumber}'.padLeft(2, '0'),
              style: AppTextStyles.monoFont14Bold.copyWith(color: colorScheme.primary),
            ),
          ),
          horizontalSpace(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.bidi(recording.title), style: AppTextStyles.font14ExtraBold),
                Text(
                  [
                    context.shortDay(recording.recordedAt),
                    if (length.isNotEmpty) length,
                    recordingHost(recording.url),
                  ].join(' · '),
                  style: AppTextStyles.font12Normal.secondary(context),
                ),
              ],
            ),
          ),
          Text(
            'admin.recordings.watched'.tr(args: ['${insights.viewersOf(recording)}/${insights.members.length}']),
            style: AppTextStyles.font12SemiBold.secondary(context),
          ),
          horizontalSpace(8),
          RecordingActions(
            recording: recording,
            onEdit: () => setState(() => _editing = recording),
            onDelete: () => _delete(recording),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.warning});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tint = warning ? colorScheme.tertiary : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          Icon(
            warning ? Icons.notification_important_outlined : Icons.notifications_active_outlined,
            size: 18,
            color: tint,
          ),
          horizontalSpace(10),
          Expanded(child: Text(text, style: AppTextStyles.font13Normal)),
        ],
      ),
    );
  }
}
