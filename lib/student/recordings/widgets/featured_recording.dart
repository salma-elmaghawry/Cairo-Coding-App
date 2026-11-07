import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/data/models/recording.dart';
import 'package:cairo_coding_app/student/widgets/recording_thumbnail.dart';
import 'package:cairo_coding_app/student/widgets/recording_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The newest recording, shown large at the top of the tab.
class FeaturedRecording extends ConsumerWidget {
  const FeaturedRecording({super.key, required this.recording, this.groupName});

  final Recording recording;
  final String? groupName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final meta = [
      'session.title'.tr(args: ['${recording.sessionNumber}'.padLeft(2, '0')]),
      context.shortDay(recording.recordedAt),
      ?groupName,
    ].join(' · ');

    return Semantics(
      button: true,
      link: true,
      child: AnimatedTap(
        onTap: () => openRecording(context, ref, recording),
        scaleDown: .98,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.primary.withValues(alpha: .28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? .6 : .08),
                blurRadius: 40,
                spreadRadius: -20,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RecordingThumbnail(recording: recording, height: 172, badge: 'recordings.latest'.tr()),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.bidi(recording.title), style: AppTextStyles.font16ExtraBold),
                    verticalSpace(2),
                    Text(meta, style: AppTextStyles.font13Normal.secondary(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
