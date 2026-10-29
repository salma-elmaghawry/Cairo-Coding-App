import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/group_detail/widgets/add_students_panel.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every student belongs to a group, so adding from the Students page starts by picking one.
class AddStudentsDialog extends ConsumerStatefulWidget {
  const AddStudentsDialog({super.key});

  static Future<void> show(BuildContext context) =>
      showDialog<void>(context: context, builder: (_) => const AddStudentsDialog());

  @override
  ConsumerState<AddStudentsDialog> createState() => _AddStudentsDialogState();
}

class _AddStudentsDialogState extends ConsumerState<AddStudentsDialog> {
  String? _groupId;

  @override
  Widget build(BuildContext context) {
    final courseNames = {
      for (final course in ref.watch(coursesProvider).value ?? const <Course>[]) course.id: course.name,
    };
    final groups = (ref.watch(adminGroupsProvider).value ?? const <AcademyGroup>[]).where((g) => !g.archived).toList();
    final selected = groups.where((g) => g.id == _groupId).firstOrNull;

    return AlertDialog(
      title: Text('admin.students_page.add_title'.tr()),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('admin.students_page.add_hint'.tr(), style: AppTextStyles.font12Normal.secondary(context)),
              verticalSpace(14),
              Text('admin.students_page.pick_group'.tr(), style: AppTextStyles.font14Bold),
              verticalSpace(8),
              DropdownButtonFormField<String>(
                initialValue: selected?.id,
                isExpanded: true,
                hint: Text('admin.students_page.pick_group'.tr()),
                items: [
                  for (final group in groups)
                    DropdownMenuItem(
                      value: group.id,
                      child: Text(
                        [group.name, ?courseNames[group.courseId]].map(context.bidi).join(' · '),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _groupId = value),
              ),
              if (selected != null) ...[
                verticalSpace(16),
                AddStudentsPanel(key: ValueKey(selected.id), group: selected),
              ],
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('common.close'.tr()))],
    );
  }
}
