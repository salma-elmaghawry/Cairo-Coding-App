import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/courses/widgets/course_form_dialog.dart';
import 'package:cairo_coding_app/admin/groups/widgets/group_form_dialog.dart';
import 'package:cairo_coding_app/admin/shell/admin_alerts.dart';
import 'package:cairo_coding_app/admin/shell/admin_search_field.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminTopBar extends StatelessWidget {
  const AdminTopBar({super.key, required this.searchFocus});

  final FocusNode searchFocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline)),
      ),
      child: Row(
        children: [
          Flexible(
            flex: 3,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AdminSearchField(focusNode: searchFocus),
            ),
          ),
          const Spacer(),
          const TodayLabel(),
          horizontalSpace(12),
          const AlertsButton(),
          horizontalSpace(12),
          const NewMenuButton(),
        ],
      ),
    );
  }
}

enum _NewItem { course, group, quiz, announcement }

/// Starts any of the things the dashboard creates.
class NewMenuButton extends StatelessWidget {
  const NewMenuButton({super.key});

  void _open(BuildContext context, _NewItem item) => switch (item) {
    _NewItem.course => CourseFormDialog.show(context),
    _NewItem.group => GroupFormDialog.show(context),
    _NewItem.quiz => context.go(AdminRoutes.newQuiz),
    _NewItem.announcement => context.go(AdminRoutes.announcements),
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<_NewItem>(
      tooltip: 'admin.top.new'.tr(),
      position: PopupMenuPosition.under,
      onSelected: (item) => _open(context, item),
      itemBuilder: (_) => [
        for (final (item, icon, label) in [
          (_NewItem.course, Icons.menu_book_outlined, 'admin.top.new_course'),
          (_NewItem.group, Icons.groups_outlined, 'admin.top.new_group'),
          (_NewItem.quiz, Icons.quiz_outlined, 'admin.top.new_quiz'),
          (_NewItem.announcement, Icons.campaign_outlined, 'admin.top.new_announcement'),
        ])
          PopupMenuItem(
            value: item,
            child: Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.primary),
                horizontalSpace(10),
                Text(label.tr()),
              ],
            ),
          ),
      ],
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 18, color: colorScheme.onPrimary),
            horizontalSpace(6),
            Text('admin.top.new'.tr(), style: AppTextStyles.font14ExtraBold.copyWith(color: colorScheme.onPrimary)),
          ],
        ),
      ),
    );
  }
}
