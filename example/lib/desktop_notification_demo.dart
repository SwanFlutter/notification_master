import 'package:flutter/material.dart';
import 'package:notification_master/notification_master.dart';

/// Desktop Notification Demo Page
/// Demonstrates how to use local_notifier for desktop notifications
class DesktopNotificationDemo extends StatefulWidget {
  const DesktopNotificationDemo({super.key});

  @override
  State<DesktopNotificationDemo> createState() =>
      _DesktopNotificationDemoState();
}

class _DesktopNotificationDemoState extends State<DesktopNotificationDemo> {
  bool _isInitialized = false;
  String _lastAction = 'No action yet';

  @override
  void initState() {
    super.initState();
    _initializeDesktopNotifications();
  }

  Future<void> _initializeDesktopNotifications() async {
    if (!NotificationMasterDesktop.isSupported()) {
      setState(() {
        _lastAction = 'Desktop notifications not supported on this platform';
      });
      return;
    }

    await NotificationMasterDesktop.initialize(
      appName: 'notification_master_example',
    );

    setState(() {
      _isInitialized = NotificationMasterDesktop.isInitialized();
      _lastAction = _isInitialized
          ? 'Desktop notifications initialized successfully'
          : 'Failed to initialize desktop notifications';
    });
  }

  Future<void> _showSimpleNotification() async {
    await NotificationMasterDesktop.showNotification(
      title: 'نوتیفیکیشن ساده',
      body: 'این یک نوتیفیکیشن تستی برای دسکتاپ است',
      onShow: () {
        setState(() {
          _lastAction = 'Notification shown';
        });
      },
      onClick: () {
        setState(() {
          _lastAction = 'Notification clicked';
        });
      },
      onClose: (reason) {
        setState(() {
          _lastAction = 'Notification closed: $reason';
        });
      },
    );
  }

  Future<void> _showNotificationWithSubtitle() async {
    await NotificationMasterDesktop.showNotification(
      title: 'پیام جدید',
      subtitle: 'از احمد رضایی',
      body: 'سلام! چطوری؟ امروز وقت داری؟',
      onClick: () {
        setState(() {
          _lastAction = 'Message notification clicked';
        });
      },
    );
  }

  Future<void> _showSilentNotification() async {
    await NotificationMasterDesktop.showNotification(
      title: 'نوتیفیکیشن بی‌صدا',
      body: 'این نوتیفیکیشن صدا ندارد',
      silent: true,
      onShow: () {
        setState(() {
          _lastAction = 'Silent notification shown';
        });
      },
    );
  }

  Future<void> _showNotificationWithActions() async {
    await NotificationMasterDesktop.showNotificationWithActions(
      title: 'درخواست تایید',
      body: 'آیا می‌خواهید این عملیات را انجام دهید؟',
      actions: ['بله', 'خیر', 'بعداً'],
      onActionClick: (actionIndex) {
        String action = '';
        switch (actionIndex) {
          case 0:
            action = 'User clicked: بله';
            break;
          case 1:
            action = 'User clicked: خیر';
            break;
          case 2:
            action = 'User clicked: بعداً';
            break;
        }
        setState(() {
          _lastAction = action;
        });
      },
      onClick: () {
        setState(() {
          _lastAction = 'Action notification body clicked';
        });
      },
    );
  }

  Future<void> _showMultipleNotifications() async {
    for (int i = 1; i <= 3; i++) {
      await NotificationMasterDesktop.showNotification(
        title: 'نوتیفیکیشن شماره $i',
        body: 'این نوتیفیکیشن شماره $i از ۳ است',
      );
      await Future.delayed(const Duration(milliseconds: 500));
    }
    setState(() {
      _lastAction = '3 notifications sent';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Desktop Notifications Demo'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: _isInitialized ? Colors.green.shade50 : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isInitialized ? Icons.check_circle : Icons.error,
                          color: _isInitialized ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'وضعیت: ${_isInitialized ? "آماده" : "غیرفعال"}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'پلتفرم: ${NotificationMasterDesktop.isSupported() ? "دسکتاپ (پشتیبانی می‌شود)" : "موبایل/وب"}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'آخرین عملیات: $_lastAction',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Basic Notifications Section
            const Text(
              'نوتیفیکیشن‌های پایه',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isInitialized ? _showSimpleNotification : null,
              icon: const Icon(Icons.notifications),
              label: const Text('نوتیفیکیشن ساده'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _isInitialized ? _showNotificationWithSubtitle : null,
              icon: const Icon(Icons.message),
              label: const Text('نوتیفیکیشن با زیرعنوان (فقط macOS)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _isInitialized ? _showSilentNotification : null,
              icon: const Icon(Icons.notifications_off),
              label: const Text('نوتیفیکیشن بی‌صدا'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // Advanced Notifications Section
            const Text(
              'نوتیفیکیشن‌های پیشرفته',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isInitialized ? _showNotificationWithActions : null,
              icon: const Icon(Icons.touch_app),
              label: const Text('نوتیفیکیشن با دکمه‌های اکشن'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _isInitialized ? _showMultipleNotifications : null,
              icon: const Icon(Icons.notifications_active),
              label: const Text('نمایش چند نوتیفیکیشن'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Information Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'نکات مهم',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      '• نوتیفیکیشن‌ها از تم پیش‌فرض سیستم عامل استفاده می‌کنند',
                    ),
                    _buildInfoItem(
                      '• زیرعنوان (subtitle) فقط در macOS کار می‌کند',
                    ),
                    _buildInfoItem(
                      '• دکمه‌های اکشن در همه پلتفرم‌های دسکتاپ پشتیبانی می‌شوند',
                    ),
                    _buildInfoItem(
                      '• نوتیفیکیشن‌ها به صورت خودکار زیبا و بومی نمایش داده می‌شوند',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Requirements Card
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'نیازمندی‌ها',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem('• Linux: نیاز به نصب libnotify-dev'),
                    _buildInfoItem('  sudo apt-get install libnotify-dev'),
                    _buildInfoItem('• macOS: بدون نیازمندی اضافی'),
                    _buildInfoItem('• Windows: بدون نیازمندی اضافی'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
      ),
    );
  }
}
