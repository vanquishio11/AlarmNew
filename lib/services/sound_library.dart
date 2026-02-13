import '../models/alarm.dart';

class BuiltInSound {
  const BuiltInSound(this.name, this.assetPath);
  final String name;
  final String assetPath;
}

class SoundLibrary {
  static const builtIn = <BuiltInSound>[
    BuiltInSound('Beep', 'assets/sounds/beep.wav'),
    BuiltInSound('Soft chime', 'assets/sounds/soft_chime.wav'),
  ];

  static AlarmSoundKind kindFromPath(String path) {
    return path.startsWith('assets/') ? AlarmSoundKind.asset : AlarmSoundKind.file;
  }
}
