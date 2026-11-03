import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void _report(BuildContext context, Result<Object?> result, String success) {
  if (!context.mounted) return;
  switch (result) {
    case Ok():
      showAppSnackBar(context, success);
    case Err(:final failure):
      showAppSnackBar(context, failure.message, isError: true);
  }
}

Future<void> setQuizPublished(BuildContext context, WidgetRef ref, Quiz quiz, bool published) async {
  final result = await ref.read(quizRepositoryProvider).setPublished(quiz, published);
  if (!context.mounted) return;
  _report(context, result, (published ? 'admin.quizzes.published_done' : 'admin.quizzes.unpublished_done').tr());
}

Future<void> duplicateQuiz(BuildContext context, WidgetRef ref, Quiz quiz) async {
  final title = 'admin.quizzes.copy_of'.tr(args: [quiz.title]);
  final result = await ref.read(quizRepositoryProvider).duplicateQuiz(quiz, title: title);
  if (!context.mounted) return;
  _report(context, result, 'admin.quizzes.duplicated'.tr());
}

Future<void> deleteQuiz(BuildContext context, WidgetRef ref, Quiz quiz) async {
  final confirmed = await showConfirmDialog(
    context,
    title: 'admin.quizzes.delete_title'.tr(args: [quiz.title]),
    message: 'admin.quizzes.delete_message'.tr(),
    confirmLabel: 'common.delete'.tr(),
    cancelLabel: 'common.cancel'.tr(),
    destructive: true,
  );
  if (!confirmed || !context.mounted) return;
  final result = await ref.read(quizRepositoryProvider).deleteQuiz(quiz);
  if (!context.mounted) return;
  _report(context, result, 'admin.quizzes.deleted'.tr());
}
