import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/group_detail/widgets/slot_dialog.dart';
import 'package:cairo_coding_app/admin/widgets/slot_labels.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
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

    return AppCard(
      color: colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('admin.schedule.slots_title'.tr(), style: AppTextStyles.font18ExtraBold),
          Text('admin.schedule.slots_hint'.tr(), style: AppTextStyles.font12Normal.secondary(context)),
          verticalSpace(14),
          for (final slot in _slots) ...[
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 6, 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${context.slotLabel(slot)} · ${'session.minutes'.tr(args: ['${slot.durationMin}'])}',
                      style: AppTextStyles.font14Bold,
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
          OutlinedButton.icon(
            onPressed: _addSlot,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('admin.schedule.add_slot'.tr()),
          ),
          verticalSpace(12),
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
