import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/group_detail/widgets/session_details_dialog.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/pickers.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_data_table.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/shared/session_labels.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionsTable extends ConsumerWidget {
  const SessionsTable({super.key, required this.group});

  final AcademyGroup group;

  Future<void> _run(BuildContext context, Future<Result<void>> action) async {
    final result = await action;
    if (!context.mounted) return;
    if (result case Err(:final failure)) showAppSnackBar(context, failure.message, isError: true);
  }

  Future<void> _reschedule(BuildContext context, WidgetRef ref, ClassSession session) async {
    final picked = await pickDateTime(context, initial: session.startsAt);
    if (picked == null || !context.mounted) return;
    await _run(context, ref.read(academyRepositoryProvider).reschedule(session, picked));
  }

  Future<void> _addExtra(BuildContext context, WidgetRef ref) async {
    final picked = await pickDateTime(context, initial: ref.read(clockProvider)());
    if (picked == null || !context.mounted) return;
    final duration = group.weeklySlots.firstOrNull?.durationMin ?? 120;
    await _run(context, ref.read(academyRepositoryProvider).addExtraSession(group, picked, duration));
  }

  void _editDetails(BuildContext context, List<ClassSession> sessions, ClassSession session) {
    final before = sessions.takeWhile((s) => s.id != session.id);
    final suggested = before.lastWhere((s) => s.instructor.isNotEmpty, orElse: () => session).instructor;
    SessionDetailsDialog.show(context, session, suggestedInstructor: suggested);
  }

  (String, StatusTone) _status(ClassSession session, bool past) => switch (session.status) {
    SessionStatus.cancelled => ('session.status.cancelled'.tr(), StatusTone.danger),
    _ when past => ('session.status.done'.tr(), StatusTone.neutral),
    SessionStatus.moved => ('session.status.moved'.tr(), StatusTone.neutral),
    SessionStatus.extra => ('session.status.extra'.tr(), StatusTone.accent),
    SessionStatus.scheduled => ('session.status.scheduled'.tr(), StatusTone.accent),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(groupSessionsProvider(group.id));
    final now = ref.watch(clockProvider)();
    final repository = ref.read(academyRepositoryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('admin.schedule.sessions_title'.tr(), style: AppTextStyles.font18ExtraBold)),
            OutlinedButton.icon(
              onPressed: () => _addExtra(context, ref),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('admin.schedule.extra'.tr()),
            ),
          ],
        ),
        verticalSpace(12),
        switch (sessions) {
          AsyncError(:final error) => ErrorView(message: error.toString()),
          AsyncData(:final value) when value.isEmpty => EmptyView(
            message: 'admin.schedule.empty'.tr(),
            icon: Icons.event_note_outlined,
          ),
          AsyncData(:final value) => AppDataTable(
            minWidth: 720,
            dimmedRows: {
              for (final (index, session) in value.indexed)
                if (session.isPast(now) || session.isCancelled) index,
            },
            columns: [
              const AppTableColumn('#'),
              AppTableColumn('admin.schedule.date'.tr(), flex: 2),
              AppTableColumn('admin.schedule.time'.tr(), flex: 2),
              AppTableColumn('admin.schedule.topic'.tr(), flex: 4),
              AppTableColumn('admin.students.status'.tr(), flex: 2),
              AppTableColumn('admin.students.actions'.tr(), flex: 4, alignEnd: true),
            ],
            rows: [
              for (final session in value)
                () {
                  final past = session.isPast(now);
                  final status = _status(session, past);
                  return [
                    Text(
                      session.number?.toString().padLeft(2, '0') ?? '—',
                      style: AppTextStyles.monoFont14Bold.copyWith(color: colorScheme.primary),
                    ),
                    Text(
                      context.shortDay(session.startsAt),
                      style: AppTextStyles.font14Bold.copyWith(
                        decoration: session.isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      '${context.time(session.startsAt)} · ${session.durationLabel}',
                      style: AppTextStyles.font14Normal.secondary(context),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.topic.isEmpty ? '—' : session.topic,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font14SemiBold,
                              ),
                              if (session.instructor.isNotEmpty)
                                Text(
                                  'session.by'.tr(args: [session.instructor]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.font12Normal.secondary(context),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          style: IconButton.styleFrom(side: BorderSide.none),
                          tooltip: 'admin.schedule.edit_details'.tr(),
                          onPressed: () => _editDetails(context, value, session),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                        ),
                      ],
                    ),
                    StatusChip(label: status.$1, tone: status.$2),
                    if (past)
                      const SizedBox.shrink()
                    else
                      Wrap(
                        spacing: 6,
                        children: [
                          TextButton(
                            onPressed: session.isCancelled ? null : () => _reschedule(context, ref, session),
                            child: Text('admin.schedule.reschedule'.tr()),
                          ),
                          TextButton(
                            style: session.isCancelled
                                ? null
                                : TextButton.styleFrom(foregroundColor: colorScheme.error),
                            onPressed: () => _run(
                              context,
                              repository.setSessionStatus(
                                session,
                                session.isCancelled
                                    ? (session.number == null ? SessionStatus.extra : SessionStatus.scheduled)
                                    : SessionStatus.cancelled,
                              ),
                            ),
                            child: Text(
                              (session.isCancelled ? 'admin.schedule.restore' : 'admin.schedule.cancel').tr(),
                            ),
                          ),
                        ],
                      ),
                  ];
                }(),
            ],
          ),
          _ => const SkeletonList(count: 6, itemHeight: 48),
        },
      ],
    );
  }
}
