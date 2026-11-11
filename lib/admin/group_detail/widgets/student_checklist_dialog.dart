import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/initials_avatar.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:cairo_coding_app/data/repositories/academy_repository.dart';
import 'package:cairo_coding_app/shared/session_labels.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef ChecklistSave = Future<Result<void>> Function(AcademyRepository repository, List<String> uids);

/// An extra action that removes the record altogether, such as taking a task off a session.
typedef ChecklistClear = ({String label, String message, Future<Result<void>> Function(AcademyRepository) run});

/// Takes or corrects attendance for one session. Students who joined from the app are already ticked.
abstract final class AttendanceDialog {
  static Future<void> show(BuildContext context, {required ClassSession session, required List<Student> students}) =>
      showDialog<void>(
        context: context,
        builder: (context) => StudentChecklistDialog(
          title: 'admin.attendance.title'.tr(args: [session.title]),
          hint: 'admin.attendance.hint'.tr(args: [context.fullDay(session.startsAt)]),
          countKey: 'admin.attendance.count',
          savedMessage: 'admin.attendance.saved'.tr(),
          students: students,
          initial: {...?session.attendees},
          save: (repository, uids) => repository.setAttendance(session, uids),
        ),
      );
}

/// Ticks who handed in the session's task. Saving with nobody ticked still counts as a task nobody handed in;
/// "No task" takes it off the session so it leaves the students' tasks rate.
abstract final class TaskDialog {
  static Future<void> show(BuildContext context, {required ClassSession session, required List<Student> students}) =>
      showDialog<void>(
        context: context,
        builder: (context) => StudentChecklistDialog(
          title: 'admin.tasks.title'.tr(args: [session.title]),
          hint: 'admin.tasks.hint'.tr(args: [context.fullDay(session.startsAt)]),
          countKey: 'admin.tasks.count',
          savedMessage: 'admin.tasks.saved'.tr(),
          students: students,
          initial: {...?session.taskDoneBy},
          save: (repository, uids) => repository.setTaskDoneBy(session, uids),
          clear: session.hasTask
              ? (
                  label: 'admin.tasks.clear'.tr(),
                  message: 'admin.tasks.cleared'.tr(),
                  run: (repository) => repository.setTaskDoneBy(session, null),
                )
              : null,
        ),
      );
}

/// A list of students to tick, with "everyone" on top. Saves the ticked uids through [save].
class StudentChecklistDialog extends ConsumerStatefulWidget {
  const StudentChecklistDialog({
    super.key,
    required this.title,
    required this.hint,
    required this.countKey,
    required this.savedMessage,
    required this.students,
    required this.initial,
    required this.save,
    this.clear,
  });

  final String title;
  final String hint;

  /// A translation key that takes the ticked count and the number of students.
  final String countKey;
  final String savedMessage;
  final List<Student> students;
  final Set<String> initial;
  final ChecklistSave save;
  final ChecklistClear? clear;

  @override
  ConsumerState<StudentChecklistDialog> createState() => _StudentChecklistDialogState();
}

class _StudentChecklistDialogState extends ConsumerState<StudentChecklistDialog> {
  late final Set<String> _ticked = {...widget.initial};
  bool _saving = false;

  Future<void> _run(Future<Result<void>> Function(AcademyRepository) action, String message) async {
    setState(() => _saving = true);
    final result = await action(ref.read(academyRepositoryProvider));
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        showAppSnackBar(context, message);
        Navigator.of(context).pop();
      case Err(:final failure):
        showAppSnackBar(context, failure.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.students.every((s) => _ticked.contains(s.uid));
    final clear = widget.clear;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.hint, style: AppTextStyles.font13Normal.secondary(context)),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: all,
              title: Text(
                widget.countKey.tr(args: ['${_ticked.length}', '${widget.students.length}']),
                style: AppTextStyles.font14ExtraBold,
              ),
              onChanged: (value) => setState(() {
                if (value ?? false) {
                  _ticked.addAll(widget.students.map((s) => s.uid));
                } else {
                  _ticked.removeAll(widget.students.map((s) => s.uid));
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
                      value: _ticked.contains(student.uid),
                      secondary: InitialsAvatar(name: student.name, size: 32),
                      title: Text(student.name, style: AppTextStyles.font14Bold),
                      onChanged: (value) =>
                          setState(() => (value ?? false) ? _ticked.add(student.uid) : _ticked.remove(student.uid)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (clear != null)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: _saving ? null : () => _run(clear.run, clear.message),
            child: Text(clear.label),
          ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('common.cancel'.tr())),
        ElevatedButton(
          onPressed: _saving ? null : () => _run((repo) => widget.save(repo, _ticked.toList()), widget.savedMessage),
          child: Text('common.save'.tr()),
        ),
      ],
    );
  }
}
