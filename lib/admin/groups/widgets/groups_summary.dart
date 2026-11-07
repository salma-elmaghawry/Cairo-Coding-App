import 'package:cairo_coding_app/admin/groups/widgets/group_form_dialog.dart';
import 'package:cairo_coding_app/admin/insights/group_insights.dart';
import 'package:cairo_coding_app/admin/widgets/card_grid.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/icon_tile.dart';
import 'package:cairo_coding_app/data/services/attendance.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Four numbers across the groups that aren't archived.
class GroupsSummary extends ConsumerWidget {
  const GroupsSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(activeInsightsProvider);
    final students = {
      for (final group in groups)
        for (final student in group.members) student.uid,
    };
    final rates = [for (final group in groups) ?group.attendance];
    final attendance = rates.isEmpty ? null : rates.reduce((a, b) => a + b) / rates.length;

    return CardGrid(
      minItemWidth: 220,
      animate: false,
      children: [
        _Item(icon: Icons.groups_outlined, value: '${groups.length}', label: 'admin.groups.sum_groups'.tr()),
        _Item(icon: Icons.school_outlined, value: '${students.length}', label: 'admin.groups.sum_students'.tr()),
        _Item(
          icon: Icons.task_alt_rounded,
          value: attendance == null ? '–' : '${percent(attendance)}%',
          label: 'admin.groups.sum_attendance'.tr(),
        ),
        _Item(
          icon: Icons.calendar_month_outlined,
          value: '${groups.fold(0, (sum, g) => sum + g.weeklySessions)}',
          label: 'admin.groups.sum_weekly'.tr(),
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        children: [
          IconTile(icon: icon, size: 40, iconSize: 19),
          horizontalSpace(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, textDirection: TextDirection.ltr, style: AppTextStyles.monoFont20Bold),
                Text(label, style: AppTextStyles.font12Normal.secondary(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The dashed card at the end of the grid that starts a new group.
class CreateGroupCard extends StatelessWidget {
  const CreateGroupCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => GroupFormDialog.show(context),
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: _DashedBorder(color: colorScheme.primary.withValues(alpha: .4)),
          child: SizedBox(
            height: 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconTile(icon: Icons.add_rounded, size: 52),
                verticalSpace(12),
                Text('admin.groups.create_title'.tr(), style: AppTextStyles.font16ExtraBold),
                verticalSpace(2),
                Text('admin.groups.create_hint'.tr(), style: AppTextStyles.font13Normal.secondary(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 12) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
