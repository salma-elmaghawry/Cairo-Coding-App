import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/groups/widgets/group_form_dialog.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GroupHeader extends ConsumerWidget {
  const GroupHeader({super.key, required this.group});

  final AcademyGroup group;

  Future<void> _toggleArchive(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(academyRepositoryProvider).setArchived(group, !group.archived);
    if (!context.mounted) return;
    if (result case Err(:final failure)) showAppSnackBar(context, failure.message, isError: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextButton(onPressed: () => context.go(AdminRoutes.groups), child: Text('admin.nav.groups'.tr())),
            Text('/', style: AppTextStyles.font14Normal.secondary(context)),
            horizontalSpace(8),
            Text(group.name, style: AppTextStyles.font14Normal.secondary(context)),
          ],
        ),
        verticalSpace(8),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    Text(group.name, style: AppTextStyles.monoFont28Bold.copyWith(color: colorScheme.primary)),
                    Text(group.track, style: AppTextStyles.font24ExtraBold),
                  ],
                ),
                verticalSpace(6),
                Text(
                  [
                    context.monthRange(group.startDate, group.endDate),
                    group.location,
                  ].where((part) => part.isNotEmpty).join(' · '),
                  style: AppTextStyles.font14Normal.secondary(context),
                ),
              ],
            ),
            Wrap(
              spacing: 10,
              children: [
                OutlinedButton(
                  onPressed: () => GroupFormDialog.show(context, group: group),
                  child: Text('admin.groups.edit'.tr()),
                ),
                OutlinedButton(
                  onPressed: () => _toggleArchive(context, ref),
                  child: Text((group.archived ? 'admin.groups.unarchive' : 'admin.groups.archive').tr()),
                ),
              ],
            ),
          ],
        ),
        verticalSpace(20),
      ],
    );
  }
}
