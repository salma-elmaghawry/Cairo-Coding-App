import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/theme/app_colors.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/data/services/leaderboard.dart';
import 'package:cairo_coding_app/shared/quizzes/quiz_format.dart';
import 'package:cairo_coding_app/student/quizzes/widgets/student_avatar.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The top three on their steps, first place in the middle.
class LeaderboardPodium extends StatelessWidget {
  const LeaderboardPodium({super.key, required this.top, required this.myUid});

  final List<RankedStudent> top;
  final String? myUid;

  @override
  Widget build(BuildContext context) {
    Widget step(RankedStudent student, double height, Color medal) => Expanded(
      child: _PodiumStep(student: student, height: height, medal: medal, isMe: student.uid == myUid),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        step(top[1], 84, AppColors.medalSilver),
        horizontalSpace(8),
        step(top[0], 116, AppColors.medalGold),
        horizontalSpace(8),
        step(top[2], 62, AppColors.medalBronze),
      ],
    );
  }
}

class _PodiumStep extends StatelessWidget {
  const _PodiumStep({required this.student, required this.height, required this.medal, required this.isMe});

  final RankedStudent student;
  final double height;
  final Color medal;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StudentAvatar(name: student.name, size: 58, ring: medal),
        verticalSpace(6),
        Text(
          context.bidi(student.name),
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.font14ExtraBold.copyWith(color: isMe ? colorScheme.primary : null),
        ),
        if (isMe) Text('quizzes.you'.tr(), style: AppTextStyles.font12SemiBold.copyWith(color: colorScheme.primary)),
        verticalSpace(2),
        Text('quizzes.points_count'.plural(student.score), style: AppTextStyles.font12Medium.secondary(context)),
        Text(
          formatClock(Duration(milliseconds: student.durationMs)),
          textDirection: TextDirection.ltr,
          style: AppTextStyles.monoFont10Medium.secondary(context),
        ),
        verticalSpace(6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: height),
          duration: AppAnimations.verySlow,
          curve: AppAnimations.defaultCurve,
          builder: (_, value, child) => Container(
            height: value,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: medal,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: child,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('${student.rank}', style: AppTextStyles.monoFont28Bold.copyWith(color: AppColors.onMedal)),
          ),
        ),
      ],
    );
  }
}
