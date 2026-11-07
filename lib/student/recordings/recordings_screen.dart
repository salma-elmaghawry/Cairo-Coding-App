import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/state_views.dart';
import 'package:cairo_coding_app/data/models/recording.dart';
import 'package:cairo_coding_app/student/recordings/widgets/featured_recording.dart';
import 'package:cairo_coding_app/student/recordings/widgets/group_filter_chips.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:cairo_coding_app/student/widgets/recording_tile.dart';
import 'package:cairo_coding_app/student/widgets/tab_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecordingsScreen extends ConsumerStatefulWidget {
  const RecordingsScreen({super.key});

  @override
  ConsumerState<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends ConsumerState<RecordingsScreen> {
  String _query = '';

  /// Matches the title, or the session number when the search is a number.
  bool _matches(Recording recording) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return recording.title.toLowerCase().contains(query) || '${recording.sessionNumber}' == query;
  }

  @override
  Widget build(BuildContext context) {
    final recordings = ref.watch(filteredRecordingsProvider);
    final groups = ref.watch(groupsByIdProvider);
    String? groupOf(Recording recording) => groups.length > 1 ? groups[recording.groupId]?.name : null;

    return TabPage(
      eyebrow: 'recordings.eyebrow'.tr(),
      title: 'recordings.title'.tr(),
      onRefresh: () async {
        ref.invalidate(studentRecordingsProvider);
        await ref.read(studentRecordingsProvider.future);
      },
      slivers: [
        SliverToBoxAdapter(child: _SearchField(onChanged: (value) => setState(() => _query = value))),
        const SliverToBoxAdapter(child: SizedBox(height: 18)),
        if (groups.length > 1) ...[
          const SliverToBoxAdapter(child: GroupFilterChips()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
        switch (recordings) {
          AsyncError(:final error) => SliverToBoxAdapter(child: ErrorView(message: error.toString())),
          AsyncData(:final value) when value.isEmpty => SliverToBoxAdapter(
            child: EmptyView(message: 'recordings.empty'.tr(), icon: Icons.smart_display_outlined),
          ),
          AsyncData(:final value) => _list(value.where(_matches).toList(), groupOf),
          _ => const SliverToBoxAdapter(child: SkeletonList(count: 5, itemHeight: 88)),
        },
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'recordings.hint'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.font12Normal.muted(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _list(List<Recording> matches, String? Function(Recording) groupOf) {
    if (matches.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyView(message: 'recordings.no_match'.tr(), icon: Icons.search_off_rounded),
      );
    }
    // The newest one is featured only while browsing, not in search results.
    final featured = _query.trim().isEmpty ? matches.first : null;
    final rest = featured == null ? matches : matches.skip(1).toList();

    return SliverMainAxisGroup(
      slivers: [
        if (featured != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: FeaturedRecording(recording: featured, groupName: groupOf(featured)).fadeInSlideUp(),
            ),
          ),
        SliverList.separated(
          itemCount: rest.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) => RecordingTile(
            recording: rest[index],
            groupName: groupOf(rest[index]),
          ).fadeInSlideUp(delay: AppAnimations.staggerDelay * (index.clamp(0, 8))),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color),
    );

    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: AppTextStyles.font15Normal,
      decoration: InputDecoration(
        hintText: 'recordings.search_hint'.tr(),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        fillColor: colorScheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: border(colorScheme.outline),
        enabledBorder: border(colorScheme.outline),
        focusedBorder: border(colorScheme.primary),
      ),
    );
  }
}
