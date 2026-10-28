import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_text_field.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/shared/session_labels.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionDetailsDialog extends ConsumerStatefulWidget {
  const SessionDetailsDialog({super.key, required this.session, this.suggestedInstructor = ''});

  final ClassSession session;

  /// Pre-selected when the session has no instructor yet, usually the one from the session before it.
  final String suggestedInstructor;

  static Future<void> show(BuildContext context, ClassSession session, {String suggestedInstructor = ''}) =>
      showDialog<void>(
        context: context,
        builder: (_) => SessionDetailsDialog(session: session, suggestedInstructor: suggestedInstructor),
      );

  @override
  ConsumerState<SessionDetailsDialog> createState() => _SessionDetailsDialogState();
}

class _SessionDetailsDialogState extends ConsumerState<SessionDetailsDialog> {
  late final _topic = TextEditingController(text: widget.session.topic);
  late String _instructor = widget.session.instructor.isNotEmpty
      ? widget.session.instructor
      : widget.suggestedInstructor;
  bool _saving = false;

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await ref
        .read(academyRepositoryProvider)
        .updateSessionDetails(widget.session, topic: _topic.text, instructor: _instructor);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Ok():
        showAppSnackBar(context, 'admin.schedule.details_saved'.tr());
        Navigator.of(context).pop();
      case Err(:final failure):
        showAppSnackBar(context, failure.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final instructors = ref.watch(instructorsProvider);
    final names = (instructors.value ?? const []).map((i) => i.name).toList();
    // A removed instructor stays selectable on the sessions that still carry the name.
    final options = [...names, if (_instructor.isNotEmpty && !names.contains(_instructor)) _instructor];

    return AlertDialog(
      title: Text('admin.schedule.details_title'.tr()),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.session.title} · ${context.shortDay(widget.session.startsAt)}',
              style: AppTextStyles.font14Normal.secondary(context),
            ),
            verticalSpace(16),
            AppTextField(
              label: 'admin.schedule.topic_label'.tr(),
              hint: 'admin.schedule.topic_hint'.tr(),
              controller: _topic,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            verticalSpace(14),
            Text('admin.schedule.instructor'.tr(), style: AppTextStyles.font14Bold),
            verticalSpace(8),
            DropdownButtonFormField<String>(
              initialValue: _instructor,
              isExpanded: true,
              items: [
                DropdownMenuItem(value: '', child: Text('admin.schedule.no_instructor'.tr())),
                for (final name in options)
                  DropdownMenuItem(
                    value: name,
                    child: Text(name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (value) => setState(() => _instructor = value ?? ''),
            ),
            if (instructors.hasValue && names.isEmpty) ...[
              verticalSpace(8),
              Text('admin.schedule.no_instructors_hint'.tr(), style: AppTextStyles.font12Normal.secondary(context)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('common.cancel'.tr())),
        TextButton(onPressed: _saving ? null : _save, child: Text('common.save'.tr())),
      ],
    );
  }
}
