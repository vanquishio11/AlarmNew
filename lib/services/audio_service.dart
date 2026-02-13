import 'dart:io';

import 'package:just_audio/just_audio.dart';

import '../models/alarm.dart';

class AudioService {
  AudioService._();
  static final instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();

  Future<void> playLooping(Alarm alarm) async {
    await stop();
    if (alarm.soundKind == AlarmSoundKind.asset) {
      await _player.setAsset(alarm.soundPath);
    } else {
      await _player.setFilePath(alarm.soundPath);
    }
    _player.setLoopMode(LoopMode.one);
    await _player.play();
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
