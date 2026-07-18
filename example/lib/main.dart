// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import 'platform_selector.dart';
import 'reminder_alarm_page.dart';
import 'simple_polling_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // home: const ImprovedPollingTest(),
      home: const HomeLauncher(),
    );
  }
}

/// Simple launcher so both the per-platform examples and the new
/// cross-platform reminder/alarm example are reachable everywhere.
class HomeLauncher extends StatelessWidget {
  const HomeLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Master Examples'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.notifications_active,
                  size: 72,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PlatformSelector()),
                  ),
                  icon: const Icon(Icons.devices),
                  label: const Text('Platform notification examples'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReminderAlarmPage(),
                    ),
                  ),
                  icon: const Icon(Icons.alarm),
                  label: const Text('⏰ Timed Reminder / Alarm (all platforms)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SimplePollingPage(),
                    ),
                  ),
                  icon: const Icon(Icons.http),
                  label: const Text('Simple HTTP polling example'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
