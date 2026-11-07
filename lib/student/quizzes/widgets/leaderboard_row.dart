import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/icon_tile.dart';
import 'package:cairo_coding_app/student/quizzes/quiz_summary.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/student_avatar.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:cairo_coding_app/student/student_routes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Opens the leaderboard, showing the student's rank and the top three of their group.
class LeaderboardRow extends ConsumerWidget {
  const LeaderboardRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final gold = colorScheme.tertiary;
    final ranking = ref.watch(myGroupRankingProvider);
    final me = ref.watch(myRankProvider);
    final groupName = ref.watch(groupsByIdProvider)[ranking?.groupId]?.name;
    final top = ranking?.ranked.take(3).toList() ?? const [];
    final subtitle = me == null || groupName == null
        ? 'quizzes.leaderboard_hint'.tr()
        : 'quizzes.your_rank'.tr(args: ['#${me.rank}', '${ranking!.ranked.length}', context.bidi(groupName)]);

    return AnimatedTap(
      onTap: () => context.push(StudentRoutes.leaderboard),
      scaleDown: AppAnimations.pressScale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: gold.withValues(alpha: .35)),
        ),
        child: Row(
          children: [
            IconTile(icon: Icons.emoji_events_outlined, color: gold, background: gold.withValues(alpha: .12)),
            horizontalSpace(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('quizzes.leaderboard'.tr(), style: AppTextStyles.font15ExtraBold),
                  verticalSpace(2),
                  Text(subtitle, style: AppTextStyles.font13Normal.secondary(context)),
                ],
              ),
            ),
            if (top.isNotEmpty) ...[
              horizontalSpace(8),
              _AvatarStack(names: [for (final s in top) s.name]),
            ],
            horizontalSpace(4),
            Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.names});

  final List<String> names;

  static const double _size = 28;
  static const double _step = 20;

  @override
  Widget build(BuildContext context) {
    final ring = Theme.of(context).colorScheme.surfaceContainer;

    return ExcludeSemantics(
      child: SizedBox(
        width: _size + _step * (names.length - 1),
        height: _size,
        child: Stack(
          children: [
            // Later avatars tuck under the earlier ones, so the leader sits on top.
            for (final (index, name) in names.indexed.toList().reversed)
              PositionedDirectional(
                start: _step * index,
                // The avatar's own fill is see-through, so it gets a solid base where they overlap.
                child: DecoratedBox(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: ring),
                  child: StudentAvatar(name: name, size: _size, ring: ring),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
