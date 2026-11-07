import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/link_launcher.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/status_chip.dart';
import 'package:cairo_coding_app/data/models/recording.dart';
import 'package:cairo_coding_app/student/student_activity.dart';
import 'package:cairo_coding_app/student/student_providers.dart';
import 'package:cairo_coding_app/student/widgets/recording_thumbnail.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens [recording] in YouTube or Drive, outside the app, and counts the student as having watched it.
Future<void> openRecording(BuildContext context, WidgetRef ref, Recording recording) async {
  final opened = await openExternalLink(recording.url);
  if (opened) {
    ref.read(studentActivityProvider).watched(recording);
  } else if (context.mounted) {
    showAppSnackBar(context, 'errors.open_link_failed'.tr(), isError: true);
  }
}

class RecordingTile extends ConsumerWidget {
  const RecordingTile({super.key, required this.recording, this.groupName});

  final Recording recording;
  final String? groupName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final uid = ref.watch(currentUserProvider.select((user) => user?.uid));
    final watched = recording.viewers.contains(uid);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final meta = [context.shortDay(recording.recordedAt), ?groupName].join(' · ');
    final label = 'session.title'.tr(args: ['${recording.sessionNumber}'.padLeft(2, '0')]).toUpperCase();

    return Semantics(
      button: true,
      link: true,
      child: AppCard(
        padding: const EdgeInsets.all(10),
        radius: 18,
        color: colorScheme.surfaceContainer,
        onTap: () => openRecording(context, ref, recording),
        child: Row(
          children: [
            RecordingThumbnail(recording: recording, width: 108, height: 66),
            horizontalSpace(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: (isRtl ? AppTextStyles.font12Bold : AppTextStyles.monoFont11Bold).copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  verticalSpace(3),
                  Text(
                    context.bidi(recording.title),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font15ExtraBold.copyWith(height: 1.25),
                  ),
                  verticalSpace(3),
                  Row(
                    children: [
                      if (watched) ...[
                        Icon(Icons.check_rounded, size: 14, color: StatusTone.success.color(context)),
                        horizontalSpace(4),
                      ],
                      Expanded(
                        child: Text(
                          [if (watched) 'recordings.watched'.tr(), meta].join(' · '),
                          style: AppTextStyles.font12Normal.secondary(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
