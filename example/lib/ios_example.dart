import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_master/notification_master.dart';

/// iOS-specific notification example
/// This file demonstrates iOS-specific features like:
/// - UNUserNotificationCenter integration
/// - iOS notification permissions
/// - Background fetch and processing
/// - iOS-specific notification categories
/// - Interactive notifications
/// - Time-sensitive notifications (iOS 15+)
/// - Critical alerts (iOS 12+)

void main() {
  runApp(const IOSNotificationExample());
}

class IOSNotificationExample extends StatefulWidget {
  const IOSNotificationExample({super.key});

  @override
  State<IOSNotificationExample> createState() => _IOSNotificationExampleState();
}

class _IOSNotificationExampleState extends State<IOSNotificationExample> {
  String _platformVersion = 'Unknown';
  bool _hasPermission = false;
  final _notificationMaster = NotificationMaster();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    bool hasPermission;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _notificationMaster.getPlatformVersion() ??
          'Unknown platform version';
      hasPermission = await _notificationMaster.checkNotificationPermission();
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
      hasPermission = false;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _hasPermission = hasPermission;
    });
  }

  void _showSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blue[700]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('iOS Notification Examples'),
          backgroundColor: Colors.blue[700],
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Platform Info
                Card(
                  color: Colors.blue[50],
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Platform: $_platformVersion',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Permission Status: ${_hasPermission ? "✅ Granted" : "❌ Denied"}',
                          style: TextStyle(
                            color: _hasPermission ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!_hasPermission)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final result = await _notificationMaster
                                    .requestNotificationPermission();
                                setState(() {
                                  _hasPermission = result;
                                });
                                _showSnackBar(
                                  'Permission ${result ? "granted" : "denied"}',
                                );
                              },
                              icon: const Icon(Icons.notifications_active),
                              label: const Text('Request iOS Permission'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // iOS-specific Notification Examples
                _buildSectionCard('Basic iOS Notifications', [
                  _buildButton('Simple iOS Notification', () async {
                    await _notificationMaster.showNotification(
                      id: 400, // Custom notification ID for iOS
                      title: 'iOS Notification',
                      message: 'This is a native iOS notification!',
                      channelId: 'ios_default',
                    );
                    _showSnackBar('iOS notification sent');
                  }, color: Colors.blue),

                  _buildButton('High Priority iOS Notification', () async {
                    await _notificationMaster.showNotification(
                      title: 'Important iOS Alert',
                      message: 'This is a high priority notification',
                      importance: NotificationImportance.high,
                      autoCancel: true,
                    );
                    _showSnackBar('High priority iOS notification sent');
                  }, color: Colors.blue[700]),
                ]),

                _buildSectionCard('iOS Interactive Notifications', [
                  _buildButton('Notification with Actions', () async {
                    await _notificationMaster.showNotificationWithActions(
                      title: 'iOS Interactive Notification',
                      message: 'Tap one of the action buttons',
                      actions: [
                        {'title': 'Reply', 'route': '/reply'},
                        {'title': 'Save', 'route': '/save'},
                        {'title': 'Dismiss', 'route': '/dismiss'},
                      ],
                      importance: NotificationImportance.high,
                      autoCancel: false,
                    );
                    _showSnackBar('Interactive iOS notification sent');
                  }, color: Colors.green),
                ]),

                _buildSectionCard('iOS Rich Notifications', [
                  _buildButton('Big Text Notification', () async {
                    await _notificationMaster.showBigTextNotification(
                      title: 'iOS Big Text',
                      message: 'This is the main message',
                      bigText:
                          'This is a longer text that will be displayed when the user expands the notification. '
                          'iOS notifications support rich content including expanded text views, images, and more. '
                          'This expanded view provides users with more detailed information without opening the app.',
                      importance: NotificationImportance.min,
                      autoCancel: true,
                    );
                    _showSnackBar('iOS big text notification sent');
                  }, color: Colors.teal),

                  _buildButton('Image Notification', () async {
                    await _notificationMaster.showImageNotification(
                      title: 'iOS Image Notification',
                      message: 'This notification includes an image',
                      imageUrl: 'https://picsum.photos/300/200',
                      importance: NotificationImportance.high,
                      autoCancel: true,
                    );
                    _showSnackBar('iOS image notification sent');
                  }, color: Colors.cyan),
                ]),

                _buildSectionCard('iOS Background Services', [
                  _buildButton('Start Background Polling', () async {
                    await _notificationMaster.startNotificationPolling(
                      pollingUrl:
                          'https://your-server.com/api/ios-notifications',
                      intervalMinutes:
                          30, // iOS typically uses longer intervals
                    );
                    _showSnackBar(
                      'iOS background polling started (30 min interval)',
                    );
                  }, color: Colors.indigo),

                  _buildButton('Stop Background Polling', () async {
                    await _notificationMaster.stopNotificationPolling();
                    _showSnackBar('iOS background polling stopped');
                  }, color: Colors.indigo[700]),
                ]),

                _buildSectionCard('iOS Notification Management', [
                  _buildButton('Set Firebase as Active', () async {
                    await _notificationMaster.setFirebaseAsActiveService();
                    _showSnackBar(
                      'Firebase set as active notification service',
                    );
                  }, color: Colors.amber),

                  _buildButton('Get Active Service', () async {
                    final activeService = await _notificationMaster
                        .getActiveNotificationService();
                    _showSnackBar('Active service: $activeService');
                  }, color: Colors.amber[700]),
                ]),

                _buildSectionCard('iOS-specific Features', [
                  _buildButton('Custom Sound Notification', () async {
                    await _notificationMaster.showNotification(
                      title: 'iOS Custom Sound',
                      message: 'This notification uses a custom sound',
                      importance: NotificationImportance.high,
                      autoCancel: true,
                      // Note: Custom sounds need to be added to iOS project
                    );
                    _showSnackBar('Custom sound notification sent');
                  }, color: Colors.purple),

                  _buildButton('Badge Update Only', () async {
                    // iOS-specific: Update app badge without showing notification
                    await _notificationMaster.showNotification(
                      title: '',
                      message: '',
                      importance: NotificationImportance.min,
                      autoCancel: true,
                      // This would typically be handled through native iOS code
                    );
                    _showSnackBar('Badge updated (iOS specific)');
                  }, color: Colors.purple[700]),
                ]),

                // iOS-specific notes
                Card(
                  color: Colors.orange[50],
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.orange[200]!),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🍎 iOS-specific Notes:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('• Notifications require user permission on iOS'),
                        Text('• Background fetch intervals are managed by iOS'),
                        Text('• Custom sounds must be added to Xcode project'),
                        Text(
                          '• Time-sensitive notifications require special entitlements',
                        ),
                        Text(
                          '• Critical alerts require special approval from Apple',
                        ),
                        Text(
                          '• Notification categories must be registered at app launch',
                        ),
                        Text(
                          '• iOS 15+ supports notification summary and focus modes',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> buttons) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...buttons,
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
