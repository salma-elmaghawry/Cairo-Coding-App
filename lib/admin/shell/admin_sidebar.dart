import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
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

    void go(String route) {
      if (inDrawer) Navigator.of(context).pop();
      context.go(route);
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: BorderDirectional(end: BorderSide(color: colorScheme.outline)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(alignment: AlignmentDirectional.centerStart, child: Wordmark(fontSize: 24)),
            verticalSpace(32),
            _NavItem(
              icon: Icons.groups_outlined,
              label: 'admin.nav.groups'.tr(),
              selected: location.startsWith(AdminRoutes.groups),
              onTap: () => go(AdminRoutes.groups),
            ),
            verticalSpace(4),
            _NavItem(
              icon: Icons.tune_outlined,
              label: 'admin.nav.settings'.tr(),
              selected: location.startsWith(AdminRoutes.settings),
              onTap: () => go(AdminRoutes.settings),
            ),
            const Spacer(),
            const Divider(),
            verticalSpace(14),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colorScheme.surfaceContainerLowest,
                  child: Text(
                    name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: AppTextStyles.font14ExtraBold.copyWith(color: colorScheme.primary),
                  ),
                ),
                horizontalSpace(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.font14Bold, overflow: TextOverflow.ellipsis),
                      Text('admin.role'.tr(), style: AppTextStyles.font12Normal.secondary(context)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'auth.logout'.tr(),
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? colorScheme.primary.withValues(alpha: .14) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant),
              horizontalSpace(12),
              Text(
                label,
                style: (selected ? AppTextStyles.font16ExtraBold : AppTextStyles.font16SemiBold).copyWith(
                  color: selected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
