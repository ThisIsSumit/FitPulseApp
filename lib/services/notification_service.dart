import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

/// Handles all local notification scheduling: permissions, channels, and timers.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const int workoutReminderId = 1001;
  static const int communityUpdateId = 2001;

  /// Call once at app startup.
  static Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // we ask explicitly via permission_handler
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  /// Requests the OS-level notification permission. Returns true if granted.
  static Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<bool> hasPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Schedules a daily repeating workout reminder at the given hour/minute (24h).
  static Future<void> scheduleWorkoutReminder({
    required int hour,
    required int minute,
  }) async {
    await init();
    await _plugin.zonedSchedule(
      id:  workoutReminderId,
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
    );
  }

  static Future<void> cancelWorkoutReminder() async {
    await _plugin.cancel(id: workoutReminderId);
  }

  /// Shows an immediate notification (used for community updates while app is foregrounded,
  /// since we don't have a push server / FCM backend).
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

  static Future<void> cancelAll() => _plugin.cancelAll();

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
