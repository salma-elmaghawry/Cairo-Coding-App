import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/courses/widgets/course_card.dart';
import 'package:cairo_coding_app/admin/courses/widgets/course_form_dialog.dart';
import 'package:cairo_coding_app/admin/widgets/admin_page.dart';
import 'package:cairo_coding_app/admin/widgets/card_grid.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(coursesProvider);

    return AdminPage(
      eyebrow: 'admin.courses.eyebrow'.tr(),
      title: 'admin.courses.title'.tr(),
      actions: [
        PrimaryButton(
          label: 'admin.courses.new'.tr(),
          icon: Icons.add_rounded,
          height: 46,
          expand: false,
          onPressed: () => CourseFormDialog.show(context),
        ),
      ],
      children: [
        switch (courses) {
          AsyncError(:final error) => ErrorView(message: error.toString()),
          AsyncData(:final value) when value.isEmpty => EmptyView(
            message: 'admin.courses.empty'.tr(),
            icon: Icons.menu_book_outlined,
          ),
          AsyncData(:final value) => CardGrid(children: [for (final course in value) CourseCard(course: course)]),
          _ => const SkeletonList(count: 3, itemHeight: 120),
        },
      ],
    );
  }
}
