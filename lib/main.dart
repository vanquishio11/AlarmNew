import 'package:flutter/material.dart';

import 'app.dart';
import 'data/alarm_repository.dart';
import 'services/alarm_tap_bus.dart';
import 'services/notification_service.dart';
import 'state/alarm_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Create objects only (cheap). Do NOT initialize them yet.
  final repo = AlarmRepository();
  final notifications = NotificationService.instance;
  final bus = AlarmTapBus.instance;
  final store = AlarmStore(repo: repo, notifications: notifications);

  // Launch UI immediately — this is critical for iOS.
  runApp(AlarmLockApp(store: store, bus: bus));
}
