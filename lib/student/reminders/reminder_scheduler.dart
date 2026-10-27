import 'package:cairo_coding_app/core/theme/app_colors.dart';
import 'package:cairo_coding_app/data/models/class_session.dart';
import 'package:cairo_coding_app/student/reminders/reminder_planner.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class ReminderScheduler {
  ReminderScheduler([FlutterLocalNotificationsPlugin? plugin]) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String _channelId = 'session_reminders';
  static const String _icon = 'ic_stat_reminder';

  final FlutterLocalNotificationsPlugin _plugin;
  Future<bool?>? _initialized;
  Future<void> _queue = Future.value();

  Future<void> _init() async {
    await (_initialized ??= _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_icon),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    ));
  }

  // One change at a time, so two quick syncs can't interleave their cancels and schedules.
  Future<void> _serial(Future<void> Function() task) => _queue = _queue.catchError((_) {}).then((_) => task());

  Future<bool> requestPermission() async {
    await _init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  // Android 14+ only allows exact alarms once the user grants "Alarms & reminders". Inexact ones can arrive up to
  // an hour late, which is why the reminder text names the session time instead of saying "in 1 hour".
  Future<AndroidScheduleMode> _scheduleMode() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final exact = await android?.canScheduleExactNotifications() ?? false;
    return exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> sync(
    List<ClassSession> sessions, {
    required ReminderPlanner planner,
    required Map<String, String> groupNames,
    required DateTime now,
  }) => _serial(() async {
    await _init();
    final scheduleMode = await _scheduleMode();
    final reminders = planner.plan(sessions, groupNames: groupNames, now: now);
    final keep = {for (final reminder in reminders) reminder.id};
    for (final pending in await _plugin.pendingNotificationRequests()) {
      if (!keep.contains(pending.id)) await _plugin.cancel(id: pending.id);
    }

    for (final reminder in reminders) {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: tz.TZDateTime.from(reminder.fireAt, tz.UTC),
        androidScheduleMode: scheduleMode,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            planner.channelName,
            channelDescription: planner.channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
            color: AppColors.primaryLight,
            timeoutAfter: reminder.visibleFor.inMilliseconds,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    }
  });

  Future<void> clear() => _serial(() async {
    await _init();
    await _plugin.cancelAllPendingNotifications();
  });
}
