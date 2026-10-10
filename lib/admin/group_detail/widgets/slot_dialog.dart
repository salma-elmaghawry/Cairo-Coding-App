import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/data/models/weekly_slot.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SlotDialog extends StatefulWidget {
  const SlotDialog({super.key});

  static Future<WeeklySlot?> show(BuildContext context) =>
      showDialog<WeeklySlot>(context: context, builder: (_) => const SlotDialog());

  @override
  State<SlotDialog> createState() => _SlotDialogState();
}

class _SlotDialogState extends State<SlotDialog> {
  static const _durations = [60, 90, 120, 150, 180];
  int _weekday = DateTime.sunday;
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 0);
  int _duration = 120;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('admin.schedule.add_slot'.tr()),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('admin.schedule.day'.tr(), style: AppTextStyles.font14Bold),
            verticalSpace(8),
            DropdownButtonFormField<int>(
              initialValue: _weekday,
              items: [
                for (var day = DateTime.monday; day <= DateTime.sunday; day++)
                  DropdownMenuItem(value: day, child: Text(context.weekdayName(day))),
              ],
              onChanged: (value) => setState(() => _weekday = value ?? _weekday),
            ),
            verticalSpace(14),
            Text('admin.schedule.time'.tr(), style: AppTextStyles.font14Bold),
            verticalSpace(8),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showTimePicker(context: context, initialTime: _time);
                if (picked != null) setState(() => _time = picked);
              },
              icon: const Icon(Icons.schedule_rounded, size: 18),
              label: Text(context.timeOfDay(_time.hour, _time.minute)),
            ),
            verticalSpace(14),
            Text('admin.schedule.duration'.tr(), style: AppTextStyles.font14Bold),
            verticalSpace(8),
            DropdownButtonFormField<int>(
              initialValue: _duration,
              items: [
                for (final minutes in _durations)
                  DropdownMenuItem(
                    value: minutes,
                    child: Text('session.minutes'.tr(args: ['$minutes'])),
                  ),
              ],
              onChanged: (value) => setState(() => _duration = value ?? _duration),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('common.cancel'.tr())),
        TextButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(WeeklySlot(weekday: _weekday, hour: _time.hour, minute: _time.minute, durationMin: _duration)),
          child: Text('common.add'.tr()),
        ),
      ],
    );
  }
}
