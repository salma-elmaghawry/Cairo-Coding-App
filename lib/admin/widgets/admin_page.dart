import 'package:cairo_coding_app/core/helpers/breakpoints.dart';
import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/eyebrow_text.dart';
import 'package:flutter/material.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.children, this.eyebrow, this.title, this.actions = const [], this.header});

  final String? eyebrow;
  final String? title;
  final Widget? header;
  final List<Widget> actions;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final horizontal = context.screenWidth >= Breakpoints.compact ? 40.0 : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 32),
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
                        Text(title!, style: AppTextStyles.font28ExtraBold),
                      ],
                    ),
                    if (actions.isNotEmpty) Wrap(spacing: 12, runSpacing: 12, children: actions),
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
