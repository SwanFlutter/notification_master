// ignore_for_file: unused_local_variable

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_master/notification_master.dart';

class WebExamplePage extends StatefulWidget {
  const WebExamplePage({super.key});

  @override
  State<WebExamplePage> createState() => _WebExamplePageState();
}

class _WebExamplePageState extends State<WebExamplePage> {
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
          ? 'Web notification permission granted!'
          : 'Web notification permission denied!',
    );
  }

  Future<void> _showWebNotification() async {
    if (!_hasPermission) {
      _showSnackBar('Notification permission not granted!');
      return;
    }

    final notificationId = await _notificationMaster.showNotification(
      id: 600, // Custom notification ID for Web
      title: 'Web Browser Notification',
      message:
          'This is a native web notification using HTML5 Notification API!',
      channelId: 'web_default',
    );
    _showSnackBar('Web browser notification sent!');
  }

  Future<void> _showWebPersistentNotification() async {
    if (!_hasPermission) {
      _showSnackBar('Notification permission not granted!');
      return;
    }

    final notificationId = await _notificationMaster.showNotification(
      title: '📌 Persistent Web Notification',
      message: 'This notification stays visible until user interacts with it',
    );
    _showSnackBar('Web persistent notification sent!');
  }

  Future<void> _showWebClickableNotification() async {
    if (!_hasPermission) {
      _showSnackBar('Notification permission not granted!');
      return;
    }

    final notificationId = await _notificationMaster.showNotification(
      title: '🖱️ Clickable Web Notification',
      message: 'Click this notification to interact with it!',
    );
    _showSnackBar('Web clickable notification sent!');
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Web Notification Example'),
          backgroundColor: Colors.purple,
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
                        '🌐 Web Platform Info',
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
                      const Text('• HTML5 Notification API'),
                      const Text('• Browser Native Notifications'),
                      const Text('• Cross-Browser Compatibility'),
                      const Text('• User Permission Management'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!_hasPermission)
                ElevatedButton.icon(
                  onPressed: _requestPermission,
                  icon: const Icon(Icons.notifications),
                  label: const Text('Request Web Notification Permission'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _hasPermission ? _showWebNotification : null,
                icon: const Icon(Icons.notifications_active),
                label: const Text('Show Web Browser Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _hasPermission
                    ? _showWebPersistentNotification
                    : null,
                icon: const Icon(Icons.push_pin),
                label: const Text('Show Persistent Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _hasPermission
                    ? _showWebClickableNotification
                    : null,
                icon: const Icon(Icons.touch_app),
                label: const Text('Show Clickable Notification'),
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
                        'Web-Specific Features:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('✅ HTML5 Notification API Integration'),
                      Text('✅ Browser Native Notifications'),
                      Text('✅ Cross-Browser Compatibility'),
                      Text('✅ User Permission Management'),
                      Text('✅ Click Event Handling'),
                      Text('✅ Auto-dismiss Functionality'),
                      Text('⚠️ Requires HTTPS in production'),
                      Text('⚠️ Limited customization options'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.amber[50],
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🌐 Browser Compatibility:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('✅ Chrome 22+'),
                      Text('✅ Firefox 22+'),
                      Text('✅ Safari 7+'),
                      Text('✅ Edge 14+'),
                      Text('✅ Opera 25+'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.red[50],
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ Important Notes:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('• HTTPS required for production'),
                      Text('• User must grant permission explicitly'),
                      Text(
                        '• Notifications may be blocked by browser settings',
                      ),
                      Text('• Limited styling and customization options'),
                      Text('• Behavior varies between browsers'),
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
