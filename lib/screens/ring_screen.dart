import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../state/alarm_store.dart';

class RingScreen extends StatefulWidget {
  const RingScreen({super.key, required this.store, required this.alarmId});
  final AlarmStore store;
  final String alarmId;

  @override
  State<RingScreen> createState() => _RingScreenState();
}

class _RingScreenState extends State<RingScreen> {
  final _passwordCtrl = TextEditingController();
  String? _error;
  bool _stopping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final alarm = widget.store.byId(widget.alarmId);
    if (alarm == null) return;
    await AudioService.instance.playLooping(alarm);
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _tryStop() async {
    final alarm = widget.store.byId(widget.alarmId);
    if (alarm == null) return;

    final input = _passwordCtrl.text;
    if (input != alarm.password) {
      setState(() => _error = 'Wrong password.');
      return;
    }

    setState(() {
      _error = null;
      _stopping = true;
    });

    await AudioService.instance.stop();

    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final alarm = widget.store.byId(widget.alarmId);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.notifications_active, size: 28, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    Text('Alarm ringing', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(alarm?.timeLabel() ?? '--:--', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 6),
                            Text(alarm?.label.isEmpty ?? true ? 'Alarm' : alarm!.label),
                          ],
                        ),
                        const Spacer(),
                        if (_stopping) const CircularProgressIndicator(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Enter password to stop', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'Password',
                    errorText: _error,
                  ),
                  onSubmitted: (_) => _tryStop(),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _stopping ? null : _tryStop,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: const Text('Stop alarm'),
                ),
                const SizedBox(height: 10),
                Text(
                  'If you close the app, the alarm screen will re-open when you tap the notification again.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
