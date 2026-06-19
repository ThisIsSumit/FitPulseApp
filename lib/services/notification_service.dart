import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const int workoutReminderId = 1001;
  static const int communityUpdateId = 2001;
  static const int testScheduleId = 8888;
  static const int testInstantId = 9999;

  static Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    _setLocalTimezoneFromOffset();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {},
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'workout_reminders',
          'Workout Reminders',
          description: 'Daily reminder to complete your workout',
          importance: Importance.high,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'community_updates',
          'Community Updates',
          description: 'Likes, comments, and challenge updates',
          importance: Importance.defaultImportance,
        ),
      );
    }

    _initialized = true;
  }

  /// Sets tz.local using the device's UTC offset — no native plugin needed.
  /// This avoids relying on flutter_timezone (which requires a Gradle/network
  /// fetch that can fail on restricted networks).
  static void _setLocalTimezoneFromOffset() {
    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.inHours;
    final minutes = offset.inMinutes.remainder(60).abs();

    // Map common offsets to IANA identifiers the `timezone` package recognizes.
    // Using Etc/GMT+N is a safe universal fallback that doesn't need exact
    // city-level timezone names — it has the correct UTC offset, which is
    // all that matters for scheduling.
    final sign = offset.isNegative ? '+' : '-'; // Etc/GMT signs are inverted
    final tzName = minutes == 0
        ? 'Etc/GMT$sign${hours.abs()}'
        : 'Etc/GMT$sign${hours.abs()}'; // Etc/GMT doesn't support :30 offsets

    try {
      tz.setLocalLocation(tz.getLocation(tzName));
      print(
          '🌍 Local timezone set via offset to: $tzName (UTC${offset.isNegative ? '-' : '+'}${hours.abs()}h)');
    } catch (e) {
      // Fallback for half-hour offsets (e.g. IST = UTC+5:30) which Etc/GMT can't express.
      // Use a known IANA zone that matches common offsets instead.
      final fallbackZone = _bestMatchTimezone(offset);
      tz.setLocalLocation(tz.getLocation(fallbackZone));
      print('🌍 Local timezone set via fallback to: $fallbackZone');
    }
  }

  /// Matches common UTC offsets (including half-hour ones like IST) to a
  /// known IANA timezone name as a fallback when Etc/GMT can't express it.
  static String _bestMatchTimezone(Duration offset) {
    final totalMinutes = offset.inMinutes;
    switch (totalMinutes) {
      case 330:
        return 'Asia/Kolkata'; // UTC+5:30 (India)
      case 345:
        return 'Asia/Kathmandu'; // UTC+5:45
      case 570:
        return 'Australia/Darwin'; // UTC+9:30
      case 630:
        return 'Australia/Adelaide'; // UTC+10:30
      case -210:
        return 'America/St_Johns'; // UTC-3:30
      default:
        // No half-hour match — use the nearest whole-hour Etc/GMT zone.
        final hours = (totalMinutes / 60).round();
        final sign = hours < 0 ? '+' : '-';
        return 'Etc/GMT$sign${hours.abs()}';
    }
  }

  /// Prints the exact pending workout reminder + its next trigger time, if any.
  static Future<void> debugWorkoutReminder() async {
    final pending = await _plugin.pendingNotificationRequests();
    final reminder = pending.where((p) => p.id == workoutReminderId).toList();
    print('🔍 Workout reminder pending count: ${reminder.length}');
    if (reminder.isNotEmpty) {
      print('🔍 Title: ${reminder.first.title}, Body: ${reminder.first.body}');
    } else {
      print('🔍 NO workout reminder is currently scheduled!');
    }
  }

  static Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<bool> hasPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  static Future<bool> canScheduleExactAlarms() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return true;
    final granted = await androidPlugin.canScheduleExactNotifications();
    return granted ?? false;
  }

  static Future<void> requestExactAlarmPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  static Future<bool> requestIgnoreBatteryOptimization() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  static Future<bool> isBatteryOptimizationIgnored() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    return status.isGranted;
  }

  static Future<void> scheduleWorkoutReminder({
    required int hour,
    required int minute,
  }) async {
    await init();
    final exactAllowed = await canScheduleExactAlarms();

    // NOTE: all positional, not named — id, title, body, scheduledDate, details
    await _plugin.zonedSchedule(
      id: workoutReminderId,
      title: '💪 Time to move!',
      body: "Don't break your streak — log today's workout.",
      scheduledDate: _nextInstanceOf(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'workout_reminders',
          'Workout Reminders',
          channelDescription: 'Daily reminder to complete your workout',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: exactAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    final pending = await _plugin.pendingNotificationRequests();
    print(
        '📋 [workout reminder] Pending: ${pending.map((p) => '${p.id}:${p.title}').toList()}');
  }

  static Future<void> cancelWorkoutReminder() async {
    await _plugin.cancel(id: workoutReminderId);
  }

  static Future<void> showCommunityUpdate({
    required String title,
    required String body,
  }) async {
    await init();
    await _plugin.show(
      id: communityUpdateId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'community_updates',
          'Community Updates',
          channelDescription: 'Likes, comments, and challenge updates',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Fires instantly — confirms permission + channel + icon all work.
  static Future<void> showTestNotification() async {
    await init();
    await _plugin.show(
      id: testInstantId,
      title: '✅ Notifications working!',
      body: 'If you see this, your setup is correct.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'workout_reminders',
          'Workout Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Schedules a one-off notification N seconds from now — isolates
  /// zonedSchedule() + exact-alarm behavior from the 24h daily reminder.
  static Future<void> scheduleTestIn(int seconds) async {
    await init();
    final scheduledTime =
        tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
    final exactAllowed = await canScheduleExactAlarms();

    print(
        '🔔 Scheduling test for $scheduledTime (exact allowed: $exactAllowed)');

    await _plugin.zonedSchedule(
      id: testScheduleId,
      title: '⏰ Scheduled test fired!',
      body: 'zonedSchedule() is working correctly.',
      scheduledDate: scheduledTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'workout_reminders',
          'Workout Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: exactAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );

    final pending = await _plugin.pendingNotificationRequests();
    print(
        '📋 [test] Pending: ${pending.map((p) => '${p.id}:${p.title}').toList()}');
  }

  static Future<void> cancelAll() => _plugin.cancelAll();

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    print(scheduled);
    return scheduled;
  }
}
