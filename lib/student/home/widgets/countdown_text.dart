import 'package:cairo_coding_app/core/providers/core_providers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CountdownText extends ConsumerWidget {
  const CountdownText({super.key, required this.session});

  final ClassSession session;

  String _format(Duration left) {
    String two(int value) => value.toString().padLeft(2, '0');
    final days = left.inDays;
    final hours = left.inHours % 24;
    final minutes = left.inMinutes % 60;
    if (days > 0) return 'home.countdown_days'.tr(args: ['$days', two(hours), two(minutes)]);
    return 'home.countdown_hours'.tr(args: [two(hours), two(minutes)]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(minuteTickerProvider).value ?? ref.watch(clockProvider)();
    final live = !now.isBefore(session.startsAt) && now.isBefore(session.endsAt);
    final text = live ? 'home.live_now'.tr() : _format(session.startsAt.difference(now));

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(text, style: AppTextStyles.monoFont28Bold.copyWith(color: Theme.of(context).colorScheme.tertiary)),
    );
  }
}
