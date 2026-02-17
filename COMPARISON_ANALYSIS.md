# مقایسه جامع: local_notifier vs notification_master

## 📊 جدول مقایسه کلی

| ویژگی | local_notifier | notification_master | توصیه |
|-------|----------------|---------------------|-------|
| **پلتفرم‌ها** |
| Android | ❌ | ✅ | notification_master |
| iOS | ❌ | ✅ | notification_master |
| Web | ❌ | ✅ | notification_master |
| Linux | ✅ | ✅ (محدود) | local_notifier |
| macOS | ✅ | ✅ (محدود) | local_notifier |
| Windows | ✅ | ✅ (محدود) | local_notifier |
| **قابلیت‌های پایه** |
| نوتیفیکیشن ساده | ✅ | ✅ | هر دو |
| عنوان و متن | ✅ | ✅ | هر دو |
| زیرعنوان | ✅ (فقط macOS) | ❌ | local_notifier |
| نوتیفیکیشن بی‌صدا | ✅ | ✅ | هر دو |
| شناسه یکتا | ✅ | ✅ | هر دو |
| **قابلیت‌های پیشرفته** |
| دکمه‌های اکشن | ✅ | ✅ | هر دو |
| نوتیفیکیشن با تصویر | ❌ | ✅ | notification_master |
| Big Text | ❌ | ✅ | notification_master |
| کانال‌های سفارشی | ❌ | ✅ | notification_master |
| HTTP Polling | ❌ | ✅ | notification_master |
| Foreground Service | ❌ | ✅ | notification_master |
| **رویدادها** |
| onShow | ✅ | ❌ | local_notifier |
| onClick | ✅ | ✅ | هر دو |
| onClose | ✅ | ❌ | local_notifier |
| onClickAction | ✅ | ✅ | هر دو |
| **کاستومایز UI** |
| تم سیستم | ✅ (خودکار) | ✅ (خودکار) | هر دو |
| رنگ سفارشی | ❌ | ✅ (Android) | notification_master |
| فونت سفارشی | ❌ | ❌ | هیچکدام |
| لی‌اوت سفارشی | ❌ | محدود | محدود |

---

## 🎯 استراتژی پیشنهادی: ترکیب هر دو پکیج

### چرا ترکیب؟

1. **پوشش کامل پلتفرم‌ها**: موبایل + وب + دسکتاپ
2. **بهترین تجربه کاربری**: استفاده از قابلیت‌های بومی هر پلتفرم
3. **انعطاف‌پذیری**: انتخاب بهترین ابزار برای هر پلتفرم

### معماری پیشنهادی

