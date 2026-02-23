// ignore_for_file: unused_local_variable

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_master/notification_master.dart';

class WindowsExamplePage extends StatefulWidget {
  const WindowsExamplePage({super.key});

  @override
  State<WindowsExamplePage> createState() => _WindowsExamplePageState();
}

class _WindowsExamplePageState extends State<WindowsExamplePage> {
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
          ? 'Windows notification permission granted!'
          : 'Windows notification permission denied!',
    );
  }

  Future<void> _showWindowsToastNotification() async {
    if (!_hasPermission) {
      _showSnackBar('Notification permission not granted!');
      return;
    }

    final notificationId = await _notificationMaster.showNotification(
      id: 100, // Custom notification ID
      title: 'Windows Toast Notification',
      message: 'This is a native Windows toast notification using WinRT APIs!',
      channelId: 'windows_channel',
    );
    _showSnackBar('Windows toast notification sent!');
  }

  Future<void> _showWindowsActionNotification() async {
    if (!_hasPermission) {
      _showSnackBar('Notification permission not granted!');
      return;
    }

    final notificationId = await _notificationMaster.showNotification(
      title: 'Windows Action Notification',
      message: 'Click to interact with this Windows notification',
      channelId: 'windows_channel',
    );
    _showSnackBar('Windows action notification sent!');
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Windows Notification Example'),
          backgroundColor: Colors.blue,
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
                      Row(
                        children: [
                          Icon(
                            Icons.desktop_windows,
                            size: 24,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Windows Platform Info',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                      const Text('• Native Windows Toast Notifications'),
                      const Text('• WinRT API Integration'),
                      const Text('• Action Center Support'),
                      const Text('• Windows 10+ Compatible'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!_hasPermission)
                ElevatedButton.icon(
                  onPressed: _requestPermission,
                  icon: const Icon(Icons.notifications),
                  label: const Text('Request Windows Notification Permission'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _hasPermission
                    ? _showWindowsToastNotification
                    : null,
                icon: const Icon(Icons.notifications_active),
                label: const Text('Show Windows Toast Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _hasPermission
                    ? _showWindowsActionNotification
                    : null,
                icon: const Icon(Icons.touch_app),
                label: const Text('Show Windows Action Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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
                        'Windows-Specific Features:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('✅ Native Toast Notifications'),
                      Text('✅ Windows Action Center Integration'),
                      Text('✅ WinRT API Support'),
                      Text('✅ Windows 10+ Compatibility'),
                      Text(
                        '⚠️ Limited customization compared to mobile platforms',
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
