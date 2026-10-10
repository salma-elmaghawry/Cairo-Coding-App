import 'package:flutter/material.dart';

class TwoPane extends StatelessWidget {
  const TwoPane({super.key, required this.main, required this.side, this.sideFirst = false});

  final Widget main;
  final Widget side;
  final bool sideFirst;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: sideFirst ? [side, const SizedBox(height: 20), main] : [main, const SizedBox(height: 20), side],
          );
        }
        final paneMain = Expanded(child: main);
        final paneSide = SizedBox(width: 340, child: side);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sideFirst
              ? [paneSide, const SizedBox(width: 20), paneMain]
              : [paneMain, const SizedBox(width: 20), paneSide],
        );
      },
    );
  }
}
