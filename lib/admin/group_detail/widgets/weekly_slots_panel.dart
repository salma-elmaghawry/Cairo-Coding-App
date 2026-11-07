import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/group_detail/widgets/slot_dialog.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/admin/widgets/admin_panel.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/weekly_slot.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeeklySlotsPanel extends ConsumerStatefulWidget {
  const WeeklySlotsPanel({super.key, required this.group});

  final AcademyGroup group;

  @override
  ConsumerState<WeeklySlotsPanel> createState() => _WeeklySlotsPanelState();
}

class _WeeklySlotsPanelState extends ConsumerState<WeeklySlotsPanel> {
  late List<WeeklySlot> _slots = [...widget.group.weeklySlots];
  bool _saving = false;

  Future<void> _addSlot() async {
    final slot = await SlotDialog.show(context);
    if (slot == null) return;
    setState(
      () =>
          _slots = [..._slots, slot]
            ..sort((a, b) => (a.weekday * 1440 + a.minuteOfDay).compareTo(b.weekday * 1440 + b.minuteOfDay)),
    );
  }

  Future<void> _generate() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.schedule.generate_title'.tr(),
      message: 'admin.schedule.generate_message'.tr(),
      confirmLabel: 'admin.schedule.generate'.tr(),
      cancelLabel: 'common.cancel'.tr(),
    );
    if (!confirmed || !mounted) return;
    setState(() => _saving = true);
    final course = ref.read(courseProvider(widget.group.courseId)).value;
    final result = await ref.read(academyRepositoryProvider).saveSlotsAndGenerate(widget.group, _slots, course: course);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok(:final value):
        showAppSnackBar(context, 'admin.schedule.generated'.tr(args: ['$value']));
      case Err(:final failure):
        showAppSnackBar(context, failure.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AdminPanel(
      title: 'admin.schedule.slots_title'.tr(),
      subtitle: 'admin.schedule.slots_hint'.tr(),
      trailing: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36), foregroundColor: colorScheme.primary),
        onPressed: _addSlot,
        icon: const Icon(Icons.add_rounded, size: 16),
        label: Text('admin.schedule.add_slot'.tr()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final slot in _slots) ...[
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 6, 10),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          context.weekdayShortName(slot.weekday).toUpperCase(),
                          style: AppTextStyles.monoFont12Bold.copyWith(color: colorScheme.primary),
                        ),
                      ),
                    ),
                  ),
                  horizontalSpace(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${context.timeOfDay(slot.hour, slot.minute)} – '
                          '${context.timeOfDay((slot.minuteOfDay + slot.durationMin) ~/ 60 % 24, (slot.minuteOfDay + slot.durationMin) % 60)}',
                          style: AppTextStyles.font14ExtraBold,
                        ),
                        Text(
                          [
                            'session.minutes'.tr(args: ['${slot.durationMin}']),
                            if (widget.group.location.isNotEmpty) widget.group.location,
                          ].join(' · '),
                          style: AppTextStyles.font12Normal.secondary(context),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(side: BorderSide.none),
                    tooltip: 'admin.schedule.remove_slot'.tr(),
                    onPressed: () => setState(() => _slots = _slots.where((s) => s != slot).toList()),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
            ),
            verticalSpace(8),
          ],
          verticalSpace(6),
          PrimaryButton(
            label: 'admin.schedule.generate'.tr(),
            height: 48,
            isLoading: _saving,
            onPressed: _slots.isEmpty ? null : _generate,
          ),
          verticalSpace(12),
          Text('admin.schedule.generate_note'.tr(), style: AppTextStyles.font12Normal.secondary(context)),
        ],
      ),
    );
  }
}
