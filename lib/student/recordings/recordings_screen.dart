import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/student/recordings/widgets/group_filter_chips.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:cairo_coding_app/student/widgets/recording_tile.dart';
import 'package:cairo_coding_app/student/widgets/tab_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecordingsScreen extends ConsumerWidget {
  const RecordingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordings = ref.watch(filteredRecordingsProvider);
    final groups = ref.watch(groupsByIdProvider);

    return TabPage(
      eyebrow: 'recordings.eyebrow'.tr(),
      title: 'recordings.title'.tr(),
      onRefresh: () async {
        ref.invalidate(studentRecordingsProvider);
        await ref.read(studentRecordingsProvider.future);
      },
      slivers: [
        if (groups.length > 1)
          const SliverToBoxAdapter(
            child: Padding(padding: EdgeInsets.only(bottom: 16), child: GroupFilterChips()),
          ),
        switch (recordings) {
          AsyncError(:final error) => SliverToBoxAdapter(child: ErrorView(message: error.toString())),
          AsyncData(:final value) when value.isEmpty => SliverToBoxAdapter(
            child: EmptyView(message: 'recordings.empty'.tr(), icon: Icons.smart_display_outlined),
          ),
          AsyncData(:final value) => SliverList.separated(
            itemCount: value.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => RecordingTile(
              recording: value[index],
              groupName: groups.length > 1 ? groups[value[index].groupId]?.name : null,
            ).fadeInSlideUp(delay: AppAnimations.staggerDelay * (index.clamp(0, 8))),
          ),
          _ => const SliverToBoxAdapter(child: SkeletonList(count: 5)),
        },
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'recordings.hint'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }
}
