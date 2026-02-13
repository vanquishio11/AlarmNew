import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/home_screen.dart';
import 'screens/edit_alarm_screen.dart';
import 'screens/ring_screen.dart';
import 'services/alarm_tap_bus.dart';
import 'state/alarm_store.dart';

class AlarmLockApp extends StatefulWidget {
  const AlarmLockApp({super.key, required this.store, required this.bus, this.launchAlarmId});

  final AlarmStore store;
  final AlarmTapBus bus;
  final String? launchAlarmId;

  @override
  State<AlarmLockApp> createState() => _AlarmLockAppState();
}

class _AlarmLockAppState extends State<AlarmLockApp> {
  late final GoRouter _router = GoRouter(
    initialLocation: widget.launchAlarmId == null ? '/' : '/ring/${widget.launchAlarmId}',
    refreshListenable: widget.bus.tappedAlarmId,
    redirect: (context, state) {
      final tapped = widget.bus.tappedAlarmId.value;
      if (tapped != null && state.matchedLocation != '/ring/$tapped') {
        // Clear so we don't keep redirecting forever.
        WidgetsBinding.instance.addPostFrameCallback((_) => widget.bus.clear());
        return '/ring/$tapped';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => HomeScreen(store: widget.store),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) {
              final id = state.uri.queryParameters['id'];
              return EditAlarmScreen(store: widget.store, alarmId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/ring/:id',
        builder: (context, state) => RingScreen(store: widget.store, alarmId: state.pathParameters['id']!),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7C4DFF));
    return MaterialApp.router(
      title: 'AlarmLock',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        textTheme: const TextTheme(
          displaySmall: TextStyle(fontWeight: FontWeight.w700),
          titleLarge: TextStyle(fontWeight: FontWeight.w700),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest.withOpacity(0.55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      routerConfig: _router,
    );
  }
}
