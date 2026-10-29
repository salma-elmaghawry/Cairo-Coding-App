import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/groups/widgets/group_form_dialog.dart';
import 'package:cairo_coding_app/admin/groups/widgets/group_card.dart';
import 'package:cairo_coding_app/admin/widgets/admin_page.dart';
import 'package:cairo_coding_app/admin/widgets/card_grid.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(visibleGroupsProvider);
    final view = ref.watch(groupsViewProvider);
    final counts = ref.watch(groupCountsProvider);
    final viewNotifier = ref.read(groupsViewProvider.notifier);

    return AdminPage(
      eyebrow: 'admin.groups.eyebrow'.tr(),
      title: 'admin.groups.title'.tr(),
      actions: [
        SizedBox(
          width: 260,
          child: TextField(
            onChanged: viewNotifier.search,
            decoration: InputDecoration(
              hintText: 'admin.groups.search'.tr(),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
            ),
          ),
        ),
        PrimaryButton(
          label: 'admin.groups.new'.tr(),
          icon: Icons.add_rounded,
          height: 46,
          expand: false,
          onPressed: () => GroupFormDialog.show(context),
        ),
      ],
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text('admin.groups.active'.tr(args: ['${counts.active}'])),
              selected: !view.archived,
              onSelected: (_) => viewNotifier.showArchived(false),
            ),
            ChoiceChip(
              label: Text('admin.groups.archived'.tr(args: ['${counts.archived}'])),
              selected: view.archived,
              onSelected: (_) => viewNotifier.showArchived(true),
            ),
          ],
        ),
        verticalSpace(20),
        switch (groups) {
          AsyncError(:final error) => ErrorView(message: error.toString()),
          AsyncData(:final value) when value.isEmpty => EmptyView(
            message: 'admin.groups.empty'.tr(),
            icon: Icons.groups_outlined,
          ),
          AsyncData(:final value) => CardGrid(children: [for (final group in value) GroupCard(group: group)]),
          _ => const SkeletonList(count: 3, itemHeight: 120),
        },
      ],
    );
  }
}
