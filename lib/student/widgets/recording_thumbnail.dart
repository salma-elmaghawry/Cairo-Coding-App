import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/data/models/recording.dart';
import 'package:flutter/material.dart';

/// A video-style cover for a recording: its session number, a play button, and where it opens.
class RecordingThumbnail extends StatelessWidget {
  const RecordingThumbnail({super.key, required this.recording, this.width, required this.height, this.badge});

  final Recording recording;

  /// Null fills the available width.
  final double? width;
  final double height;

  /// A label in the top corner, such as "Latest".
  final String? badge;

  static String? hostOf(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    if (host.contains('youtu')) return 'YouTube';
    if (host.contains('drive.google') || host.contains('docs.google')) return 'Drive';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final large = height > 100;
    // Only the large cover has room to say where the video opens.
    final host = large ? hostOf(recording.url) : null;
    final number = '${recording.sessionNumber}'.padLeft(2, '0');

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(large ? 0 : 12),
        border: large ? null : Border.all(color: colorScheme.outline),
        gradient: RadialGradient(
          center: AlignmentDirectional.topEnd.resolve(Directionality.of(context)),
          radius: 1.2,
          colors: [colorScheme.primary.withValues(alpha: .3), colorScheme.surfaceContainerLowest],
          stops: const [0, .6],
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            PositionedDirectional(
              start: large ? 22 : 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Text(
                  '#$number',
                  style: (large ? AppTextStyles.monoFont28Bold : AppTextStyles.monoFont16Bold).copyWith(
                    color: colorScheme.primary.withValues(alpha: .9),
                  ),
                ),
              ),
            ),
            Align(
              alignment: large ? const Alignment(.82, 0) : const Alignment(.45, 0),
              child: Container(
                width: large ? 56 : 30,
                height: large ? 56 : 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.onSurface.withValues(alpha: .95),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Icon(Icons.play_arrow_rounded, size: large ? 30 : 18, color: colorScheme.surfaceContainerLowest),
              ),
            ),
            if (host != null)
              Positioned(
                right: 14,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .72),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(host, style: AppTextStyles.monoFont10Medium.copyWith(color: Colors.white)),
                ),
              ),
            if (badge != null)
              Positioned(
                left: 14,
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    badge!.toUpperCase(),
                    style: AppTextStyles.font11ExtraBold.copyWith(color: colorScheme.onPrimary, letterSpacing: .6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
