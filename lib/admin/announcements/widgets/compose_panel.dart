import 'package:cairo_coding_app/admin/admin_providers.dart';
import 'package:cairo_coding_app/admin/widgets/admin_panel.dart';
import 'package:cairo_coding_app/core/error_handling/result.dart';
import 'package:cairo_coding_app/core/helpers/bidi.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/helpers/ui_helpers.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/app_text_field.dart';
import 'package:cairo_coding_app/core/widgets/icon_tile.dart';
import 'package:cairo_coding_app/core/widgets/primary_button.dart';
import 'package:cairo_coding_app/data/data_providers.dart';
import 'package:cairo_coding_app/data/models/academy_group.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Writes an announcement and sends it to the groups picked.
class ComposePanel extends ConsumerStatefulWidget {
  const ComposePanel({super.key});

  @override
  ConsumerState<ComposePanel> createState() => _ComposePanelState();
}

class _ComposePanelState extends ConsumerState<ComposePanel> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final Set<String> _groupIds = {};
  bool _sending = false;
  bool _showGroupError = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty) ? 'validation.required'.tr() : null;

  Future<void> _send() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _showGroupError = _groupIds.isEmpty);
    if (!valid || _groupIds.isEmpty) return;
    setState(() => _sending = true);
    final result = await ref
        .read(academyRepositoryProvider)
        .postAnnouncement(title: _title.text, body: _body.text, groupIds: _groupIds.toList());
    if (!mounted) return;
    setState(() => _sending = false);
    switch (result) {
      case Ok():
        _title.clear();
        _body.clear();
        setState(_groupIds.clear);
        showAppSnackBar(context, 'admin.announcements.sent'.tr());
      case Err(:final failure):
        showAppSnackBar(context, failure.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = (ref.watch(adminGroupsProvider).value ?? const <AcademyGroup>[]).where((g) => !g.archived).toList();
    final colorScheme = Theme.of(context).colorScheme;

    return AdminPanel(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const IconTile(icon: Icons.campaign_outlined, size: 40, iconSize: 20),
                horizontalSpace(12),
                Flexible(child: Text('admin.announcements.new'.tr(), style: AppTextStyles.font18ExtraBold)),
              ],
            ),
            verticalSpace(16),
            AppTextField(label: 'admin.announcements.title_label'.tr(), controller: _title, validator: _required),
            verticalSpace(12),
            AppTextField(
              label: 'admin.announcements.body_label'.tr(),
              controller: _body,
              maxLines: 5,
              validator: _required,
            ),
            verticalSpace(14),
            Text('admin.announcements.to'.tr(), style: AppTextStyles.font14Bold),
            verticalSpace(8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final group in groups)
                  FilterChip(
                    label: Text(context.bidi(group.name)),
                    selected: _groupIds.contains(group.id),
                    onSelected: (on) => setState(() => on ? _groupIds.add(group.id) : _groupIds.remove(group.id)),
                  ),
              ],
            ),
            if (_showGroupError && _groupIds.isEmpty) ...[
              verticalSpace(6),
              Text(
                'admin.announcements.pick_group'.tr(),
                style: AppTextStyles.font12Normal.copyWith(color: colorScheme.error),
              ),
            ],
            verticalSpace(12),
            Text('admin.announcements.in_app'.tr(), style: AppTextStyles.font12Normal.secondary(context)),
            verticalSpace(16),
            PrimaryButton(
              label: 'admin.announcements.send'.tr(),
              icon: Icons.send_rounded,
              height: 46,
              glow: true,
              isLoading: _sending,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}
