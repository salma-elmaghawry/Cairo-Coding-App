import 'package:flutter/widgets.dart';

class Breakpoints {
  static const double compact = 600;
  static const double wide = 960;
}

extension ScreenSize on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isWideScreen => screenWidth >= Breakpoints.wide;
}
