import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'app.dart';
import 'data/alarm_repository.dart';
import 'services/alarm_tap_bus.dart';
import 'services/notification_service.dart';
import 'state/alarm_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  final repo = AlarmRepository();
  final notifications = NotificationService.instance;
  final bus = AlarmTapBus.instance;

  final store = AlarmStore(repo: repo, notifications: notifications);
  await store.init();

  await notifications.init(
    onAlarmTapped: (alarmId) => bus.push(alarmId),
  );

  final launchAlarmId = await notifications.appLaunchAlarmIdIfAny();

  runApp(AlarmLockApp(store: store, launchAlarmId: launchAlarmId, bus: bus));
}
