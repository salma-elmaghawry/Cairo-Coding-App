import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/admin_routes.dart';
import 'package:cairo_coding_app/admin/quizzes/widgets/quiz_actions.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_image.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _QuizAction { publish, unpublish, duplicate, delete }

class AdminQuizCard extends ConsumerWidget {
  const AdminQuizCard({super.key, required this.quiz});

  final Quiz quiz;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final groups = {
      for (final group in ref.watch(adminGroupsProvider).value ?? const <AcademyGroup>[]) group.id: group,
    };
    final groupNames = [for (final id in quiz.groupIds) ?groups[id]?.name];

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: QuizImage(
                  url: quiz.coverUrl,
                  radius: 12,
                  fallback: ColoredBox(
                    color: colorScheme.primary.withValues(alpha: .14),
                    child: Icon(Icons.quiz_outlined, color: colorScheme.primary),
                  ),
                ),
              ),
              horizontalSpace(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.bidi(quiz.title), style: AppTextStyles.font18ExtraBold),
                    verticalSpace(4),
                    StatusChip(
                      label: (quiz.isPublished ? 'admin.quizzes.status_published' : 'admin.quizzes.status_draft').tr(),
                      tone: quiz.isPublished ? StatusTone.success : StatusTone.neutral,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_QuizAction>(
                tooltip: 'admin.quizzes.actions'.tr(),
                onSelected: (action) => switch (action) {
                  _QuizAction.publish => setQuizPublished(context, ref, quiz, true),
                  _QuizAction.unpublish => setQuizPublished(context, ref, quiz, false),
                  _QuizAction.duplicate => duplicateQuiz(context, ref, quiz),
                  _QuizAction.delete => deleteQuiz(context, ref, quiz),
                },
                itemBuilder: (_) => [
                  if (quiz.isPublished)
                    PopupMenuItem(value: _QuizAction.unpublish, child: Text('admin.quizzes.unpublish'.tr()))
                  else
                    PopupMenuItem(value: _QuizAction.publish, child: Text('admin.quizzes.publish'.tr())),
                  PopupMenuItem(value: _QuizAction.duplicate, child: Text('admin.quizzes.duplicate'.tr())),
                  PopupMenuItem(value: _QuizAction.delete, child: Text('admin.quizzes.delete'.tr())),
                ],
              ),
            ],
          ),
          if (quiz.description.isNotEmpty) ...[
            verticalSpace(10),
            Text(
              context.bidi(quiz.description),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.font14Normal.secondary(context),
            ),
          ],
          verticalSpace(14),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _Stat(label: 'admin.quizzes.questions'.tr(), value: '${quiz.questionCount}'),
              _Stat(label: 'admin.quizzes.points'.tr(), value: '${quiz.totalPoints}'),
              _Stat(
                label: 'admin.quizzes.time'.tr(),
                value: quiz.hasTimeLimit ? 'admin.quizzes.minutes'.tr(args: ['${quiz.durationMin}']) : '–',
              ),
            ],
          ),
          verticalSpace(12),
          Text(
            groupNames.isEmpty ? 'admin.quizzes.no_groups'.tr() : groupNames.map(context.bidi).join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.font12Medium.secondary(context),
          ),
          verticalSpace(2),
          Text(context.monthRange(quiz.opensAt, quiz.closesAt), style: AppTextStyles.font12Normal.secondary(context)),
          verticalSpace(16),
          Row(
            children: [
              if (!quiz.isPublished) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go(AdminRoutes.editQuiz(quiz.id)),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text('admin.quizzes.edit'.tr()),
                  ),
                ),
                horizontalSpace(10),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go(AdminRoutes.quizAnalytics(quiz.id)),
                  icon: const Icon(Icons.insights_rounded, size: 18),
                  label: Text('admin.quizzes.analytics'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    // The time reads "10 min", and the mono font has no Arabic letters.
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.font12Normal.secondary(context)),
        Text(value, style: isRtl ? AppTextStyles.font16ExtraBold : AppTextStyles.monoFont16Bold),
      ],
    );
  }
}
