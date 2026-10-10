import 'package:cairo_coding_app/core/helpers/spacing.dart';
import 'package:cairo_coding_app/core/utils/app_text_styles.dart';
import 'package:cairo_coding_app/core/widgets/eyebrow_text.dart';
import 'package:flutter/material.dart';

class TabPage extends StatelessWidget {
  const TabPage({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.slivers,
    this.trailing,
    this.onRefresh,
  });

  final String eyebrow;
  final String title;
  final Widget? trailing;
  final List<Widget> slivers;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final scrollView = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EyebrowText(eyebrow),
                      verticalSpace(4),
                      Text(title, style: AppTextStyles.font24ExtraBold),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
        ...slivers.map((sliver) => SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 20), sliver: sliver)),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );

    return SafeArea(
      bottom: false,
      child: onRefresh == null ? scrollView : RefreshIndicator(onRefresh: onRefresh!, child: scrollView),
    );
  }
}
