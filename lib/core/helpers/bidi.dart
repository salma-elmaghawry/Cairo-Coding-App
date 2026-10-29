import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;

extension BidiIsolate on String {
  /// Lays the text out in the direction of its first letter wherever it's placed, so
  /// "C++" or "OOP (Encapsulation)" keeps its symbols in place inside Arabic text.
  String get isolated => isEmpty ? this : '\u2068$this\u2069';
}

extension BidiContext on BuildContext {
  /// [text] as it is when it already reads in the UI's direction, otherwise [BidiIsolate.isolated].
  String bidi(String text) {
    final rtlUi = Directionality.of(this) == TextDirection.rtl;
    final differs = rtlUi ? intl.Bidi.startsWithLtr(text) : intl.Bidi.startsWithRtl(text);
    return differs ? text.isolated : text;
  }
}
