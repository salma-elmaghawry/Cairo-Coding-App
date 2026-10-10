import 'package:cairo_coding_app/core/helpers/date_formats.dart';
import 'package:cairo_coding_app/core/helpers/link_launcher.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_card.dart';
import 'package:cairo_coding_app/core/widgets/date_badge.dart';
import 'package:cairo_coding_app/data/models/recording.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class RecordingTile extends StatelessWidget {
  const RecordingTile({super.key, required this.recording, this.groupName});

  final Recording recording;
  final String? groupName;

  Future<void> _open(BuildContext context) async {
    final opened = await openExternalLink(recording.url);
    if (!opened && context.mounted) {
      showAppSnackBar(context, 'errors.open_link_failed'.tr(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = [?groupName, context.shortDay(recording.recordedAt)].join(' · ');

    return Semantics(
      button: true,
      link: true,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        radius: 16,
        onTap: () => _open(context),
        child: Row(
          children: [
            DateBadge(top: '${recording.sessionNumber}'.padLeft(2, '0'), size: 48),
            horizontalSpace(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recording.title, style: AppTextStyles.font16Bold),
                  verticalSpace(2),
                  Text(meta, style: AppTextStyles.font14Normal.secondary(context)),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
