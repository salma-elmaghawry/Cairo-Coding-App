import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/initials_avatar.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:cairo_coding_app/shared/session_labels.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Takes or corrects attendance for one session. Students who joined from the app are already ticked.
class AttendanceDialog extends ConsumerStatefulWidget {
  const AttendanceDialog({super.key, required this.session, required this.students});

  final ClassSession session;
  final List<Student> students;

  static Future<void> show(BuildContext context, {required ClassSession session, required List<Student> students}) =>
      showDialog<void>(
        context: context,
        builder: (_) => AttendanceDialog(session: session, students: students),
      );

  @override
  ConsumerState<AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends ConsumerState<AttendanceDialog> {
  late final Set<String> _present = {...?widget.session.attendees};
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await ref.read(academyRepositoryProvider).setAttendance(widget.session, _present.toList());
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        showAppSnackBar(context, 'admin.attendance.saved'.tr());
        Navigator.of(context).pop();
      case Err(:final failure):
        showAppSnackBar(context, failure.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.students.every((s) => _present.contains(s.uid));

    return AlertDialog(
      title: Text('admin.attendance.title'.tr(args: [widget.session.title])),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'admin.attendance.hint'.tr(args: [context.fullDay(widget.session.startsAt)]),
              style: AppTextStyles.font13Normal.secondary(context),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: all,
              title: Text(
                'admin.attendance.count'.tr(args: ['${_present.length}', '${widget.students.length}']),
                style: AppTextStyles.font14ExtraBold,
              ),
              onChanged: (value) => setState(() {
                if (value ?? false) {
                  _present.addAll(widget.students.map((s) => s.uid));
                } else {
                  _present.removeAll(widget.students.map((s) => s.uid));
                }
              }),
            ),
            const Divider(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final student in widget.students)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _present.contains(student.uid),
                      secondary: InitialsAvatar(name: student.name, size: 32),
                      title: Text(student.name, style: AppTextStyles.font14Bold),
                      onChanged: (value) =>
                          setState(() => (value ?? false) ? _present.add(student.uid) : _present.remove(student.uid)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('common.cancel'.tr())),
        ElevatedButton(onPressed: _saving ? null : _save, child: Text('common.save'.tr())),
      ],
    );
  }
}
