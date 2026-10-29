import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/pickers.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_text_field.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Adds a session to [group] by hand, or edits [session] when one is given.
class SessionFormDialog extends ConsumerStatefulWidget {
  const SessionFormDialog({
    super.key,
    required this.group,
    this.session,
    this.nextNumber = 1,
    this.suggestedInstructor = '',
  });

  final AcademyGroup group;
  final ClassSession? session;

  /// The number a new session starts with; its name is pre-filled from the course list.
  final int nextNumber;

  /// Pre-selected when the session has no instructor yet, usually the one from the session before it.
  final String suggestedInstructor;

  static Future<void> show(
    BuildContext context, {
    required AcademyGroup group,
    ClassSession? session,
    int nextNumber = 1,
    String suggestedInstructor = '',
  }) => showDialog<void>(
    context: context,
    builder: (_) => SessionFormDialog(
      group: group,
      session: session,
      nextNumber: nextNumber,
      suggestedInstructor: suggestedInstructor,
    ),
  );

  @override
  ConsumerState<SessionFormDialog> createState() => _SessionFormDialogState();
}

class _SessionFormDialogState extends ConsumerState<SessionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _topic = TextEditingController(
    text:
        widget.session?.topic ??
        ref.read(courseProvider(widget.group.courseId)).value?.titleOf(widget.nextNumber) ??
        '',
  );
  late final _number = TextEditingController(text: '${widget.session?.number ?? widget.nextNumber}');
  late final _link = TextEditingController(text: widget.session?.meetingLinkOverride);
  late DateTime? _startsAt = widget.session?.startsAt;
  late String _instructor = widget.session?.instructor.isNotEmpty ?? false
      ? widget.session!.instructor
      : widget.suggestedInstructor;
  String? _topicError;
  String? _dateError;
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [_topic, _number, _link]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validateNumber(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    return number == null || number < 1 ? 'admin.schedule.number_invalid'.tr() : null;
  }

  String? _validateLink(String? value) {
    final link = value?.trim() ?? '';
    if (link.isEmpty) return null;
    final uri = Uri.tryParse(link);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty ? null : 'admin.recordings.url_invalid'.tr();
  }

  Future<void> _pickDate() async {
    final now = ref.read(clockProvider)();
    final slot = widget.group.weeklySlots.firstOrNull;
    final picked = await pickDateTime(
      context,
      initial: _startsAt ?? DateTime(now.year, now.month, now.day, slot?.hour ?? 19, slot?.minute ?? 0),
    );
    if (picked == null) return;
    setState(() {
      _startsAt = picked;
      _dateError = null;
    });
  }

  Future<void> _save() async {
    final validForm = _formKey.currentState!.validate();
    setState(() {
      _topicError = _topic.text.trim().isEmpty ? 'validation.required'.tr() : null;
      _dateError = _startsAt == null ? 'admin.schedule.date_required'.tr() : null;
    });
    if (!validForm || _topicError != null || _dateError != null) return;

    setState(() => _saving = true);
    final repository = ref.read(academyRepositoryProvider);
    final number = int.parse(_number.text.trim());
    final session = widget.session;
    final result = session == null
        ? await repository.addSession(
            widget.group,
            topic: _topic.text,
            number: number,
            startsAt: _startsAt!,
            instructor: _instructor,
            meetingLink: _link.text,
          )
        : await repository.updateSession(
            session,
            topic: _topic.text,
            number: number,
            startsAt: _startsAt!,
            instructor: _instructor,
            meetingLink: _link.text,
          );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        showAppSnackBar(
          context,
          (session == null ? 'admin.schedule.session_added' : 'admin.schedule.details_saved').tr(),
        );
        Navigator.of(context).pop();
      case Err(:final failure):
        showAppSnackBar(context, failure.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titles = ref.watch(courseProvider(widget.group.courseId)).value?.sessionTitles ?? const <String>[];
    final instructors = ref.watch(sessionInstructorsProvider(widget.group.id));
    final names = instructors.map((i) => i.name).toList();
    // A removed instructor stays selectable on the sessions that still carry the name.
    final options = [...names, if (_instructor.isNotEmpty && !names.contains(_instructor)) _instructor];
    final startsAt = _startsAt;

    return AlertDialog(
      title: Text((widget.session == null ? 'admin.schedule.add_title' : 'admin.schedule.edit_title').tr()),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Label('admin.schedule.topic'.tr()),
                DropdownMenu<String>(
                  controller: _topic,
                  expandedInsets: EdgeInsets.zero,
                  enableFilter: true,
                  requestFocusOnTap: true,
                  menuHeight: 320,
                  hintText: 'admin.schedule.topic_hint'.tr(),
                  errorText: _topicError,
                  dropdownMenuEntries: [
                    for (final (index, title) in titles.indexed)
                      DropdownMenuEntry(
                        value: title,
                        label: title,
                        labelWidget: Text(context.bidi(title)),
                        leadingIcon: Text(
                          '${index + 1}'.padLeft(2, '0'),
                          style: AppTextStyles.monoFont12Medium.copyWith(color: colorScheme.primary),
                        ),
                      ),
                  ],
                  // Picking from the course list sets the number that goes with it.
                  onSelected: (title) {
                    final index = title == null ? -1 : titles.indexOf(title);
                    if (index >= 0) _number.text = '${index + 1}';
                  },
                ),
                verticalSpace(14),
                AppTextField(
                  label: 'admin.schedule.number'.tr(),
                  controller: _number,
                  keyboardType: TextInputType.number,
                  monospace: true,
                  validator: _validateNumber,
                ),
                verticalSpace(14),
                _Label('admin.schedule.date'.tr()),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    alignment: AlignmentDirectional.centerStart,
                    side: _dateError == null ? null : BorderSide(color: colorScheme.error),
                  ),
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(
                    startsAt == null
                        ? 'admin.schedule.pick_date'.tr()
                        : '${context.shortDay(startsAt)} · ${context.time(startsAt)}',
                  ),
                ),
                if (_dateError case final error?) ...[
                  verticalSpace(6),
                  Text(error, style: AppTextStyles.font12Normal.copyWith(color: colorScheme.error)),
                ],
                verticalSpace(14),
                _Label('admin.schedule.instructor'.tr()),
                DropdownMenu<String>(
                  initialSelection: _instructor,
                  expandedInsets: EdgeInsets.zero,
                  enableFilter: true,
                  requestFocusOnTap: true,
                  menuHeight: 280,
                  dropdownMenuEntries: [
                    DropdownMenuEntry(value: '', label: 'admin.schedule.no_instructor'.tr()),
                    for (final name in options) DropdownMenuEntry(value: name, label: name),
                  ],
                  onSelected: (value) => setState(() => _instructor = value ?? ''),
                ),
                if (ref.watch(instructorsProvider).hasValue && names.isEmpty) ...[
                  verticalSpace(8),
                  Text('admin.schedule.no_instructors_hint'.tr(), style: AppTextStyles.font12Normal.secondary(context)),
                ],
                verticalSpace(14),
                AppTextField(
                  label: 'admin.schedule.link'.tr(),
                  hint: 'admin.schedule.link_hint'.tr(),
                  controller: _link,
                  keyboardType: TextInputType.url,
                  monospace: true,
                  validator: _validateLink,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('common.cancel'.tr())),
        TextButton(onPressed: _saving ? null : _save, child: Text('common.save'.tr())),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTextStyles.font14Bold),
    );
  }
}
