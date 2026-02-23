import 'dart:async';

import 'package:flutter/material.dart';
import 'package:notification_master/notification_master.dart';

import 'flutter_notification_client.dart'; // Import the client

/// Improved polling test with proper sound handling and background service
class ImprovedPollingTest extends StatefulWidget {
  const ImprovedPollingTest({super.key});

  @override
  State<ImprovedPollingTest> createState() => _ImprovedPollingTestState();
}

class _ImprovedPollingTestState extends State<ImprovedPollingTest> {
  // Use the new NotificationPollingClient
  late final NotificationPollingClient _pollingClient;

  bool _isPolling = false;
  bool isForeground = false;
  String _status = 'Stopped';
  String _lastError = '';

  final String pollingUrl =
      'http://notification.bettervote.eu/send_notification.php?action=send&mode=sequence&interval=50';

  @override
  void initState() {
    super.initState();
    // Initialize the client with high importance and sound enabled
    _pollingClient = NotificationPollingClient(
      pollingUrl: pollingUrl,
      intervalSeconds: 60, // Default interval
      channelId:
          'server_notifications_v2', // Versioned channel for fresh settings
      channelName: 'Server Notifications V2',
      channelDescription: 'Notifications from server with sound',
      importance:
          NotificationImportance.high, // Ensure HIGH importance for sound
      enableSound: true,
      enableVibration: true,
    );

    _initialize();
  }

  @override
  void dispose() {
    _pollingClient.stopLocalPolling();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() => _status = 'Initializing...');

    try {
      await _pollingClient.initialize();
      setState(() => _status = 'Ready');
    } catch (e) {
      setState(() {
        _status = 'Initialization Failed';
        _lastError = e.toString();
      });
    }
  }

  /// Start local polling (works when app is open)
  Future<void> _startLocalPolling() async {
    await _pollingClient.startLocalPolling(runImmediately: true);

    setState(() {
      _isPolling = true;
      isForeground = false;
      _status = 'Local Polling Active (60s)';
    });
  }

  /// Start foreground service (works even when app is closed)
  Future<void> _startForegroundService() async {
    final success = await _pollingClient.startForegroundServicePolling(
      intervalMinutes: 1, // Minimum 1 minute for foreground service
      serviceChannelId: 'polling_service_v2',
      serviceChannelName: 'Notification Service V2',
      serviceChannelDescription: 'Keeps checking for new notifications',
      serviceImportance:
          NotificationImportance.low, // Low for persistent service notification
      serviceEnableSound: false, // Service notification shouldn't make sound
    );

    if (success) {
      setState(() {
        _isPolling = true;
        isForeground = true;
        _status = 'Foreground Service Active (1m)';
      });
    } else {
      setState(() => _status = 'Failed to start foreground service');
    }
  }

  /// Stop all polling
  Future<void> _stopAll() async {
    await _pollingClient.stopAllPolling();

    setState(() {
      _isPolling = false;
      isForeground = false;
      _status = 'Stopped';
    });
  }

  /// Poll once manually
  Future<void> _pollOnce() async {
    try {
      setState(() => _lastError = '');
      await _pollingClient.pollOnce();

      // Feedback UI update (optional, since polling happens in background/client)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Manual poll requested')));
    } catch (e) {
      setState(() => _lastError = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Improved Polling Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: _isPolling ? Colors.green.shade50 : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      _isPolling ? Icons.check_circle : Icons.stop_circle,
                      size: 48,
                      color: _isPolling ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (_lastError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _lastError,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isPolling ? null : _startLocalPolling,
              icon: const Icon(Icons.timer),
              label: const Text('Start Local Polling (App Open)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isPolling ? null : _startForegroundService,
              icon: const Icon(Icons.notifications_active),
              label: const Text('Start Foreground Service (App Closed)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pollOnce,
              icon: const Icon(Icons.refresh),
              label: const Text('Poll Once Manually'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isPolling ? _stopAll : null,
              icon: const Icon(Icons.stop),
              label: const Text('Stop Polling'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
