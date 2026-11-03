import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/models/quiz.dart';
import 'package:cairo_coding_app/data/services/leaderboard.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_providers.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/leaderboard_ranking.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key, this.quizId});

  /// The quiz to open on; null opens the overall ranking.
  final String? quizId;

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String? _groupId;
  late String? _quizId = widget.quizId;
  late bool _byQuiz = widget.quizId != null;

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsByIdProvider);
    final quizzes = ref.watch(studentQuizzesProvider).value ?? const <Quiz>[];
    final uid = ref.watch(currentUserProvider)?.uid;
    final groupIds = ref.watch(studentGroupIdsProvider);
    final opening = quizzes.where((q) => q.id == _quizId).firstOrNull;
    // Opening on a quiz starts in a group that quiz belongs to, because a student can be in several.
    final groupId = _groupId ?? opening?.groupIds.where(groupIds.contains).firstOrNull ?? groupIds.firstOrNull;
    final groupQuizzes = quizzes.where((q) => q.groupIds.contains(groupId)).toList();
    final quizId = groupQuizzes.any((q) => q.id == _quizId) ? _quizId : groupQuizzes.firstOrNull?.id;

    final ranked = switch ((groupId, _byQuiz, quizId)) {
      (null, _, _) || (_, true, null) => const AsyncData(<RankedStudent>[]),
      (final String group, true, final String quiz) =>
        ref.watch(quizBoardProvider((groupId: group, quizId: quiz))).whenData(Leaderboard.forQuiz),
      (final String group, _, _) => ref.watch(overallLeaderboardProvider(group)),
    };

    return Scaffold(
      appBar: AppBar(title: Text('quizzes.leaderboard'.tr())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: false, label: Text('quizzes.board_overall'.tr())),
              ButtonSegment(value: true, label: Text('quizzes.board_by_quiz'.tr())),
            ],
            selected: {_byQuiz},
            onSelectionChanged: (selection) => setState(() => _byQuiz = selection.first),
          ),
          if (groups.length > 1) ...[
            verticalSpace(12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final group in groups.values)
                  ChoiceChip(
                    label: Text(context.bidi(group.name)),
                    selected: group.id == groupId,
                    onSelected: (_) => setState(() => _groupId = group.id),
                  ),
              ],
            ),
          ],
          if (_byQuiz && groupQuizzes.isNotEmpty) ...[
            verticalSpace(12),
            DropdownButtonFormField<String>(
              key: ValueKey(quizId),
              initialValue: quizId,
              isExpanded: true,
              items: [
                for (final quiz in groupQuizzes)
                  DropdownMenuItem(
                    value: quiz.id,
                    child: Text(context.bidi(quiz.title), overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (value) => setState(() => _quizId = value),
            ),
          ],
          verticalSpace(8),
          if (groups[groupId]?.name case final groupName?)
            Text(
              'quizzes.board_scope'.tr(args: [context.bidi(groupName)]),
              style: AppTextStyles.font12Normal.secondary(context),
            ),
          verticalSpace(16),
          switch (ranked) {
            AsyncError(:final error) => ErrorView(message: error.toString()),
            AsyncData(:final value) when value.isEmpty => EmptyView(
              message: 'quizzes.board_empty'.tr(),
              icon: Icons.emoji_events_outlined,
            ),
            AsyncData(:final value) => LeaderboardRanking(ranked: value, myUid: uid, showQuizCount: !_byQuiz),
            _ => const SkeletonList(count: 5),
          },
        ],
      ),
    );
  }
}
