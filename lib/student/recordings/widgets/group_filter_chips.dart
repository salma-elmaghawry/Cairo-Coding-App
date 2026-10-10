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

    Widget chip(String label, String? groupId) =>
        ChoiceChip(label: Text(label), selected: selected == groupId, onSelected: (_) => filter.select(groupId));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [chip('recordings.all'.tr(), null), for (final group in groups) chip(group.name, group.id)],
    );
  }
}
