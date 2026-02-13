import 'package:flutter/foundation.dart';

class AlarmTapBus {
  AlarmTapBus._();
  static final instance = AlarmTapBus._();

  /// Set when user taps an alarm notification.
  final ValueNotifier<String?> tappedAlarmId = ValueNotifier<String?>(null);

  void push(String alarmId) => tappedAlarmId.value = alarmId;

  void clear() => tappedAlarmId.value = null;
}
