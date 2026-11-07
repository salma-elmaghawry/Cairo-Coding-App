import 'package:cairo_coding_app/core/helpers/breakpoints.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/eyebrow_text.dart';
import 'package:flutter/material.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.children,
    this.eyebrow,
    this.title,
    this.subtitle,
    this.actions = const [],
    this.header,
  });

  final String? eyebrow;
  final String? title;

  /// One line under the title, such as what the page is for.
  final String? subtitle;
  final Widget? header;
  final List<Widget> actions;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final horizontal = context.screenWidth >= Breakpoints.compact ? 32.0 : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 40),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?header,
              if (title != null)
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (eyebrow != null) EyebrowText(eyebrow!),
                        verticalSpace(4),
                        Text(title!, style: AppTextStyles.font28ExtraBold.copyWith(letterSpacing: -.5)),
                        if (subtitle != null) ...[
                          verticalSpace(4),
                          Text(subtitle!, style: AppTextStyles.font14Normal.secondary(context)),
                        ],
                      ],
                    ),
                    if (actions.isNotEmpty)
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: actions,
                      ),
                  ],
                ),
              verticalSpace(24),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
