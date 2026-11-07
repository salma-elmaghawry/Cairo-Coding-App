import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/initials_avatar.dart';
import 'package:cairo_coding_app/core/widgets/wordmark.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminSidebar extends ConsumerWidget {
  const AdminSidebar({super.key, required this.location, this.inDrawer = false});

  final String location;
  final bool inDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = ref.watch(authStateProvider.select((auth) => auth.value?.profile.name ?? ''));
    final groupCount = ref.watch(groupCountsProvider.select((counts) => counts.active));
    final studentCount = ref.watch(allStudentsProvider.select((value) => value.value?.where((s) => s.active).length));

    void go(String route) {
      if (inDrawer) Navigator.of(context).pop();
      context.go(route);
    }

    Widget item(String route, IconData icon, String label, {int? count}) => Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: _NavItem(
        icon: icon,
        label: label.tr(),
        count: count,
        selected: location.startsWith(route),
        onTap: () => go(route),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: BorderDirectional(end: BorderSide(color: colorScheme.outline)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Wordmark(fontSize: 20),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colorScheme.primary.withValues(alpha: .35)),
                    ),
                    child: Text(
                      'admin.badge'.tr(),
                      style: AppTextStyles.monoFont10Medium.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            verticalSpace(28),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _SectionLabel('admin.nav.workspace'.tr()),
                  item(AdminRoutes.overview, Icons.space_dashboard_outlined, 'admin.nav.overview'),
                  item(AdminRoutes.courses, Icons.menu_book_outlined, 'admin.nav.courses'),
                  item(AdminRoutes.groups, Icons.groups_outlined, 'admin.nav.groups', count: groupCount),
                  item(AdminRoutes.students, Icons.school_outlined, 'admin.nav.students', count: studentCount),
                  item(AdminRoutes.instructors, Icons.co_present_outlined, 'admin.nav.instructors'),
                  item(AdminRoutes.quizzes, Icons.quiz_outlined, 'admin.nav.quizzes'),
                  verticalSpace(20),
                  _SectionLabel('admin.nav.academy'.tr()),
                  item(AdminRoutes.announcements, Icons.campaign_outlined, 'admin.nav.announcements'),
                  item(AdminRoutes.settings, Icons.tune_outlined, 'admin.nav.settings'),
                ],
              ),
            ),
            verticalSpace(12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Row(
                children: [
                  InitialsAvatar(name: name, size: 36),
                  horizontalSpace(10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: AppTextStyles.font14ExtraBold, overflow: TextOverflow.ellipsis),
                        Text('admin.role'.tr(), style: AppTextStyles.font12Normal.secondary(context)),
                      ],
                    ),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(side: BorderSide.none),
                    tooltip: 'auth.logout'.tr(),
                    onPressed: () => ref.read(authRepositoryProvider).signOut(),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Text(text.toUpperCase(), style: AppTextStyles.font11ExtraBold.muted(context).copyWith(letterSpacing: 1.1)),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap, this.count});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? colorScheme.primary.withValues(alpha: .16) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? colorScheme.primary.withValues(alpha: .25) : Colors.transparent),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 19, color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant),
              horizontalSpace(12),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: (selected ? AppTextStyles.font14ExtraBold : AppTextStyles.font14Bold).copyWith(
                    color: selected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (count != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('$count', style: AppTextStyles.monoFont11Bold.secondary(context)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
