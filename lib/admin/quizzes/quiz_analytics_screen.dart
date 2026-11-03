import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/quizzes/quiz_admin_providers.dart';
import 'package:cairo_coding_app/admin/quizzes/widgets/question_stats_card.dart';
import 'package:cairo_coding_app/admin/quizzes/widgets/quiz_kpis.dart';
import 'package:cairo_coding_app/admin/quizzes/widgets/quiz_results_table.dart';
import 'package:cairo_coding_app/admin/widgets/admin_page.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/not_found_screen.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/services/quiz_analytics.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class QuizAnalyticsScreen extends ConsumerStatefulWidget {
  const QuizAnalyticsScreen({super.key, required this.quizId});

  final String quizId;

  @override
  ConsumerState<QuizAnalyticsScreen> createState() => _QuizAnalyticsScreenState();
}

class _QuizAnalyticsScreenState extends ConsumerState<QuizAnalyticsScreen> {
  /// Only this group's students; null counts every group the quiz was given to.
  String? _groupId;

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(adminQuizProvider(widget.quizId));
    final content = ref.watch(quizContentProvider(widget.quizId));
    final attempts = ref.watch(quizAttemptsProvider(widget.quizId));
    final students = ref.watch(quizStudentsProvider(widget.quizId));

    final problem = quiz.error ?? content.error ?? attempts.error ?? students.error;
    if (problem != null) return ErrorView(message: problem.toString());
    if (quiz.hasValue && quiz.value == null) return const NotFoundScreen();
    if (!quiz.hasValue || !content.hasValue || !attempts.hasValue || !students.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    final loaded = quiz.requireValue!;
    final groups = {
      for (final group in ref.watch(adminGroupsProvider).value ?? const <AcademyGroup>[]) group.id: group,
    };
    final analytics = QuizAnalytics.from(
      quiz: loaded,
      content: content.requireValue,
      students: students.requireValue,
      attempts: attempts.requireValue,
      groupId: _groupId,
    );

    return AdminPage(
      eyebrow: 'admin.quiz_analytics.eyebrow'.tr(),
      title: context.bidi(loaded.title),
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.go(AdminRoutes.quizzes),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: Text('admin.quiz_analytics.back'.tr()),
        ),
      ],
      children: [
        if (loaded.groupIds.length > 1) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text('admin.quiz_analytics.all_groups'.tr()),
                selected: _groupId == null,
                onSelected: (_) => setState(() => _groupId = null),
              ),
              for (final id in loaded.groupIds)
                ChoiceChip(
                  label: Text(context.bidi(groups[id]?.name ?? id)),
                  selected: _groupId == id,
                  onSelected: (_) => setState(() => _groupId = id),
                ),
            ],
          ),
          verticalSpace(16),
        ],
        QuizKpis(analytics: analytics),
        verticalSpace(28),
        Text('admin.quiz_analytics.questions'.tr(), style: AppTextStyles.font18Bold),
        verticalSpace(4),
        Text('admin.quiz_analytics.first_attempt_note'.tr(), style: AppTextStyles.font12Normal.secondary(context)),
        verticalSpace(12),
        if (analytics.completed == 0)
          EmptyView(message: 'admin.quiz_analytics.no_results'.tr(), icon: Icons.insights_rounded)
        else
          for (final (index, stats) in analytics.questions.indexed) ...[
            QuestionStatsCard(number: index + 1, stats: stats),
            verticalSpace(12),
          ],
        verticalSpace(16),
        Text('admin.quiz_analytics.students'.tr(), style: AppTextStyles.font18Bold),
        verticalSpace(12),
        if (analytics.results.isEmpty)
          EmptyView(message: 'admin.quiz_analytics.no_students'.tr(), icon: Icons.school_outlined)
        else
          QuizResultsTable(quiz: loaded, analytics: analytics, groups: groups),
      ],
    );
  }
}
