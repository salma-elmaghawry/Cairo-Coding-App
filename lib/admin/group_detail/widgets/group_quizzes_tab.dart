import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/insights/group_insights.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_data_table.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/data/services/attendance.dart';
import 'package:cairo_coding_app/data/services/quiz_averages.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The group's quizzes, with how many of its students took each and how they did.
class GroupQuizzesTab extends ConsumerWidget {
  const GroupQuizzesTab({super.key, required this.group});

  final AcademyGroup group;

  (String, StatusTone) _status(Quiz quiz, DateTime now) => switch (quiz) {
    _ when !quiz.isPublished => ('admin.quizzes.status_draft'.tr(), StatusTone.neutral),
    _ when !quiz.hasOpened(now) => ('quizzes.status.upcoming'.tr(), StatusTone.accent),
    _ when quiz.hasClosed(now) => ('admin.group.quiz_closed'.tr(), StatusTone.neutral),
    _ => ('admin.group.quiz_open'.tr(), StatusTone.success),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(groupInsightsProvider(group.id));
    if (insights == null) return const SkeletonList(count: 3, itemHeight: 56);
    final quizzes = insights.groupQuizzes;
    if (quizzes.isEmpty) return EmptyView(message: 'admin.group.no_quizzes'.tr(), icon: Icons.quiz_outlined);
    final now = insights.now;

    return AppDataTable(
      minWidth: 760,
      columns: [
        AppTableColumn('admin.group.quiz'.tr(), flex: 4),
        AppTableColumn('admin.students.status'.tr(), flex: 2),
        AppTableColumn('admin.group.closes'.tr(), flex: 3),
        AppTableColumn('admin.group.submitted'.tr(), flex: 2),
        AppTableColumn('admin.group.average'.tr(), flex: 2),
        AppTableColumn('admin.students.actions'.tr(), flex: 2, alignEnd: true),
      ],
      rows: [
        for (final quiz in quizzes)
          () {
            final board = insights.boardOf(quiz.id);
            final average = board == null ? null : QuizAverages.group([board], insights.quizzes);
            final status = _status(quiz, now);
            return [
              Text(context.bidi(quiz.title), style: AppTextStyles.font14ExtraBold),
              StatusChip(label: status.$1, tone: status.$2),
              Text(
                '${context.shortDay(quiz.closesAt)}, ${context.time(quiz.closesAt)}',
                style: AppTextStyles.font13Normal.secondary(context),
              ),
              Text(
                '${board?.entries.length ?? 0}/${insights.members.length}',
                textDirection: TextDirection.ltr,
                style: AppTextStyles.monoFont14Bold,
              ),
              Text(
                average == null ? '—' : '${percent(average)}%',
                textDirection: TextDirection.ltr,
                style: AppTextStyles.monoFont14Bold,
              ),
              TextButton(
                onPressed: () => context.go(AdminRoutes.quizAnalytics(quiz.id)),
                child: Text('admin.quizzes.analytics'.tr()),
              ),
            ];
          }(),
      ],
    );
  }
}
