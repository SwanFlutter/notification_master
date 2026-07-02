import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_master/notification_master.dart';

/// Android-specific notification example
/// This file demonstrates Android-specific features like:
/// - Custom notification channels
/// - Foreground services
/// - Custom actions
/// - Notification importance levels
/// - Android 8.0+ channel management
/// - WorkManager integration

class AndroidNotificationExample extends StatefulWidget {
  const AndroidNotificationExample({super.key});

  @override
  State<AndroidNotificationExample> createState() =>
      _AndroidNotificationExampleState();
}

class _AndroidNotificationExampleState
    extends State<AndroidNotificationExample> {
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
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Android Notification Examples'),
          backgroundColor: Colors.green[700],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Platform Info
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Platform: $_platformVersion',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Permission Status: ${_hasPermission ? "✅ Granted" : "❌ Denied"}',
                        ),
                        const SizedBox(height: 8),
                        if (!_hasPermission)
                          ElevatedButton(
                            onPressed: () async {
                              final result = await _notificationMaster
                                  .requestNotificationPermission();
                              setState(() {
                                _hasPermission = result;
                              });
                              if (result) {
                                _showSnackBar('Permission granted');
                              } else {
                                _showSnackBar(
                                  'Permission denied. If permanently denied, please enable it in App Settings.',
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Request Permission'),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Android-specific Notification Examples
                _buildSectionCard('Basic Android Notifications', [
                  _buildButton(
                    'Heads-Up Notification (از بالا میاد)',
                    () async {
                      debugPrint('📱 Sending heads-up notification...');
                      await _notificationMaster.showNotification(
                        id: 300,
                        title: '🔔 Heads-Up Notification',
                        message:
                            'این نوتیفیکیشن از بالای صفحه نمایش داده میشه و padding داره',
                        importance: NotificationImportance.high,
                        autoCancel: true,
                      );
                      _showSnackBar(
                        'Heads-up notification sent (check top of screen)',
                      );
                    },
                    color: Colors.deepPurple,
                  ),

                  _buildButton('Simple Notification (High Priority)', () async {
                    debugPrint('📱 Sending high priority notification...');
                    await _notificationMaster.showNotification(
                      id: 301,
                      title: 'Android High Priority',
                      message:
                          'This is a high priority notification for Android',
                      importance: NotificationImportance.high,
                      autoCancel: true,
                    );
                    _showSnackBar('High priority notification sent');
                  }, color: Colors.blue),

                  _buildButton('Low Priority Notification', () async {
                    debugPrint('📱 Sending low priority notification...');
                    await _notificationMaster.showNotification(
                      title: 'Android Low Priority',
                      message: 'This is a low priority notification',
                      importance: NotificationImportance.low,
                      autoCancel: true,
                    );
                    _showSnackBar('Low priority notification sent');
                  }, color: Colors.grey),
                ]),

                _buildSectionCard('Android Notification Channels', [
                  _buildButton('Create Custom Channel', () async {
                    // print('🔧 Creating custom channel...');
                    try {
                      // Using a new channel ID to ensure fresh creation with sound enabled
                      // Android notification channels are immutable once created.
                      // If you want to change settings like sound/importance, you must use a new ID
                      // or reinstall the app.
                      const channelId = 'custom_channel_high_importance_v2';

                      await _notificationMaster.createCustomChannel(
                        channelId: channelId,
                        channelName: 'High Priority Channel',
                        channelDescription:
                            'This is a high priority channel with sound enabled',
                        importance: NotificationImportance.high,
                        enableSound: true,
                        enableVibration: true,
                        enableLights: true,
                      );
                      // print('✅ Custom channel created successfully');

                      // Wait a bit to ensure channel is fully registered
                      await Future.delayed(Duration(milliseconds: 500));

                      _showSnackBar('Custom channel created successfully');

                      // Show a styled notification to confirm channel creation
                      await _notificationMaster.showStyledNotification(
                        title: 'کانال ساخته شد ✅',
                        message: 'کانال سفارشی با موفقیت ساخته شد و صدا دارد',
                        channelId: channelId,
                      );
                      // print('✅ Confirmation notification sent');
                    } catch (e) {
                      debugPrint('❌ Error creating custom channel: $e');
                      _showSnackBar('Error: $e');
                    }
                  }, color: Colors.purple),

                  _buildButton('Notification with Custom Channel', () async {
                    // debugPrint('📱 Sending notification with custom channel...');
                    try {
                      // Must match the ID used in creation above
                      const channelId = 'custom_channel_high_importance_v2';

                      await _notificationMaster.showStyledNotification(
                        title: 'نوتیفیکیشن کانال سفارشی',
                        message:
                            'این نوتیفیکیشن از کانال سفارشی استفاده می‌کند و باید صدا داشته باشد',
                        channelId: channelId,
                      );
                      // debugPrint('✅ Notification sent successfully');
                      _showSnackBar('Notification with custom channel sent');
                    } catch (e) {
                      debugPrint('❌ Error sending notification: $e');
                      _showSnackBar('Error: $e');
                    }
                  }, color: Colors.purple[700]),

                  _buildButton('Styled Notification (مثل تصویر)', () async {
                    // debugPrint('📱 Sending styled notification...');
                    try {
                      await _notificationMaster.showStyledNotification(
                        title: 'ویرایش عصرگاهی ؟ • now 🔔',
                        message:
                            'این نوتیفیکیشن با آیکون اپلیکیشن و متن کامل نمایش داده میشه',
                      );
                      // debugPrint('✅ Styled notification sent');
                      _showSnackBar(
                        'Styled notification sent (check notification bar)',
                      );
                    } catch (e) {
                      debugPrint('❌ Error sending styled notification: $e');
                      _showSnackBar('Error: $e');
                    }
                  }, color: Colors.deepPurple),
                ]),

                _buildSectionCard('Android Action Notifications', [
                  _buildButton('Notification with Actions', () async {
                    await _notificationMaster.showNotificationWithActions(
                      title: 'Action Notification',
                      message: 'This notification has custom actions',
                      actions: [
                        {'title': 'Reply', 'route': 'reply'},
                        {'title': 'Archive', 'route': 'archive'},
                        {'title': 'Delete', 'route': 'delete'},
                      ],
                      importance: NotificationImportance.high,
                      autoCancel: false,
                    );
                    _showSnackBar('Action notification sent');
                  }, color: Colors.orange),
                ]),

                _buildSectionCard('Android Rich Notifications', [
                  _buildButton('Heads-Up Notification (Custom UI)', () async {
                    debugPrint(
                      '📱 Sending heads-up notification with custom UI...',
                    );
                    await _notificationMaster.showHeadsUpNotification(
                      title: '🎨 Custom Heads-Up',
                      message: 'این نوتیفیکیشن از بالا میاد و UI سفارشی داره',
                    );
                    _showSnackBar('Heads-up notification with custom UI sent');
                  }, color: Colors.deepOrange),

                  _buildButton('Full Screen Notification', () async {
                    debugPrint('📱 Sending full screen notification...');
                    await _notificationMaster.showFullScreenNotification(
                      title: '📞 Full Screen Alert',
                      message: 'این نوتیفیکیشن تمام صفحه رو میگیره (مثل تماس)',
                    );
                    _showSnackBar('Full screen notification sent');
                  }, color: Colors.red),

                  _buildButton('Big Text Notification', () async {
                    debugPrint('📱 Sending big text notification...');
                    await _notificationMaster.showBigTextNotification(
                      title: 'Android Big Text',
                      message: 'This is the main message',
                      bigText:
                          'This is a very long text that will be displayed in the expanded notification view. '
                          'Android allows for much longer text content in notifications when expanded. '
                          'This is perfect for displaying detailed information, news articles, or long messages '
                          'that need more space than a standard notification allows.',
                      importance: NotificationImportance.high,
                      autoCancel: true,
                    );
                    _showSnackBar('Big text notification sent');
                  }, color: Colors.teal),

                  _buildButton('Image Notification', () async {
                    debugPrint('📱 Sending image notification...');
                    await _notificationMaster.showImageNotification(
                      title: 'Android Image Notification',
                      message: 'This notification includes an image',
                      imageUrl: 'https://picsum.photos/200/300',
                      importance: NotificationImportance.high,
                      autoCancel: true,
                    );
                    _showSnackBar('Image notification sent');
                  }, color: Colors.cyan),
                ]),

                _buildSectionCard('Android Foreground Service', [
                  _buildButton('Start Foreground Service', () async {
                    await _notificationMaster.startForegroundService(
                      pollingUrl: 'https://your-server.com/api/notifications',
                      intervalMinutes: 15,
                      channelId: 'foreground_service_channel',
                    );
                    _showSnackBar('Foreground service started');
                  }, color: Colors.red),

                  _buildButton('Stop Foreground Service', () async {
                    await _notificationMaster.stopForegroundService();
                    _showSnackBar('Foreground service stopped');
                  }, color: Colors.red[700]),
                ]),

                _buildSectionCard('Android Background Polling', [
                  _buildButton('Start Polling Service', () async {
                    await _notificationMaster.startNotificationPolling(
                      pollingUrl: 'https://your-server.com/api/notifications',
                      intervalMinutes: 15,
                    );
                    _showSnackBar('Polling service started (15 min interval)');
                  }, color: Colors.indigo),

                  _buildButton('Stop Polling Service', () async {
                    await _notificationMaster.stopNotificationPolling();
                    _showSnackBar('Polling service stopped');
                  }, color: Colors.indigo[700]),
                ]),

                _buildSectionCard('Notification Service Management', [
                  _buildButton('Set Firebase as Active', () async {
                    await _notificationMaster.setFirebaseAsActiveService();
                    _showSnackBar('Firebase set as active service');
                  }, color: Colors.amber),

                  _buildButton('Get Active Service', () async {
                    final activeService = await _notificationMaster
                        .getActiveNotificationService();
                    _showSnackBar('Active service: $activeService');
                  }, color: Colors.amber[700]),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> buttons) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
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
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(text, style: const TextStyle(fontSize: 14)),
        ),
      ),
    );
  }
}
