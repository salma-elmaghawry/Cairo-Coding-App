import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/link_launcher.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/data/models/recording.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String recordingHost(String url) {
  final host = Uri.tryParse(url)?.host ?? '';
  if (host.contains('youtu')) return 'YouTube';
  if (host.contains('drive.google') || host.contains('docs.google')) return 'Drive';
  return host.replaceFirst('www.', '');
}

String recordingLength(int minutes) => minutes <= 0 ? '' : '${minutes ~/ 60}:${'${minutes % 60}'.padLeft(2, '0')}';

/// Copy, edit and delete, shared by the grid card and the list row.
class RecordingActions extends StatelessWidget {
  const RecordingActions({super.key, required this.recording, required this.onEdit, required this.onDelete});

  final Recording recording;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final plain = IconButton.styleFrom(
      side: BorderSide.none,
      minimumSize: const Size(32, 32),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          style: plain,
          tooltip: 'admin.recordings.copy'.tr(),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: recording.url));
            if (context.mounted) showAppSnackBar(context, 'admin.recordings.copied'.tr());
          },
          icon: const Icon(Icons.link_rounded, size: 18),
        ),
        IconButton(
          style: plain,
          tooltip: 'admin.recordings.edit'.tr(),
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 18),
        ),
        IconButton(
          style: plain.copyWith(foregroundColor: WidgetStatePropertyAll(colorScheme.error)),
          tooltip: 'common.delete'.tr(),
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
        ),
      ],
    );
  }
}

class RecordingCard extends StatelessWidget {
  const RecordingCard({
    super.key,
    required this.recording,
    required this.watched,
    required this.members,
    required this.onEdit,
    required this.onDelete,
  });

  final Recording recording;
  final int watched;
  final int members;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final host = recordingHost(recording.url);
    final length = recordingLength(recording.durationMin);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => openExternalLink(recording.url),
            child: Container(
              height: 112,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: AlignmentDirectional.topEnd.resolve(Directionality.of(context)),
                  radius: 1.3,
                  colors: [colorScheme.primary.withValues(alpha: .3), colorScheme.surfaceContainerLowest],
                  stops: const [0, .6],
                ),
              ),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '// session ${'${recording.sessionNumber}'.padLeft(2, '0')}',
                      style: AppTextStyles.monoFont12Medium.muted(context),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: host == 'YouTube' ? colorScheme.error : colorScheme.primary,
                          ),
                        ),
                        horizontalSpace(6),
                        Text(host, style: AppTextStyles.monoFont11Bold),
                        const Spacer(),
                        if (length.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: .72),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(length, style: AppTextStyles.monoFont10Medium.copyWith(color: Colors.white)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.bidi(recording.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font15ExtraBold,
                ),
                Text(context.shortDay(recording.recordedAt), style: AppTextStyles.font12Normal.secondary(context)),
                verticalSpace(6),
                Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 15, color: colorScheme.onSurfaceVariant),
                    horizontalSpace(6),
                    Expanded(
                      child: Text(
                        'admin.recordings.watched'.tr(args: ['$watched/$members']),
                        style: AppTextStyles.font12SemiBold.secondary(context),
                      ),
                    ),
                    RecordingActions(recording: recording, onEdit: onEdit, onDelete: onDelete),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