```dart
// lib/notification_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:notification_master/notification_master.dart';
import 'package:local_notifier/local_notifier.dart';

class UnifiedNotificationService {
  static final NotificationMaster _notificationMaster = NotificationMaster();
  static bool _isInitialized = false;

  /// Initialize notification service for all platforms
  static Future<void> initialize({
    required String appName,
  }) async {
    if (_isInitialized) return;

    // Initialize desktop notifications
    if (_isDesktopPlatform()) {
      await localNotifier.setup(
        appName: appName,
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
    }

    // Initialize mobile/web notifications
    if (_isMobilePlatform() || kIsWeb) {
      final hasPermission = await _notificationMaster.checkNotificationPermission();
      if (!hasPermission) {
        await _notificationMaster.requestNotificationPermission();
      }
    }

    _isInitialized = true;
  }

  /// Show a simple notification on any platform
  static Future<void> showNotification({
    required String title,
    required String message,
    String? subtitle,
    bool silent = false,
    VoidCallback? onClick,
  }) async {
    if (!_isInitialized) {
      throw Exception('NotificationService not initialized. Call initialize() first.');
    }

    if (_isDesktopPlatform()) {
      // Use local_notifier for desktop
      await _showDesktopNotification(
        title: title,
        body: message,
        subtitle: subtitle,
        silent: silent,
        onClick: onClick,
      );
    } else {
      // Use notification_master for mobile/web
      await _notificationMaster.showNotification(
        title: title,
        message: message,
      );
    }
  }

  /// Show notification with actions
  static Future<void> showNotificationWithActions({
    required String title,
    required String message,
    required List<String> actions,
    Function(int)? onActionClick,
    VoidCallback? onClick,
  }) async {
    if (!_isInitialized) {
      throw Exception('NotificationService not initialized. Call initialize() first.');
    }

    if (_isDesktopPlatform()) {
      // Use local_notifier for desktop
      LocalNotification notification = LocalNotification(
        title: title,
        body: message,
        actions: actions.map((action) => 
          LocalNotificationAction(text: action)
        ).toList(),
      );

      if (onClick != null) {
        notification.onClick = onClick;
      }

      if (onActionClick != null) {
        notification.onClickAction = onActionClick;
      }

      await notification.show();
    } else {
      // Use notification_master for mobile/web
      await _notificationMaster.showNotificationWithActions(
        title: title,
        message: message,
        actions: actions.asMap().entries.map((entry) => {
          'title': entry.value,
          'route': '/action_${entry.key}',
        }).toList(),
      );
    }
  }

  /// Show notification with image (mobile/web only)
  static Future<void> showImageNotification({
    required String title,
    required String message,
    required String imageUrl,
  }) async {
    if (_isDesktopPlatform()) {
      // Desktop doesn't support images, show simple notification
      await showNotification(
        title: title,
        message: message,
      );
    } else {
      // Use notification_master for mobile/web
      await _notificationMaster.showImageNotification(
        title: title,
        message: message,
        imageUrl: imageUrl,
      );
    }
  }

  /// Show big text notification (mobile only)
  static Future<void> showBigTextNotification({
    required String title,
    required String message,
    required String bigText,
  }) async {
    if (_isDesktopPlatform()) {
      // Desktop doesn't support big text, show simple notification
      await showNotification(
        title: title,
        message: bigText, // Use bigText as message
      );
    } else {
      // Use notification_master for mobile
      await _notificationMaster.showBigTextNotification(
        title: title,
        message: message,
        bigText: bigText,
      );
    }
  }

  // Private helper methods

  static Future<void> _showDesktopNotification({
    required String title,
    required String body,
    String? subtitle,
    bool silent = false,
    VoidCallback? onClick,
  }) async {
    LocalNotification notification = LocalNotification(
      title: title,
      subtitle: subtitle,
      body: body,
      silent: silent,
    );

    if (onClick != null) {
      notification.onClick = onClick;
    }

    await notification.show();
  }

  static bool _isDesktopPlatform() {
    return !kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows);
  }

  static bool _isMobilePlatform() {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  static String getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    return 'Unknown';
  }
}
```

---

## 📱 مثال استفاده از سرویس یکپارچه

