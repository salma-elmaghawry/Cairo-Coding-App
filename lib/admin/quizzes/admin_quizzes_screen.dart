import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/quizzes/quiz_admin_providers.dart';
import 'package:cairo_coding_app/admin/quizzes/widgets/admin_quiz_card.dart';
import 'package:cairo_coding_app/admin/widgets/admin_page.dart';
import 'package:cairo_coding_app/admin/widgets/card_grid.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminQuizzesScreen extends ConsumerWidget {
  const AdminQuizzesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzes = ref.watch(visibleQuizzesProvider);
    final view = ref.watch(quizzesViewProvider);
    final viewNotifier = ref.read(quizzesViewProvider.notifier);

    return AdminPage(
      eyebrow: 'admin.quizzes.eyebrow'.tr(),
      title: 'admin.quizzes.title'.tr(),
      actions: [
        SizedBox(
          width: 300,
          child: TextField(
            onChanged: viewNotifier.search,
            decoration: InputDecoration(
              hintText: 'admin.quizzes.search'.tr(),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
            ),
          ),
        ),
        PrimaryButton(
          label: 'admin.quizzes.new'.tr(),
          icon: Icons.add_rounded,
          height: 46,
          expand: false,
          onPressed: () => context.go(AdminRoutes.newQuiz),
        ),
      ],
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (status, label) in [
              (null, 'admin.quizzes.all'),
              (QuizStatus.draft, 'admin.quizzes.status_draft'),
              (QuizStatus.published, 'admin.quizzes.status_published'),
            ])
              ChoiceChip(
                label: Text(label.tr()),
                selected: view.status == status,
                onSelected: (_) => viewNotifier.filterStatus(status),
              ),
          ],
        ),
        verticalSpace(20),
        switch (quizzes) {
          AsyncError(:final error) => ErrorView(message: error.toString()),
          AsyncData(:final value) when value.isEmpty => EmptyView(
            message: (view.query.isEmpty && view.status == null ? 'admin.quizzes.empty' : 'admin.quizzes.empty_filter')
                .tr(),
            icon: Icons.quiz_outlined,
          ),
          AsyncData(:final value) => CardGrid(children: [for (final quiz in value) AdminQuizCard(quiz: quiz)]),
          _ => const SkeletonList(count: 3, itemHeight: 160),
        },
      ],
    );
  }
}
