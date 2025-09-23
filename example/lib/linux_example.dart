// ignore_for_file: unused_local_variable

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_master/notification_master.dart';

class LinuxExamplePage extends StatefulWidget {
  const LinuxExamplePage({super.key});

  @override
  State<LinuxExamplePage> createState() => _LinuxExamplePageState();
}

class _LinuxExamplePageState extends State<LinuxExamplePage> {
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
          ? 'Linux notification permission granted!'
          : 'Linux notification permission denied!',
    );
  }

  Future<void> _showLinuxNotification() async {
    if (!_hasPermission) {
      _showSnackBar('Notification permission not granted!');
      return;
    }

    final notificationId = await _notificationMaster.showNotification(
      id: 500, // Custom notification ID for Linux
      title: 'Linux Notification',
      message: 'This is a native Linux notification using libnotify!',
      channelId: 'linux_default',
    );
    _showSnackBar('Linux desktop notification sent!');
  }

  Future<void> _showLinuxUrgentNotification() async {
    if (!_hasPermission) {
      _showSnackBar('Notification permission not granted!');
      return;
    }

    final notificationId = await _notificationMaster.showNotification(
      title: '🚨 Urgent Linux Notification',
      message: 'This is an urgent notification that stays visible longer',
      channelId: 'linux_urgent_channel',
    );
    _showSnackBar('Linux urgent notification sent!');
  }

  Future<void> _showLinuxInfoNotification() async {
    if (!_hasPermission) {
      _showSnackBar('Notification permission not granted!');
      return;
    }

    final notificationId = await _notificationMaster.showNotification(
      title: 'ℹ️ Linux Info',
      message: 'Information notification with 5-second timeout',
      channelId: 'linux_info_channel',
    );
    _showSnackBar('Linux info notification sent!');
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Linux Notification Example'),
          backgroundColor: Colors.orange,
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
                        '🐧 Linux Platform Info',
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
                      const Text('• libnotify Integration'),
                      const Text('• GTK Desktop Environment Support'),
                      const Text('• System Notification Area'),
                      const Text('• Configurable Timeout'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!_hasPermission)
                ElevatedButton.icon(
                  onPressed: _requestPermission,
                  icon: const Icon(Icons.notifications),
                  label: const Text('Request Linux Notification Permission'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _hasPermission ? _showLinuxNotification : null,
                icon: const Icon(Icons.notifications_active),
                label: const Text('Show Linux Desktop Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _hasPermission ? _showLinuxUrgentNotification : null,
                icon: const Icon(Icons.priority_high),
                label: const Text('Show Urgent Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _hasPermission ? _showLinuxInfoNotification : null,
                icon: const Icon(Icons.info),
                label: const Text('Show Info Notification'),
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
                        'Linux-Specific Features:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('✅ libnotify Integration'),
                      Text('✅ GTK Desktop Environment Support'),
                      Text('✅ System Notification Area'),
                      Text('✅ Configurable Timeout (5 seconds)'),
                      Text('✅ Desktop Environment Compatibility'),
                      Text('⚠️ Requires libnotify-dev package'),
                      Text('⚠️ Limited styling options'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Card(
                color: Colors.amber,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📋 Installation Requirements:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('sudo apt-get install libnotify-dev'),
                      Text('sudo apt-get install libgtk-3-dev'),
                      Text('sudo apt-get install pkg-config'),
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
