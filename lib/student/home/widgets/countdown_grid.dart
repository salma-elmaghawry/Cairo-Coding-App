import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Days, hours, minutes and seconds until [session] starts, or "Live now" while it runs.
class CountdownGrid extends ConsumerWidget {
  const CountdownGrid({super.key, required this.session});

  final ClassSession session;

  String _two(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(secondTickerProvider).value ?? ref.watch(clockProvider)();
    final colorScheme = Theme.of(context).colorScheme;

    if (!now.isBefore(session.startsAt) && now.isBefore(session.endsAt)) {
      return _Box(
        child: Text('home.live_now'.tr(), style: AppTextStyles.font18ExtraBold.copyWith(color: colorScheme.tertiary)),
      );
    }

    final left = session.startsAt.isAfter(now) ? session.startsAt.difference(now) : Duration.zero;
    final units = [
      (left.inDays, 'home.unit_days'),
      (left.inHours % 24, 'home.unit_hours'),
      (left.inMinutes % 60, 'home.unit_minutes'),
      (left.inSeconds % 60, 'home.unit_seconds'),
    ];
    final spoken = left.inDays > 0
        ? 'home.countdown_days'.tr(args: ['${left.inDays}', _two(left.inHours % 24), _two(left.inMinutes % 60)])
        : 'home.countdown_hours'.tr(args: [_two(left.inHours), _two(left.inMinutes % 60)]);

    return Semantics(
      label: '${'home.starts_in'.tr()} $spoken',
      excludeSemantics: true,
      child: Row(
        children: [
          for (final (index, (value, label)) in units.indexed) ...[
            if (index > 0) horizontalSpace(8),
            Expanded(
              child: _Box(
                child: Column(
                  children: [
                    Text(
                      _two(value),
                      textDirection: TextDirection.ltr,
                      style: AppTextStyles.monoFont24Bold.copyWith(color: colorScheme.tertiary, height: 1.1),
                    ),
                    verticalSpace(2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(label.tr().toUpperCase(), style: AppTextStyles.font11ExtraBold.muted(context)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline),
      ),
      child: child,
    );
  }
}
