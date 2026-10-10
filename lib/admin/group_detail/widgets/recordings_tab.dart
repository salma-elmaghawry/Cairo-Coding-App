import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/group_detail/widgets/recording_form.dart';
import 'package:cairo_coding_app/admin/widgets/two_pane.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/link_launcher.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_data_table.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/recording.dart';
import 'package:easy_localization/easy_localization.dart';
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

  String _host(String url) => Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? url;

  @override
  Widget build(BuildContext context) {
    final recordings = ref.watch(groupRecordingsProvider(widget.group.id));
    final colorScheme = Theme.of(context).colorScheme;

    final table = switch (recordings) {
      AsyncError(:final error) => ErrorView(message: error.toString()),
      AsyncData(:final value) when value.isEmpty => EmptyView(
        message: 'admin.recordings.empty'.tr(),
        icon: Icons.smart_display_outlined,
      ),
      AsyncData(:final value) => AppDataTable(
        columns: [
          const AppTableColumn('#'),
          AppTableColumn('admin.recordings.title'.tr(), flex: 4),
          AppTableColumn('admin.recordings.date'.tr(), flex: 2),
          AppTableColumn('admin.recordings.link'.tr(), flex: 2),
          AppTableColumn('admin.students.actions'.tr(), flex: 2, alignEnd: true),
        ],
        rows: [
          for (final recording in value)
            [
              Text(
                '${recording.sessionNumber}'.padLeft(2, '0'),
                style: AppTextStyles.monoFont14Bold.copyWith(color: colorScheme.primary),
              ),
              Text(recording.title, style: AppTextStyles.font14Bold),
              Text(context.shortDay(recording.recordedAt), style: AppTextStyles.font14Normal.secondary(context)),
              TextButton.icon(
                onPressed: () => openExternalLink(recording.url),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(_host(recording.url), overflow: TextOverflow.ellipsis),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'admin.recordings.edit'.tr(),
                    onPressed: () => setState(() => _editing = recording),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'common.delete'.tr(),
                    style: IconButton.styleFrom(foregroundColor: colorScheme.error),
                    onPressed: () => _delete(recording),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  ),
                ],
              ),
            ],
        ],
      ),
      _ => const SkeletonList(count: 5, itemHeight: 52),
    };

    return TwoPane(
      main: table,
      side: RecordingForm(
        key: ValueKey(_editing?.id),
        group: widget.group,
        editing: _editing,
        onDone: () => setState(() => _editing = null),
      ),
    );
  }
}
