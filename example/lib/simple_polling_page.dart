import 'package:flutter/material.dart';
import 'package:notification_master/notification_master.dart';

class SimplePollingPage extends StatefulWidget {
  const SimplePollingPage({super.key});

  @override
  State<SimplePollingPage> createState() => _SimplePollingPageState();
}

class _SimplePollingPageState extends State<SimplePollingPage> {
  final NotificationMaster _notificationMaster = NotificationMaster();
  bool _isPollingActive = false;
  bool _isForegroundActive = false;
  String _statusMessage = 'Notification service is not active';

  // Default polling URL - using a mock API that always returns a valid response
  final String _pollingUrl = 'https://jsonplaceholder.typicode.com/posts/1';

  // Default polling interval in minutes
  final int _intervalMinutes = 1;

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
    _createNotificationChannels();
  }

  // Check if any notification service is active
  Future<void> _checkServiceStatus() async {
    try {
      // Get the active notification service
      final activeService = await _notificationMaster
          .getActiveNotificationService();

      setState(() {
        _isPollingActive = activeService == "polling";
        _isForegroundActive = activeService == "foreground";

        if (activeService == "none") {
          _statusMessage = 'Notification service is not active';
        } else if (activeService == "polling") {
          _statusMessage = 'Background polling is active';
        } else if (activeService == "foreground") {
          _statusMessage = 'Foreground service is active';
        } else if (activeService == "firebase") {
          _statusMessage = 'Firebase Cloud Messaging is active';
        } else {
          _statusMessage = 'Unknown service is active: $activeService';
        }
      });
    } catch (e) {
      setState(() {
        _isPollingActive = false;
        _isForegroundActive = false;
        _statusMessage = 'Error checking service status: $e';
      });
    }
  }

  // Create notification channels for different priorities
  Future<void> _createNotificationChannels() async {
    // High priority channel with sound
    await _notificationMaster.createCustomChannel(
      channelId: 'high_priority_channel',
      channelName: 'High Priority',
      channelDescription: 'Channel for important notifications',
      importance: NotificationImportance.high,
      enableLights: true,
      lightColor: 0xFFFF0000, // Red color
      enableVibration: true,
      enableSound: true,
    );

    // Default channel with sound
    await _notificationMaster.createCustomChannel(
      channelId: 'default_channel',
      channelName: 'Default Notifications',
      channelDescription: 'Channel for regular notifications',
      importance: NotificationImportance.defaultImportance,
      enableLights: true,
      lightColor: 0xFF00FF00, // Green color
      enableVibration: true,
      enableSound: true,
    );

    // Silent channel
    await _notificationMaster.createCustomChannel(
      channelId: 'silent_channel',
      channelName: 'Silent Notifications',
      channelDescription: 'Channel for silent notifications',
      importance: NotificationImportance.min,
      enableLights: false,
      enableVibration: false,
      enableSound: false,
    );
  }

  // Show a test notification with navigation
  Future<void> _showTestNotification() async {
    await _notificationMaster.showBigTextNotification(
      title: 'Test Notification',
      message: 'This notification will open the main page when tapped',
      bigText:
          'This is a test notification to demonstrate the navigation capability. When you tap this notification, it will open the main page of the app.',
      channelId: 'high_priority_channel',
      targetScreen: '/',
      extraData: {'source': 'test', 'timestamp': DateTime.now().toString()},
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Test notification sent! Try tapping it when it appears.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Toggle background polling
  Future<void> _toggleBackgroundPolling() async {
    if (_isPollingActive) {
      await _stopBackgroundPolling();
    } else {
      await _startBackgroundPolling();
    }
  }

  // Start background polling
  Future<void> _startBackgroundPolling() async {
    // Check permission
    final hasPermission = await _notificationMaster
        .checkNotificationPermission();
    if (!hasPermission) {
      if (!mounted) return;

      // Request permission if not granted
      final granted = await _notificationMaster.requestNotificationPermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission not granted')),
        );
        return;
      }
    }

    // Start polling
    final success = await _notificationMaster.startNotificationPolling(
      pollingUrl: _pollingUrl,
      intervalMinutes: _intervalMinutes,
    );

    if (!mounted) return;

    if (success) {
      _checkServiceStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Background polling started! Note: This may stop when the app is closed.',
          ),
          action: SnackBarAction(
            label: 'Use Foreground Service Instead',
            onPressed: () {
              _stopBackgroundPolling().then((_) => _startForegroundService());
            },
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start notification polling')),
      );
    }
  }

  // Stop background polling
  Future<void> _stopBackgroundPolling() async {
    final success = await _notificationMaster.stopNotificationPolling();

    if (!mounted) return;

    if (success) {
      _checkServiceStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Background polling stopped!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to stop notification polling')),
      );
    }
  }

  // Toggle foreground service
  Future<void> _toggleForegroundService() async {
    if (_isForegroundActive) {
      await _stopForegroundService();
    } else {
      await _startForegroundService();
    }
  }

  // Start foreground service
  Future<void> _startForegroundService() async {
    // Check permission
    final hasPermission = await _notificationMaster
        .checkNotificationPermission();
    if (!hasPermission) {
      if (!mounted) return;

      // Request permission if not granted
      final granted = await _notificationMaster.requestNotificationPermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission not granted')),
        );
        return;
      }
    }

    // Start foreground service with default channel parameters
    final success = await _notificationMaster.startForegroundService(
      pollingUrl: _pollingUrl,
      intervalMinutes: _intervalMinutes,
      channelId: 'high_priority_channel',
      channelName: 'High Priority',
      channelDescription: 'Channel for important notifications',
      importance: NotificationImportance.high,
      enableLights: true,
      lightColor: 0xFFFF0000, // Red color
      enableVibration: true,
      enableSound: true,
    );

    if (!mounted) return;

    if (success) {
      _checkServiceStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Foreground service started! Notifications will continue even when the app is closed.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start foreground service')),
      );
    }
  }

  // Stop foreground service
  Future<void> _stopForegroundService() async {
    final success = await _notificationMaster.stopForegroundService();

    if (!mounted) return;

    if (success) {
      _checkServiceStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foreground service stopped!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to stop foreground service')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple HTTP Notification'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status section
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: _isForegroundActive
                      ? Colors.green.shade100
                      : _isPollingActive
                      ? Colors.blue.shade100
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: _isForegroundActive
                        ? Colors.green.shade300
                        : _isPollingActive
                        ? Colors.blue.shade300
                        : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isForegroundActive
                              ? Icons.notifications_active
                              : _isPollingActive
                              ? Icons.notifications
                              : Icons.notifications_off,
                          color: _isForegroundActive
                              ? Colors.green.shade800
                              : _isPollingActive
                              ? Colors.blue.shade800
                              : Colors.grey.shade800,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isForegroundActive
                              ? 'Foreground Service Active'
                              : _isPollingActive
                              ? 'Background Polling Active'
                              : 'Notification Service Inactive',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isForegroundActive
                                ? Colors.green.shade800
                                : _isPollingActive
                                ? Colors.blue.shade800
                                : Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _isForegroundActive
                            ? Colors.green.shade800
                            : _isPollingActive
                            ? Colors.blue.shade800
                            : Colors.grey.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Background polling button
              ElevatedButton.icon(
                onPressed: _toggleBackgroundPolling,
                icon: Icon(
                  _isPollingActive ? Icons.stop : Icons.play_arrow,
                  color: _isPollingActive ? Colors.red : Colors.white,
                ),
                label: Text(
                  _isPollingActive
                      ? 'Stop Background Polling'
                      : 'Start Background Polling',
                  style: TextStyle(
                    color: _isPollingActive ? Colors.red : Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isPollingActive
                      ? Colors.white
                      : Colors.blue,
                  foregroundColor: _isPollingActive ? Colors.red : Colors.white,
                  side: _isPollingActive
                      ? const BorderSide(color: Colors.red)
                      : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),

              const SizedBox(height: 16),

              // Foreground service button
              ElevatedButton.icon(
                onPressed: _toggleForegroundService,
                icon: Icon(
                  _isForegroundActive ? Icons.stop : Icons.play_arrow,
                  color: _isForegroundActive ? Colors.red : Colors.white,
                ),
                label: Text(
                  _isForegroundActive
                      ? 'Stop Foreground Service'
                      : 'Start Foreground Service',
                  style: TextStyle(
                    color: _isForegroundActive ? Colors.red : Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isForegroundActive
                      ? Colors.white
                      : Colors.green,
                  foregroundColor: _isForegroundActive
                      ? Colors.red
                      : Colors.white,
                  side: _isForegroundActive
                      ? const BorderSide(color: Colors.red)
                      : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),

              const SizedBox(height: 32),

              // Information section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Background polling may stop when the app is closed',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '• Foreground service keeps running even when the app is closed',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '• Foreground service shows a persistent notification',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current server URL: $_pollingUrl',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Text(
                      'Note: Using a mock API for testing. In a real app, you would use your own server.',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                    Text(
                      'Polling interval: $_intervalMinutes minute(s)',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showTestNotification,
                      icon: const Icon(Icons.notifications_active),
                      label: const Text(
                        'Send Test Notification with Navigation',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
