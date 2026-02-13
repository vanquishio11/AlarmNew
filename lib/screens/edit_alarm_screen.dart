import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/alarm.dart';
import '../services/sound_library.dart';
import '../state/alarm_store.dart';

class EditAlarmScreen extends StatefulWidget {
  const EditAlarmScreen({super.key, required this.store, this.alarmId});
  final AlarmStore store;
  final String? alarmId;

  @override
  State<EditAlarmScreen> createState() => _EditAlarmScreenState();
}

class _EditAlarmScreenState extends State<EditAlarmScreen> {
  late Alarm _alarm;
  late final TextEditingController _labelCtrl;
  late final TextEditingController _passwordCtrl;

  @override
  void initState() {
    super.initState();
    final existing = widget.alarmId == null ? null : widget.store.byId(widget.alarmId!);
    _alarm = existing ?? widget.store.newDraft();
    _labelCtrl = TextEditingController(text: _alarm.label);
    _passwordCtrl = TextEditingController(text: _alarm.password);
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final initial = DateTime(2000, 1, 1, _alarm.hour, _alarm.minute);
    DateTime temp = initial;

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SizedBox(
          height: 320,
          child: Column(
            children: [
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  minuteInterval: 1,
                  initialDateTime: initial,
                  onDateTimeChanged: (d) => temp = d,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _alarm = _alarm.copyWith(hour: temp.hour, minute: temp.minute);
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Set time'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickSoundFile() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'caf'],
    );
    if (res == null || res.files.isEmpty) return;
    final path = res.files.single.path;
    if (path == null) return;

    // Copy into app documents directory so the path stays accessible.
    final docs = await getApplicationDocumentsDirectory();
    final destDir = Directory('${docs.path}/alarm_sounds')..createSync(recursive: true);
    final fileName = path.split('/').last;
    final destPath = '${destDir.path}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await File(path).copy(destPath);

    setState(() {
      _alarm = _alarm.copyWith(soundKind: AlarmSoundKind.file, soundPath: destPath);
    });
  }

  Future<void> _save() async {
    final updated = _alarm.copyWith(
      label: _labelCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    // simple validation
    if (updated.password.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a password (required to stop the alarm).')),
      );
      return;
    }

    final exists = widget.alarmId != null && widget.store.byId(widget.alarmId!) != null;
    if (exists) {
      await widget.store.updateAlarm(updated);
    } else {
      await widget.store.addAlarm(updated);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteIfExisting() async {
    if (widget.alarmId == null) return;
    final id = widget.alarmId!;
    await widget.store.deleteAlarm(id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final soundLabel = _alarm.soundKind == AlarmSoundKind.asset
        ? (SoundLibrary.builtIn.firstWhere((s) => s.assetPath == _alarm.soundPath, orElse: () => SoundLibrary.builtIn.first).name)
        : 'Custom file';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alarmId == null ? 'New alarm' : 'Edit alarm'),
        actions: [
          if (widget.alarmId != null)
            IconButton(
              tooltip: 'Delete',
              onPressed: _deleteIfExisting,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Time', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          _alarm.timeLabel(),
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _pickTime,
                      child: const Text('Pick'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Label', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _labelCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Gym, Study, Wake up',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sound', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Selected: $soundLabel', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final s in SoundLibrary.builtIn)
                          ChoiceChip(
                            label: Text(s.name),
                            selected: _alarm.soundKind == AlarmSoundKind.asset && _alarm.soundPath == s.assetPath,
                            onSelected: (_) {
                              setState(() {
                                _alarm = _alarm.copyWith(soundKind: AlarmSoundKind.asset, soundPath: s.assetPath);
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickSoundFile,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Pick a sound file'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tip: On iOS you may need to pick from Files / iCloud Drive.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Password to stop', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Required',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'When the alarm rings, it keeps playing until the correct password is entered.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Save alarm'),
            ),
          ],
        ),
      ),
    );
  }
}