```dart
import 'package:flutter/material.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize unified notification service
  await UnifiedNotificationService.initialize(
    appName: 'my_awesome_app',
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NotificationDemo(),
    );
  }
}

class NotificationDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Unified Notifications'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Platform: ${UnifiedNotificationService.getPlatformName()}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: () async {
                await UnifiedNotificationService.showNotification(
                  title: 'Simple Notification',
                  message: 'This works on all platforms!',
                  onClick: () {
                    print('Notification clicked!');
                  },
                );
              },
              child: Text('Show Simple Notification'),
            ),
            
            SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: () async {
                await UnifiedNotificationService.showNotificationWithActions(
                  title: 'Action Notification',
                  message: 'Choose an option',
                  actions: ['Yes', 'No', 'Maybe'],
                  onActionClick: (index) {
                    print('Action $index clicked');
                  },
                );
              },
              child: Text('Show Notification with Actions'),
            ),
            
            SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: () async {
                await UnifiedNotificationService.showImageNotification(
                  title: 'Image Notification',
                  message: 'This has an image (mobile/web only)',
                  imageUrl: 'https://picsum.photos/200',
                );
              },
              child: Text('Show Image Notification'),
            ),
            
            SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: () async {
                await UnifiedNotificationService.showBigTextNotification(
                  title: 'Big Text Notification',
                  message: 'Short message',
                  bigText: 'This is a very long text that will be shown '
                      'when the notification is expanded. It can contain '
                      'multiple lines and detailed information.',
                );
              },
              child: Text('Show Big Text Notification'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🎨 مقایسه ظاهر نوتیفیکیشن‌ها

### Linux (GNOME)
```
┌─────────────────────────────────────┐
│ 🔔 عنوان نوتیفیکیشن                │
│ متن نوتیفیکیشن در اینجا نمایش...   │
│                                     │
│ [دکمه 1]  [دکمه 2]                 │
└─────────────────────────────────────┘
```
- تم: مطابق با تم GNOME/KDE/XFCE
- رنگ: خاکستری/سفید (بستگی به تم)
- فونت: فونت سیستم

### macOS
```
┌─────────────────────────────────────┐
│ 🔔 عنوان نوتیفیکیشن                │
│ زیرعنوان (اختیاری)                 │
│ متن نوتیفیکیشن در اینجا...         │
│                                     │
│ [دکمه 1]  [دکمه 2]                 │
└─────────────────────────────────────┘
```
- تم: مطابق با macOS Notification Center
- رنگ: سفید/خاکستری (Light/Dark mode)
- فونت: San Francisco

### Windows
```
┌─────────────────────────────────────┐
│ 🔔 عنوان نوتیفیکیشن                │
│ متن نوتیفیکیشن در اینجا نمایش...   │
│                                     │
│ [دکمه 1]  [دکمه 2]                 │
└─────────────────────────────────────┘
```
- تم: مطابق با Windows Toast
- رنگ: سفید/خاکستری (Light/Dark mode)
- فونت: Segoe UI

### Android (notification_master)
```
┌─────────────────────────────────────┐
│ 🔔 عنوان نوتیفیکیشن                │
│ متن نوتیفیکیشن...                   │
│ [تصویر بزرگ در صورت وجود]          │
│                                     │
│ [دکمه 1]  [دکمه 2]  [دکمه 3]       │
└─────────────────────────────────────┘
```
- تم: Material Design
- رنگ: قابل تنظیم (با کانال‌های سفارشی)
- فونت: Roboto

---

## 💰 هزینه و پیچیدگی

| جنبه | local_notifier | notification_master | ترکیب هر دو |
|------|----------------|---------------------|-------------|
| **نصب** | ساده | ساده | متوسط |
| **پیکربندی** | کم | متوسط | متوسط |
| **حجم پکیج** | کم (~50KB) | متوسط (~200KB) | زیاد (~250KB) |
| **وابستگی‌ها** | کم | متوسط | زیاد |
| **منحنی یادگیری** | کم | متوسط | متوسط |
| **نگهداری** | آسان | متوسط | متوسط |

---

## 🚀 توصیه نهایی

### برای پروژه‌های دسکتاپ فقط:
✅ استفاده از **local_notifier**

### برای پروژه‌های موبایل فقط:
✅ استفاده از **notification_master**

### برای پروژه‌های چند پلتفرمی:
✅ استفاده از **ترکیب هر دو** با سرویس یکپارچه

### برای پروژه‌های ساده:
✅ استفاده از **notification_master** (پوشش بیشتر پلتفرم‌ها)

---

## 📊 نمودار تصمیم‌گیری

```
آیا پروژه شما فقط دسکتاپ است؟
│
├─ بله → local_notifier
│
└─ خیر → آیا به قابلیت‌های پیشرفته نیاز دارید؟
    │
    ├─ بله → ترکیب هر دو
    │
    └─ خیر → notification_master
```

---

## 🔗 منابع

- [local_notifier GitHub](https://github.com/leanflutter/local_notifier)
- [notification_master GitHub](https://github.com/swanflutter/notification_master)
- [Flutter Desktop Documentation](https://docs.flutter.dev/desktop)

---

**نتیجه‌گیری**: هر دو پکیج قابلیت‌های خوبی دارند، اما برای بهترین تجربه کاربری در پروژه‌های چند پلتفرمی، ترکیب هر دو پکیج با یک سرویس یکپارچه توصیه می‌شود.
