import 'dart:convert';

enum AlarmSoundKind { asset, file }

class Alarm {
  Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    required this.enabled,
    required this.label,
    required this.soundKind,
    required this.soundPath,
    required this.password,
  });

  final String id;
  final int hour;
  final int minute;
  final bool enabled;
  final String label;
  final AlarmSoundKind soundKind;
  final String soundPath; // asset path (e.g. assets/sounds/beep.wav) or file path
  final String password;

  Alarm copyWith({
    String? id,
    int? hour,
    int? minute,
    bool? enabled,
    String? label,
    AlarmSoundKind? soundKind,
    String? soundPath,
    String? password,
  }) {
    return Alarm(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
      label: label ?? this.label,
      soundKind: soundKind ?? this.soundKind,
      soundPath: soundPath ?? this.soundPath,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'enabled': enabled,
        'label': label,
        'soundKind': soundKind.name,
        'soundPath': soundPath,
        'password': password,
      };

  static Alarm fromMap(Map<String, dynamic> map) {
    final kind = AlarmSoundKind.values.firstWhere(
      (k) => k.name == (map['soundKind'] as String? ?? 'asset'),
      orElse: () => AlarmSoundKind.asset,
    );
    return Alarm(
      id: map['id'] as String,
      hour: (map['hour'] as num).toInt(),
      minute: (map['minute'] as num).toInt(),
      enabled: map['enabled'] as bool? ?? true,
      label: map['label'] as String? ?? '',
      soundKind: kind,
      soundPath: map['soundPath'] as String? ?? 'assets/sounds/beep.wav',
      password: map['password'] as String? ?? '',
    );
  }

  String toJson() => jsonEncode(toMap());
  static Alarm fromJson(String json) => fromMap(jsonDecode(json) as Map<String, dynamic>);

  String timeLabel() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
