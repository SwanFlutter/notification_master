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
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
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
          ? '✅ Windows notification permission granted!'
          : '❌ Windows notification permission denied!',
    );
  }

  // 1. Simple Toast Notification
  Future<void> _showSimpleToast() async {
    if (!_hasPermission) {
      _showSnackBar('❌ Notification permission not granted!');
      return;
    }

    try {
      final notificationId = await _notificationMaster.showNotification(
        id: 100,
        title: '🔔 Simple Windows Toast',
        message: 'This is a basic Windows toast notification using WinRT APIs!',
        channelId: 'windows_channel',
      );
      _showSnackBar('✅ Simple toast sent! ID: $notificationId');
    } catch (e) {
      _showSnackBar('❌ Error: $e');
    }
  }

  // 2. Big Text Notification
  Future<void> _showBigText() async {
    if (!_hasPermission) {
      _showSnackBar('❌ Notification permission not granted!');
      return;
    }

    try {
      final notificationId = await _notificationMaster.showBigTextNotification(
        title: '📄 Long Message',
        message: 'Short summary',
        bigText:
            'This is a very long notification message that will be expanded when the user clicks on it. '
            'It can contain multiple lines and paragraphs of text to provide detailed information to the user. '
            'Perfect for news updates, messages, or any content that requires more than a simple line!',
      );
      _showSnackBar('✅ Big text notification sent! ID: $notificationId');
    } catch (e) {
      _showSnackBar('❌ Error: $e');
    }
  }

  // 3. Image Notification
  Future<void> _showImageNotification() async {
    if (!_hasPermission) {
      _showSnackBar('❌ Notification permission not granted!');
      return;
    }

    try {
      final notificationId = await _notificationMaster.showImageNotification(
        title: '🖼️ Image Notification',
        message: 'Check out this beautiful image!',
        imageUrl: 'https://picsum.photos/400/200',
      );
      _showSnackBar('✅ Image notification sent! ID: $notificationId');
    } catch (e) {
      _showSnackBar('❌ Error: $e');
    }
  }

  // 4. Notification with Actions (Buttons)
  Future<void> _showWithActions() async {
    if (!_hasPermission) {
      _showSnackBar('❌ Notification permission not granted!');
      return;
    }

    try {
      final notificationId = await _notificationMaster
          .showNotificationWithActions(
            title: '🎯 Action Notification',
            message: 'Click a button below to respond',
            actions: [
              {'title': 'Accept', 'route': '/action/accept'},
              {'title': 'Decline', 'route': '/action/decline'},
            ],
          );
      _showSnackBar('✅ Action notification sent! ID: $notificationId');
    } catch (e) {
      _showSnackBar('❌ Error: $e');
    }
  }

  // 5. Styled Notification (Windows specific - with attribution)
  Future<void> _showStyledNotification() async {
    if (!_hasPermission) {
      _showSnackBar('❌ Notification permission not granted!');
      return;
    }

    try {
      final notificationId = await _notificationMaster.showStyledNotification(
        title: '⭐ Styled Notification',
        message:
            'This notification has a styled appearance with attribution text at the bottom',
        channelId: 'styled_channel',
      );
      _showSnackBar('✅ Styled notification sent! ID: $notificationId');
    } catch (e) {
      _showSnackBar('❌ Error: $e');
    }
  }

  // 6. Heads-Up Notification (Alarm Scenario - stays visible longer)
  Future<void> _showHeadsUpNotification() async {
    if (!_hasPermission) {
      _showSnackBar('❌ Notification permission not granted!');
      return;
    }

    try {
      final notificationId = await _notificationMaster.showHeadsUpNotification(
        title: '⏰ Heads-Up Alert!',
        message: 'This notification stays visible longer with an alarm sound!',
      );
      _showSnackBar('✅ Heads-up notification sent! ID: $notificationId');
    } catch (e) {
      _showSnackBar('❌ Error: $e');
    }
  }

  // 7. Full Screen Notification (Incoming Call Scenario)
  Future<void> _showFullScreenNotification() async {
    if (!_hasPermission) {
      _showSnackBar('❌ Notification permission not granted!');
      return;
    }

    try {
      final notificationId = await _notificationMaster
          .showFullScreenNotification(
            title: '📞 Incoming Call',
            message: 'John Doe is calling you...',
          );
      _showSnackBar('✅ Full screen notification sent! ID: $notificationId');
    } catch (e) {
      _showSnackBar('❌ Error: $e');
    }
  }

  Widget _buildFeatureCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Windows Notification Master'),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue[700]!, Colors.blue[50]!],
              stops: const [0.0, 0.3],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Platform Info Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.desktop_windows,
                                size: 32,
                                color: Colors.blue[700],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Windows Platform',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Version: $_platformVersion',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _hasPermission
                                ? Colors.green[50]
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _hasPermission
                                  ? Colors.green[200]!
                                  : Colors.orange[200]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _hasPermission
                                    ? Icons.check_circle
                                    : Icons.warning,
                                color: _hasPermission
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _hasPermission
                                      ? 'Notification permission granted'
                                      : 'Notification permission required',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: _hasPermission
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_hasPermission) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _requestPermission,
                            icon: const Icon(Icons.notifications_active),
                            label: const Text('Request Permission'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Section Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text(
                    '🔔 Notification Types',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Notification Feature Cards
                _buildFeatureCard(
                  '1. Simple Toast',
                  'Basic Windows toast notification',
                  Icons.notifications,
                  Colors.blue,
                  _hasPermission ? _showSimpleToast : null,
                ),
                const SizedBox(height: 8),

                _buildFeatureCard(
                  '2. Big Text',
                  'Expandable long text notification',
                  Icons.notes,
                  Colors.green,
                  _hasPermission ? _showBigText : null,
                ),
                const SizedBox(height: 8),

                _buildFeatureCard(
                  '3. With Image',
                  'Notification with an image',
                  Icons.image,
                  Colors.purple,
                  _hasPermission ? _showImageNotification : null,
                ),
                const SizedBox(height: 8),

                _buildFeatureCard(
                  '4. Action Buttons',
                  'Notification with clickable buttons',
                  Icons.touch_app,
                  Colors.orange,
                  _hasPermission ? _showWithActions : null,
                ),
                const SizedBox(height: 8),

                _buildFeatureCard(
                  '5. Styled',
                  'Windows styled with attribution text',
                  Icons.style,
                  Colors.indigo,
                  _hasPermission ? _showStyledNotification : null,
                ),
                const SizedBox(height: 8),

                _buildFeatureCard(
                  '6. Heads-Up (Alarm)',
                  'Stays visible longer with alarm sound',
                  Icons.alarm,
                  Colors.red,
                  _hasPermission ? _showHeadsUpNotification : null,
                ),
                const SizedBox(height: 8),

                _buildFeatureCard(
                  '7. Full Screen (Call)',
                  'Incoming call style notification',
                  Icons.call,
                  Colors.teal,
                  _hasPermission ? _showFullScreenNotification : null,
                ),

                const SizedBox(height: 20),

                // Features Summary Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✨ Windows-Specific Features:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                          '✅ Native Toast Notifications (WinRT)',
                        ),
                        _buildFeatureItem(
                          '✅ Windows Action Center Integration',
                        ),
                        _buildFeatureItem('✅ Multiple notification scenarios'),
                        _buildFeatureItem(
                          '✅ Custom audio (Alarm, Call, SMS, etc.)',
                        ),
                        _buildFeatureItem('✅ Image support with download'),
                        _buildFeatureItem('✅ Action buttons'),
                        _buildFeatureItem('✅ Attribution text'),
                        _buildFeatureItem('✅ Windows 10+ Compatibility'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
