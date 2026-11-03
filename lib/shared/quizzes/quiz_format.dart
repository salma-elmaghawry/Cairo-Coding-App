/// "03:07", or "1:03:07" past an hour. Digits stay Latin, like the app's other clocks.
String formatClock(Duration duration) {
  final safe = duration.isNegative ? Duration.zero : duration;
  String two(int value) => value.toString().padLeft(2, '0');
  final minutes = two(safe.inMinutes.remainder(60));
  final seconds = two(safe.inSeconds.remainder(60));
  return safe.inHours > 0 ? '${safe.inHours}:$minutes:$seconds' : '$minutes:$seconds';
}

String optionLetter(int index) => String.fromCharCode('A'.codeUnitAt(0) + index);

/// 0 when there's nothing to divide by, so an empty quiz doesn't show NaN.
int percentOf(num part, num whole) => whole <= 0 ? 0 : (part * 100 / whole).round();
