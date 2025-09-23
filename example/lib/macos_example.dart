import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_master/notification_master.dart';

class MacOSExamplePage extends StatefulWidget {
  const MacOSExamplePage({super.key});

  @override
  State<MacOSExamplePage> createState() => _MacOSExamplePageState();
}

class _MacOSExamplePageState extends State<MacOSExamplePage> {
  String _platformVersion = 'Unknown';
  bool _hasPermission = false;
  final _notificationMaster = NotificationMaster();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

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
    _createMacOSChannels();
  }

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

  Future<void> _checkPermission() async {
    final hasPermission = await _notificationMaster
        .checkNotificationPermission();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  Future<void> _requestPermission() async {
    final granted = await _notificationMaster.requestNotificationPermission();
    if (!mounted) return;
    setState(() {
      _hasPermission = granted;
    });
    _showSnackBar(
      granted
          ? 'macOS notification permission granted!'
          : 'macOS notification permission denied!',
    );
  }

  Future<void> _createMacOSChannels() async {
    await _notificationMaster.createCustomChannel(
      channelId: 'macos_default',
      channelName: 'macOS Default',
      channelDescription: 'Default macOS notifications',
      importance: NotificationImportance.defaultImportance,
      enableSound: true,
    );

    await _notificationMaster.createCustomChannel(
      channelId: 'macos_critical',
      channelName: 'macOS Critical',
      channelDescription: 'Critical macOS notifications',
      importance: NotificationImportance.high,
      enableSound: true,
    );
  }

  Future<void> _showMacOSNotification() async {
    if (!_hasPermission) {
      _showSnackBar('Notification permission not granted!');
      return;
    }

    final notificationId = await _notificationMaster.showNotification(
      id: 200, // Custom notification ID for macOS
      title: 'macOS Notification',
      message:
          'This is a native macOS notification using UNUserNotificationCenter!',
      channelId: 'macos_standard',
    );
    _showSnackBar('macOS notification sent!');
  }

  Future<void> _showMacOSCriticalNotification() async {
    if (!_hasPermission) {
      _showSnackBar('Notification permission not granted!');
      return;
    }

    final notificationId = await _notificationMaster.showNotification(
      title: '🚨 Critical macOS Alert',
      message: 'This is a critical notification that bypasses Do Not Disturb',
      channelId: 'macos_critical',
    );
    _showSnackBar('macOS critical notification sent!');
  }

  Future<void> _showMacOSBannerNotification() async {
    if (!_hasPermission) {
      _showSnackBar('Notification permission not granted!');
      return;
    }

    final notificationId = await _notificationMaster.showNotification(
      title: '📢 macOS Banner',
      message: 'This notification appears as a banner in the top-right corner',
      channelId: 'macos_banner',
    );
    _showSnackBar('macOS banner notification sent!');
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('macOS Notification Example'),
          backgroundColor: Colors.grey[800],
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🍎 macOS Platform Info',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Platform Version: $_platformVersion'),
                      Text(
                        'Permission Status: ${_hasPermission ? "✅ Granted" : "❌ Not Granted"}',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Features:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text('• UNUserNotificationCenter Integration'),
                      const Text('• Notification Center Support'),
                      const Text('• Banner & Alert Styles'),
                      const Text('• Do Not Disturb Compatibility'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!_hasPermission)
                ElevatedButton.icon(
                  onPressed: _requestPermission,
                  icon: const Icon(Icons.notifications),
                  label: const Text('Request macOS Notification Permission'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _hasPermission ? _showMacOSNotification : null,
                icon: const Icon(Icons.notifications_active),
                label: const Text('Show macOS Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _hasPermission
                    ? _showMacOSCriticalNotification
                    : null,
                icon: const Icon(Icons.priority_high),
                label: const Text('Show Critical Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _hasPermission ? _showMacOSBannerNotification : null,
                icon: const Icon(Icons.campaign),
                label: const Text('Show Banner Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'macOS-Specific Features:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('✅ UNUserNotificationCenter Integration'),
                      Text('✅ Notification Center Support'),
                      Text('✅ Banner & Alert Presentation Styles'),
                      Text('✅ Do Not Disturb Mode Compatibility'),
                      Text('✅ Critical Notifications (bypass DND)'),
                      Text('✅ Sound & Badge Support'),
                      Text('✅ macOS 10.14+ Compatible'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.blue[50],
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 macOS Tips:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('• Notifications appear in the top-right corner'),
                      Text(
                        '• Users can configure notification styles in System Preferences',
                      ),
                      Text(
                        '• Critical notifications can bypass Do Not Disturb mode',
                      ),
                      Text(
                        '• Notifications are automatically managed by the system',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
