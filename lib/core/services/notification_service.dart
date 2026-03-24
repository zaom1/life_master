import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get _isSupported => !kIsWeb;

  Future<void> init() async {
    if (_initialized) return;
    if (!_isSupported) {
      _initialized = true;
      return;
    }

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String? body,
    required DateTime scheduledDate,
    String repeatType = 'none',
  }) async {
    if (!_isSupported) return;
    if (!_initialized) await init();

    if (scheduledDate.isBefore(DateTime.now()) && repeatType == 'none') {
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Notification channel for reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    DateTimeComponents? matchComponents;
    switch (repeatType) {
      case 'daily':
        matchComponents = DateTimeComponents.time;
        break;
      case 'weekly':
        matchComponents = DateTimeComponents.dayOfWeekAndTime;
        break;
      case 'monthly':
        matchComponents = DateTimeComponents.dayOfMonthAndTime;
        break;
      default:
        matchComponents = null;
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body ?? title,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchComponents,
    );
  }

  Future<void> cancelReminder(int id) async {
    if (!_isSupported) return;
    if (!_initialized) await init();
    await _notifications.cancel(id);
  }

  Future<void> cancelAllReminders() async {
    if (!_isSupported) return;
    if (!_initialized) await init();
    await _notifications.cancelAll();
  }
}
