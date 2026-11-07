import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/course.dart';
import 'package:cairo_coding_app/data/models/student.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class _Hit {
  const _Hit({required this.icon, required this.title, required this.subtitle, required this.open});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback open;
}

/// Finds students, groups and courses from anywhere in the dashboard. Ctrl K (⌘K) focuses it.
class AdminSearchField extends ConsumerStatefulWidget {
  const AdminSearchField({super.key, required this.focusNode});

  final FocusNode focusNode;

  @override
  ConsumerState<AdminSearchField> createState() => _AdminSearchFieldState();
}

class _AdminSearchFieldState extends ConsumerState<AdminSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Hit> _search(String text) {
    final query = text.trim().toLowerCase();
    if (query.length < 2) return const [];
    final students = ref.read(allStudentsProvider).value ?? const <Student>[];
    final groups = ref.read(adminGroupsProvider).value ?? const <AcademyGroup>[];
    final courses = ref.read(coursesProvider).value ?? const <Course>[];
    final router = GoRouter.of(context);

    return [
      for (final course in courses)
        if (course.name.toLowerCase().contains(query))
          _Hit(
            icon: Icons.menu_book_outlined,
            title: course.name,
            subtitle: 'admin.nav.courses'.tr(),
            open: () => router.go(AdminRoutes.course(course.id)),
          ),
      for (final group in groups)
        if (group.name.toLowerCase().contains(query))
          _Hit(
            icon: Icons.groups_outlined,
            title: group.name,
            subtitle: 'admin.nav.groups'.tr(),
            open: () => router.go(AdminRoutes.group(group.id)),
          ),
      for (final student in students)
        if ('${student.name} ${student.email} ${student.phone.replaceAll(' ', '')}'.toLowerCase().contains(query))
          _Hit(
            icon: Icons.school_outlined,
            title: student.name,
            subtitle: student.email,
            open: () {
              ref.read(studentsViewProvider.notifier).search(student.email);
              router.go(AdminRoutes.students);
            },
          ),
    ].take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RawAutocomplete<_Hit>(
      textEditingController: _controller,
      focusNode: widget.focusNode,
      optionsBuilder: (value) => _search(value.text),
      displayStringForOption: (hit) => hit.title,
      onSelected: (hit) {
        _controller.clear();
        widget.focusNode.unfocus();
        hit.open();
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextField(
        controller: controller,
        focusNode: focusNode,
        onSubmitted: (_) => onSubmitted(),
        style: AppTextStyles.font14Normal,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'admin.top.search'.tr(),
          fillColor: colorScheme.surfaceContainer,
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          suffixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colorScheme.primary.withValues(alpha: .25)),
                ),
                child: Text('Ctrl K', style: AppTextStyles.monoFont10Medium.secondary(context)),
              ),
            ),
          ),
        ),
      ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: AlignmentDirectional.topStart,
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Material(
            elevation: 12,
            color: colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: colorScheme.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420, maxHeight: 380),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                children: [
                  for (final hit in options)
                    ListTile(
                      dense: true,
                      leading: Icon(hit.icon, size: 20, color: colorScheme.primary),
                      title: Text(context.bidi(hit.title), style: AppTextStyles.font14Bold),
                      subtitle: Text(hit.subtitle, style: AppTextStyles.font12Normal.secondary(context)),
                      onTap: () => onSelected(hit),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
