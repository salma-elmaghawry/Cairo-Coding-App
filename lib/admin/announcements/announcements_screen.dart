import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/announcements/announcement_providers.dart';
import 'package:cairo_coding_app/admin/announcements/widgets/compose_panel.dart';
import 'package:cairo_coding_app/admin/widgets/admin_page.dart';
import 'package:cairo_coding_app/admin/widgets/two_pane.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/announcement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, Announcement announcement) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.announcements.delete_title'.tr(),
      message: 'admin.announcements.delete_message'.tr(args: [announcement.title]),
      confirmLabel: 'common.delete'.tr(),
      cancelLabel: 'common.cancel'.tr(),
      destructive: true,
    );
    if (!confirmed) return;
    final result = await ref.read(academyRepositoryProvider).deleteAnnouncement(announcement);
    if (!context.mounted) return;
    if (result case Err(:final failure)) showAppSnackBar(context, failure.message, isError: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = ref.watch(adminAnnouncementsProvider);
    final groupNames = {for (final group in ref.watch(adminGroupsProvider).value ?? const []) group.id: group.name};
    final now = ref.watch(clockProvider)();
    final colorScheme = Theme.of(context).colorScheme;

    final list = switch (announcements) {
      AsyncError(:final error) => ErrorView(message: error.toString()),
      AsyncData(:final value) when value.isEmpty => EmptyView(
        message: 'admin.announcements.empty'.tr(),
        icon: Icons.campaign_outlined,
      ),
      AsyncData(:final value) => Column(
        children: [
          for (final announcement in value)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.bidi(announcement.title), style: AppTextStyles.font16ExtraBold),
                        verticalSpace(4),
                        Text(context.bidi(announcement.body), style: AppTextStyles.font14Normal.secondary(context)),
                        verticalSpace(10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            for (final id in announcement.groupIds)
                              Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text(groupNames[id] ?? id, style: AppTextStyles.font12Bold),
                              ),
                            Text(
                              context.relativeTime(announcement.createdAt, now),
                              style: AppTextStyles.monoFont10Medium.muted(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'common.delete'.tr(),
                    style: IconButton.styleFrom(side: BorderSide.none, foregroundColor: colorScheme.error),
                    onPressed: () => _delete(context, ref, announcement),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  ),
                ],
              ),
            ),
        ],
      ),
      _ => const SkeletonList(count: 3, itemHeight: 96),
    };

    return AdminPage(
      eyebrow: 'admin.announcements.eyebrow'.tr(),
      title: 'admin.announcements.title'.tr(),
      subtitle: 'admin.announcements.subtitle'.tr(),
      children: [TwoPane(main: list, side: const ComposePanel())],
    );
  }
}
