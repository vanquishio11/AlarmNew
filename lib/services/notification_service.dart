import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/alarm.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'alarms';
  static const _channelName = 'Alarms';
  static const _channelDesc = 'Alarm notifications';

  Future<void> init({
    required void Function(String alarmId) onAlarmTapped,
  }) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {},
    );

    final initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload != null && payload.isNotEmpty) {
          onAlarmTapped(payload);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Android channel
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
    );

    await plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Required for background tap callback on Android.
  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse response) {}

  int _notificationIdForAlarm(String alarmId) => alarmId.hashCode & 0x7fffffff;

  Future<void> scheduleDailyAlarm(Alarm alarm) async {
    final id = _notificationIdForAlarm(alarm.id);

    // iOS uses the sound file name (bundled) for custom sounds in notifications.
    // For simplicity, we always play sound inside the app on the Ring screen.
    // Notification sound is still enabled (default).
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );

    final next = _nextInstanceOfTime(alarm.hour, alarm.minute);

    await plugin.zonedSchedule(
      id,
      alarm.label.isEmpty ? 'Alarm' : alarm.label,
      'Tap to stop (password required)',
      next,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: alarm.id,
      matchDateTimeComponents: DateTimeComponents.time, // daily
    );

    if (kDebugMode) {
      // ignore: avoid_print
      print('Scheduled alarm ${alarm.id} at $next');
    }
  }

  Future<void> cancelAlarm(String alarmId) async {
    final id = _notificationIdForAlarm(alarmId);
    await plugin.cancel(id);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<String?> appLaunchAlarmIdIfAny() async {
    final details = await plugin.getNotificationAppLaunchDetails();
    final resp = details?.notificationResponse;
    return resp?.payload;
  }
}
