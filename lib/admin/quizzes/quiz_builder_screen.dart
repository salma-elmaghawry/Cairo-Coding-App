import 'package:cairo_coding_app/admin/quizzes/quiz_admin_providers.dart';
import 'package:cairo_coding_app/admin/quizzes/widgets/quiz_actions.dart';
import 'package:cairo_coding_app/admin/quizzes/widgets/quiz_builder_form.dart';
import 'package:cairo_coding_app/admin/widgets/admin_page.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/not_found_screen.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads what the form needs, then hands over to it. [quizId] is null for a new quiz.
class QuizBuilderScreen extends ConsumerWidget {
  const QuizBuilderScreen({super.key, this.quizId});

  final String? quizId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = quizId;
    if (id == null) return const QuizBuilderForm();

    final quiz = ref.watch(adminQuizProvider(id));
    final content = ref.watch(quizContentProvider(id));
    final hasAttempts = ref.watch(quizHasAttemptsProvider(id));
    final problem = quiz.error ?? content.error ?? hasAttempts.error;
    if (problem != null) return ErrorView(message: problem.toString());
    if (!quiz.hasValue || !content.hasValue || !hasAttempts.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    final loaded = quiz.value;
    if (loaded == null) return const NotFoundScreen();
    if (loaded.isPublished) return _PublishedNotice(quiz: loaded);
    return QuizBuilderForm(
      key: ValueKey(id),
      quiz: loaded,
      content: content.requireValue,
      questionsLocked: hasAttempts.requireValue,
    );
  }
}

class _PublishedNotice extends ConsumerWidget {
  const _PublishedNotice({required this.quiz});

  final Quiz quiz;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminPage(
      eyebrow: 'admin.quizzes.eyebrow'.tr(),
      title: context.bidi(quiz.title),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('admin.quiz_builder.published_notice'.tr(), style: AppTextStyles.font14Normal.secondary(context)),
              verticalSpace(14),
              OutlinedButton(
                onPressed: () => setQuizPublished(context, ref, quiz, false),
                child: Text('admin.quizzes.unpublish'.tr()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
