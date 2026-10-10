import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class CairoTime {
  static tz.Location? _location;

  static void init() {
    if (_location != null) return;
    tz_data.initializeTimeZones();
    _location = tz.getLocation('Africa/Cairo');
  }

  static tz.Location get location {
    init();
    return _location!;
  }

  static DateTime at(int year, int month, int day, [int hour = 0, int minute = 0]) =>
      DateTime.fromMillisecondsSinceEpoch(
        tz.TZDateTime(location, year, month, day, hour, minute).millisecondsSinceEpoch,
      );

  static tz.TZDateTime from(DateTime moment) => tz.TZDateTime.from(moment, location);
}
