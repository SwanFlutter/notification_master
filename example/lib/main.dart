// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_master/notification_master.dart';

import 'http_notification_page.dart';
import 'notification_service_page.dart';
import 'simple_polling_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NotifinationTest(),
    );
  }
}

class NotifinationTest extends StatefulWidget {
  const NotifinationTest({super.key});

  @override
  State<NotifinationTest> createState() => _NotifinationTestState();
}

class _NotifinationTestState extends State<NotifinationTest> {
  String _platformVersion = 'Unknown';
  bool _hasPermission = false;
  final _notificationMaster = NotificationMaster();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  // Helper method to show a snackbar
  void _showSnackBar(String message) {
    if (!mounted) return;
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _checkPermission();
    _createNotificationChannels();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion =
          await _notificationMaster.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  // Check notification permission
  Future<void> _checkPermission() async {
    final hasPermission =
        await _notificationMaster.checkNotificationPermission();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  // Request notification permission
  Future<void> _requestPermission() async {
    final granted = await _notificationMaster.requestNotificationPermission();

    if (!mounted) return;

    setState(() {
      _hasPermission = granted;
    });

    _showSnackBar(
      granted
          ? 'Notification permission granted!'
          : 'Notification permission denied!',
    );
  }

  // Create custom notification channels
  Future<void> _createNotificationChannels() async {
    // Create high priority channel
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

    // Create silent channel
    await _notificationMaster.createCustomChannel(
      channelId: 'silent_channel',
      channelName: 'Silent Notifications',
      channelDescription: 'Channel for silent notifications',
      importance: NotificationImportance.silent,
      enableLights: false,
      enableVibration: false,
      enableSound: false,
    );

    // Create media channel
    await _notificationMaster.createCustomChannel(
      channelId: 'media_channel',
      channelName: 'Media',
      channelDescription: 'Channel for media notifications',
      importance: NotificationImportance.defaultImportance,
      enableLights: true,
      lightColor: 0xFF00FF00, // Green color
      enableVibration: false,
      enableSound: true,
    );
  }

  // Show a simple notification
  Future<void> _showSimpleNotification() async {
    if (!_hasPermission) {
      _showSnackBar('Notification permission not granted!');
      return;
    }

    final notificationId = await _notificationMaster.showNotification(
      title: 'Simple Notification',
      message: 'This is a simple notification from the example app',
    );

    if (!mounted) return;

    _showSnackBar('Simple notification sent! ID: $notificationId');
  }

  // Show a high priority notification
  Future<void> _showHighPriorityNotification() async {
    if (!_hasPermission) {
      _showSnackBar('Notification permission not granted!');
      return;
    }

    final notificationId = await _notificationMaster.showNotification(
      title: 'High Priority Notification',
      message: 'This is a high priority notification',
      channelId: 'high_priority_channel',
      priority: 1, // High priority
    );

    if (!mounted) return;

    _showSnackBar('High priority notification sent! ID: $notificationId');
  }

  // Show a big text notification
  Future<void> _showBigTextNotification() async {
    if (!_hasPermission) {
      _showSnackBar('Notification permission not granted!');
      return;
    }

    final notificationId = await _notificationMaster.showBigTextNotification(
      title: 'Big Text Notification',
      message: 'This notification has expanded text',
      bigText:
          'This is the expanded text content that will be shown when the notification is expanded. '
          'It can contain much more text than the regular notification message and can span multiple lines. '
          'This is useful for showing longer messages, emails, or other content that requires more space.',
    );

    if (!mounted) return;

    _showSnackBar('Big text notification sent! ID: $notificationId');
  }

  // Show an image notification
  Future<void> _showImageNotification() async {
    if (!_hasPermission) {
      _showSnackBar('Notification permission not granted!');
      return;
    }

    final notificationId = await _notificationMaster.showImageNotification(
      title: 'Image Notification',
      message: 'This notification includes an image',
      imageUrl: 'https://picsum.photos/id/237/200/300',
      channelId: 'media_channel',
    );

    if (!mounted) return;

    _showSnackBar('Image notification sent! ID: $notificationId');
  }

  // Show a notification with actions
  Future<void> _showNotificationWithActions() async {
    if (!_hasPermission) {
      _showSnackBar('Notification permission not granted!');
      return;
    }

    final notificationId = await _notificationMaster
        .showNotificationWithActions(
          title: 'Action Notification',
          message: 'This notification has custom actions',
          actions: [
            {'title': 'Open Settings', 'route': '/settings'},
            {'title': 'View Profile', 'route': '/profile'},
          ],
        );

    if (!mounted) return;

    _showSnackBar('Notification with actions sent! ID: $notificationId');
  }

  // Show a silent notification
  Future<void> _showSilentNotification() async {
    if (!_hasPermission) {
      _showSnackBar('Notification permission not granted!');
      return;
    }

    final notificationId = await _notificationMaster.showNotification(
      title: 'Silent Notification',
      message: 'This notification will not make sound or vibration',
      channelId: 'silent_channel',
    );

    if (!mounted) return;

    _showSnackBar('Silent notification sent! ID: $notificationId');
  }

  // Start notification polling
  Future<void> _startNotificationPolling() async {
    if (!_hasPermission) {
      _showSnackBar('Notification permission not granted!');
      return;
    }

    // Use the local PHP server for testing
    const pollingUrl = 'http://10.0.2.2:3000/';

    final success = await _notificationMaster.startNotificationPolling(
      pollingUrl: pollingUrl,
      intervalMinutes: 15, // Check every 15 minutes
    );

    if (!mounted) return;

    _showSnackBar(
      success
          ? 'Notification polling started!'
          : 'Failed to start notification polling!',
    );
  }

  // Stop notification polling
  Future<void> _stopNotificationPolling() async {
    final success = await _notificationMaster.stopNotificationPolling();

    if (!mounted) return;

    _showSnackBar(
      success
          ? 'Notification polling stopped!'
          : 'Failed to stop notification polling!',
    );
  }

  // Show a random notification (for demo purposes)
  Future<void> _showRandomNotification() async {
    if (!_hasPermission) {
      _showSnackBar('Notification permission not granted!');
      return;
    }

    final random = Random();
    final type = random.nextInt(5);

    switch (type) {
      case 0:
        await _showSimpleNotification();
        break;
      case 1:
        await _showHighPriorityNotification();
        break;
      case 2:
        await _showBigTextNotification();
        break;
      case 3:
        await _showImageNotification();
        break;
      case 4:
        await _showNotificationWithActions();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: const Text('Notification Master Example')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Running on: $_platformVersion',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Notification permission: ${_hasPermission ? 'Granted' : 'Not granted'}',
              style: TextStyle(
                fontSize: 16,
                color: _hasPermission ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),

            // Permission section
            const Text(
              'Permission',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _requestPermission,
              child: const Text('Request Notification Permission'),
            ),
            const SizedBox(height: 16),

            // Basic notifications section
            const Text(
              'Basic Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showSimpleNotification,
              child: const Text('Show Simple Notification'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showHighPriorityNotification,
              child: const Text('Show High Priority Notification'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showSilentNotification,
              child: const Text('Show Silent Notification'),
            ),
            const SizedBox(height: 16),

            // Advanced notifications section
            const Text(
              'Advanced Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showBigTextNotification,
              child: const Text('Show Big Text Notification'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showImageNotification,
              child: const Text('Show Image Notification'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showNotificationWithActions,
              child: const Text('Show Notification With Actions'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showRandomNotification,
              child: const Text('Show Random Notification'),
            ),
            const SizedBox(height: 16),

            // HTTP polling section
            const Text(
              'HTTP Notification Polling',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startNotificationPolling,
                    child: const Text('Start Polling'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _stopNotificationPolling,
                    child: const Text('Stop Polling'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Navigation section
            const Text(
              'Navigation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SimplePollingPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simple HTTP Notification (Recommended)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HttpNotificationPage(),
                  ),
                );
              },
              child: const Text('Advanced HTTP Notification Page'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationServicePage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Notification Service Manager'),
            ),
          ],
        ),
      ),
    );
  }
}
