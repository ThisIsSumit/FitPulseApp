import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

/// Persists user preference toggles across app restarts and wires them
/// to real notification scheduling.
class SettingsProvider extends ChangeNotifier {
  static const _kPushNotifications = 'push_notifications';
  static const _kWorkoutReminders = 'workout_reminders';
  static const _kCommunityUpdates = 'community_updates';
  static const _kReminderHour = 'reminder_hour';
  static const _kReminderMinute = 'reminder_minute';
  static const _kLanguage = 'language';
  static const _kUnits = 'units';

  bool _pushNotifications = true;
  bool _workoutReminders = true;
  bool _communityUpdates = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 18, minute: 0);
  String _language = 'English';
  String _units = 'Metric';
  bool _loaded = false;

  bool get pushNotifications => _pushNotifications;
  bool get workoutReminders => _workoutReminders;
  bool get communityUpdates => _communityUpdates;
  TimeOfDay get reminderTime => _reminderTime;
  String get language => _language;
  String get units => _units;
  bool get loaded => _loaded;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _pushNotifications = prefs.getBool(_kPushNotifications) ?? true;
    _workoutReminders = prefs.getBool(_kWorkoutReminders) ?? true;
    _communityUpdates = prefs.getBool(_kCommunityUpdates) ?? false;
    _reminderTime = TimeOfDay(
      hour: prefs.getInt(_kReminderHour) ?? 18,
      minute: prefs.getInt(_kReminderMinute) ?? 0,
    );
    _language = prefs.getString(_kLanguage) ?? 'English';
    _units = prefs.getString(_kUnits) ?? 'Metric';
    _loaded = true;

    // Re-apply scheduling on app start based on saved state
    if (_pushNotifications && _workoutReminders) {
      await NotificationService.scheduleWorkoutReminder(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
      );
    }
    notifyListeners();
  }

  /// Returns false if the user denied OS permission — caller should show a message.
  Future<bool> setPushNotifications(bool value) async {
    if (value) {
      final granted = await NotificationService.requestPermission();
      if (!granted) return false;

      // Android 12+ needs this separately, opens system settings if not granted
      final exactAllowed = await NotificationService.canScheduleExactAlarms();
      if (!exactAllowed) {
        await NotificationService.requestExactAlarmPermission();
      }
    } else {
      await NotificationService.cancelAll();
    }
    _pushNotifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPushNotifications, value);

    if (value && _workoutReminders) {
      await NotificationService.scheduleWorkoutReminder(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
      );
    }
    notifyListeners();
    return true;
  }

  Future<void> setWorkoutReminders(bool value) async {
    _workoutReminders = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWorkoutReminders, value);

    if (value && _pushNotifications) {
      await NotificationService.scheduleWorkoutReminder(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
      );
    } else {
      await NotificationService.cancelWorkoutReminder();
    }
    notifyListeners();
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kReminderHour, time.hour);
    await prefs.setInt(_kReminderMinute, time.minute);

    if (_pushNotifications && _workoutReminders) {
      await NotificationService.scheduleWorkoutReminder(
        hour: time.hour,
        minute: time.minute,
      );
    }
    notifyListeners();
  }

  Future<void> setCommunityUpdates(bool value) async {
    _communityUpdates = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCommunityUpdates, value);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, value);
    notifyListeners();
  }

  Future<void> setUnits(String value) async {
    _units = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUnits, value);
    notifyListeners();
  }
}
