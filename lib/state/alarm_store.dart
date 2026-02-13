import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/alarm_repository.dart';
import '../models/alarm.dart';
import '../services/notification_service.dart';

class AlarmStore extends ChangeNotifier {
  AlarmStore({
    required AlarmRepository repo,
    required NotificationService notifications,
  })  : _repo = repo,
        _notifications = notifications;

  final AlarmRepository _repo;
  final NotificationService _notifications;

  final List<Alarm> _alarms = [];
  List<Alarm> get alarms => List.unmodifiable(_alarms);

  Future<void> init() async {
    _alarms
      ..clear()
      ..addAll(await _repo.load());
    // Re-schedule enabled alarms
    for (final a in _alarms) {
      if (a.enabled) {
        await _notifications.scheduleDailyAlarm(a);
      } else {
        await _notifications.cancelAlarm(a.id);
      }
    }
    notifyListeners();
  }

  Future<void> addAlarm(Alarm alarm) async {
    _alarms.add(alarm);
    await _repo.save(_alarms);
    if (alarm.enabled) await _notifications.scheduleDailyAlarm(alarm);
    notifyListeners();
  }

  Future<void> updateAlarm(Alarm alarm) async {
    final idx = _alarms.indexWhere((a) => a.id == alarm.id);
    if (idx == -1) return;
    _alarms[idx] = alarm;
    await _repo.save(_alarms);

    await _notifications.cancelAlarm(alarm.id);
    if (alarm.enabled) await _notifications.scheduleDailyAlarm(alarm);

    notifyListeners();
  }

  Future<void> deleteAlarm(String id) async {
    _alarms.removeWhere((a) => a.id == id);
    await _repo.save(_alarms);
    await _notifications.cancelAlarm(id);
    notifyListeners();
  }

  Future<void> toggleEnabled(String id, bool enabled) async {
    final idx = _alarms.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    final updated = _alarms[idx].copyWith(enabled: enabled);
    _alarms[idx] = updated;
    await _repo.save(_alarms);

    if (enabled) {
      await _notifications.scheduleDailyAlarm(updated);
    } else {
      await _notifications.cancelAlarm(id);
    }
    notifyListeners();
  }

  Alarm? byId(String id) {
    for (final a in _alarms) {
      if (a.id == id) return a;
    }
    return null;
  }

  Alarm newDraft() {
    final now = DateTime.now();
    return Alarm(
      id: const Uuid().v4(),
      hour: now.hour,
      minute: (now.minute + 1) % 60,
      enabled: true,
      label: '',
      soundKind: AlarmSoundKind.asset,
      soundPath: 'assets/sounds/beep.wav',
      password: '',
    );
  }
}
