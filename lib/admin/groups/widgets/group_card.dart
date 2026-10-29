import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/groups/widgets/group_form_dialog.dart';
import 'package:cairo_coding_app/admin/widgets/slot_labels.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _GroupAction { edit, archive }

class GroupCard extends ConsumerWidget {
  const GroupCard({super.key, required this.group});

  final AcademyGroup group;

  Future<void> _onAction(BuildContext context, WidgetRef ref, _GroupAction action) async {
    switch (action) {
      case _GroupAction.edit:
        await GroupFormDialog.show(context, group: group);
      case _GroupAction.archive:
        final result = await ref.read(academyRepositoryProvider).setArchived(group, !group.archived);
        if (!context.mounted) return;
        if (result case Err(:final failure)) showAppSnackBar(context, failure.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final studentCount = ref.watch(groupStudentsProvider(group.id).select((value) => value.value?.length));
    final next = ref.watch(groupNextSessionProvider(group.id));
    final course = ref.watch(courseProvider(group.courseId)).value;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, style: AppTextStyles.monoFont20Bold.copyWith(color: colorScheme.primary)),
                    Text(
                      course?.name ?? 'admin.groups.no_course'.tr(),
                      style: course == null ? AppTextStyles.font16Bold.secondary(context) : AppTextStyles.font16Bold,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_GroupAction>(
                tooltip: 'admin.groups.actions'.tr(),
                onSelected: (action) => _onAction(context, ref, action),
                itemBuilder: (_) => [
                  PopupMenuItem(value: _GroupAction.edit, child: Text('admin.groups.edit'.tr())),
                  PopupMenuItem(
                    value: _GroupAction.archive,
                    child: Text((group.archived ? 'admin.groups.unarchive' : 'admin.groups.archive').tr()),
                  ),
                ],
              ),
            ],
          ),
          verticalSpace(16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _Stat(label: 'admin.groups.students'.tr(), value: studentCount?.toString() ?? '…', mono: true),
              _Stat(label: 'admin.groups.weekly'.tr(), value: context.slotsSummary(group.weeklySlots)),
              _Stat(label: 'admin.groups.runs'.tr(), value: context.monthRange(group.startDate, group.endDate)),
              _Stat(
                label: 'admin.groups.next_session'.tr(),
                value: next == null ? '—' : context.shortDay(next.startsAt),
              ),
            ],
          ),
          verticalSpace(18),
          OutlinedButton.icon(
            onPressed: () => context.go(AdminRoutes.group(group.id)),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text('admin.groups.open'.tr()),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.font12Normal.secondary(context)),
        Text(value, style: mono ? AppTextStyles.monoFont16Bold : AppTextStyles.font14Bold),
      ],
    );
  }
}
