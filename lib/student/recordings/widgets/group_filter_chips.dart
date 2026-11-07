import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/widgets/filter_pill.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupFilterChips extends ConsumerWidget {
  const GroupFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsByIdProvider).values.toList();
    final selected = ref.watch(recordingsFilterProvider);
    final filter = ref.read(recordingsFilterProvider.notifier);

    return FilterPillBar(
      children: [
        FilterPill(label: 'recordings.all'.tr(), selected: selected == null, onSelected: () => filter.select(null)),
        for (final group in groups)
          FilterPill(
            label: context.bidi(group.name),
            selected: selected == group.id,
            onSelected: () => filter.select(group.id),
          ),
      ],
    );
  }
}
