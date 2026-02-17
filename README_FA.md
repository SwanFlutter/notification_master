# Notification Master - مدیریت جامع نوتیفیکیشن

<div dir="rtl">

یک پکیج کامل Flutter برای مدیریت نوتیفیکیشن‌ها در تمام پلتفرم‌ها با قابلیت‌های پیشرفته.

## 🌟 ویژگی‌ها

### پشتیبانی کامل از پلتفرم‌ها

| پلتفرم | وضعیت | قابلیت‌ها |
|--------|-------|-----------|
| 🤖 Android | ✅ کامل | نوتیفیکیشن محلی، کانال‌های سفارشی، سطوح اهمیت، لغو خودکار، آیکون‌های سفارشی، HTTP polling |
| 🍏 iOS | ✅ کامل | نوتیفیکیشن محلی، صداهای سفارشی، بج‌ها، HTTP polling، نوتیفیکیشن‌های غنی |
| 🍎 macOS | ✅ کامل | نوتیفیکیشن‌های بومی، صداهای سفارشی، بج‌ها، HTTP polling |
| 🪟 Windows | ✅ کامل | Toast notifications، اکشن‌های سفارشی، HTTP polling |
| 🌐 Web | ✅ کامل | نوتیفیکیشن‌های مرورگر، مدیریت مجوزها، HTTP polling |
| 🐧 Linux | ✅ کامل | نوتیفیکیشن‌های دسکتاپ، آیکون‌های سفارشی، HTTP polling |

### قابلیت‌های پیشرفته

- ✅ نوتیفیکیشن‌های ساده
- ✅ نوتیفیکیشن با متن بزرگ (Big Text)
- ✅ نوتیفیکیشن با تصویر
- ✅ نوتیفیکیشن با دکمه‌های اکشن
- ✅ کانال‌های سفارشی (Android)
- ✅ HTTP Polling برای دریافت نوتیفیکیشن از سرور
- ✅ Foreground Service برای نوتیفیکیشن‌های قابل اعتماد
- ✅ پشتیبانی از Firebase Cloud Messaging
- ✅ مدیریت خودکار مجوزها
- ✅ سرویس یکپارچه برای تمام پلتفرم‌ها

## 📦 نصب

به فایل `pubspec.yaml` اضافه کنید:

```yaml
dependencies:
  notification_master: ^0.0.3
  
  # برای پشتیبانی کامل دسکتاپ (اختیاری)
  local_notifier: ^0.1.6
```

سپس دستور زیر را اجرا کنید:

```bash
flutter pub get
```

### نیازمندی‌های پلتفرم

#### Android
✅ بدون نیازمندی اضافی! پکیج به صورت خودکار تمام مجوزها و تنظیمات را اضافه می‌کند.

#### iOS
برای راهنمای تنظیمات iOS، به [IOS_README.md](IOS_README.md) مراجعه کنید.

#### Linux
```bash
sudo apt-get install libnotify-dev
```

#### macOS و Windows
بدون نیازمندی اضافی

## 🚀 شروع سریع

### راه‌اندازی اولیه

```dart
import 'package:flutter/material.dart';
import 'package:notification_master/notification_master.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // راه‌اندازی سرویس یکپارچه نوتیفیکیشن
  await UnifiedNotificationService.initialize(
    appName: 'my_awesome_app',
  );
  
  runApp(MyApp());
}
```

### بررسی و درخواست مجوز

```dart
final notificationMaster = NotificationMaster();

// بررسی مجوز
final hasPermission = await notificationMaster.checkNotificationPermission();

// درخواست مجوز (برای Android 13+)
if (!hasPermission) {
  final granted = await notificationMaster.requestNotificationPermission();
  if (!granted) {
    print('مجوز نوتیفیکیشن رد شد');
    return;
  }
}
```

## 📱 مثال‌های استفاده

### 1. نوتیفیکیشن ساده

```dart
// استفاده از سرویس یکپارچه (توصیه می‌شود)
await UnifiedNotificationService.showNotification(
  title: 'سلام',
  message: 'این یک نوتیفیکیشن ساده است',
  onClick: () {
    print('نوتیفیکیشن کلیک شد');
  },
);

// یا استفاده مستقیم از NotificationMaster
await notificationMaster.showNotification(
  title: 'نوتیفیکیشن ساده',
  message: 'این یک نوتیفیکیشن تستی است',
);
```

### 2. نوتیفیکیشن با اهمیت بالا

```dart
await notificationMaster.showNotification(
  title: 'نوتیفیکیشن مهم',
  message: 'این یک نوتیفیکیشن با اهمیت بالا است',
  importance: NotificationImportance.high,
);
```

### 3. نوتیفیکیشن با متن بزرگ

```dart
await UnifiedNotificationService.showBigTextNotification(
  title: 'مقاله جدید',
  message: 'مقاله جدید منتشر شد',
  bigText: 'این متن کامل مقاله است که می‌تواند خیلی طولانی باشد. '
      'وقتی کاربر نوتیفیکیشن را باز کند، تمام این متن نمایش داده می‌شود. '
      'این قابلیت برای نمایش اطلاعات تفصیلی بسیار مفید است.',
);
```

### 4. نوتیفیکیشن با تصویر

```dart
await UnifiedNotificationService.showImageNotification(
  title: 'عکس جدید',
  message: 'کسی یک عکس با شما به اشتراک گذاشت',
  imageUrl: 'https://picsum.photos/200/300',
);
```

### 5. نوتیفیکیشن با دکمه‌های اکشن

```dart
await UnifiedNotificationService.showNotificationWithActions(
  title: 'درخواست دوستی',
  message: 'احمد رضایی درخواست دوستی فرستاده',
  actions: ['قبول', 'رد', 'بعداً'],
  onActionClick: (index) {
    switch (index) {
      case 0:
        print('کاربر قبول را انتخاب کرد');
        break;
      case 1:
        print('کاربر رد را انتخاب کرد');
        break;
      case 2:
        print('کاربر بعداً را انتخاب کرد');
        break;
    }
  },
);
```

### 6. کانال سفارشی (Android)

```dart
// ایجاد کانال با اهمیت بالا
await notificationMaster.createCustomChannel(
  channelId: 'urgent_alerts',
  channelName: 'هشدارهای فوری',
  channelDescription: 'کانال برای نوتیفیکیشن‌های مهم که نیاز به توجه فوری دارند',
  importance: NotificationImportance.high,
  enableLights: true,
  lightColor: 0xFFFF0000, // رنگ قرمز
  enableVibration: true,
  enableSound: true,
);

// استفاده از کانال
await notificationMaster.showNotification(
  title: 'خطای سیستم',
  message: 'نیاز به توجه فوری',
  channelId: 'urgent_alerts',
);
```

### 7. HTTP Polling

```dart
// شروع polling برای دریافت نوتیفیکیشن از سرور
await notificationMaster.startNotificationPolling(
  pollingUrl: 'https://your-api.com/notifications',
  intervalMinutes: 15, // هر 15 دقیقه یکبار
);

// توقف polling
await notificationMaster.stopNotificationPolling();

// بررسی وضعیت سرویس
String activeService = await notificationMaster.getActiveNotificationService();
print('سرویس فعال: $activeService');
```

### 8. Foreground Service

```dart
// شروع foreground service برای نوتیفیکیشن‌های قابل اعتماد
await notificationMaster.startForegroundService(
  pollingUrl: 'https://your-api.com/notifications',
  intervalMinutes: 10,
  channelId: 'notification_service',
  channelName: 'سرویس نوتیفیکیشن',
  channelDescription: 'برنامه را برای دریافت نوتیفیکیشن فعال نگه می‌دارد',
  importance: NotificationImportance.low,
);

// توقف foreground service
await notificationMaster.stopForegroundService();
```

## 🎨 سرویس یکپارچه نوتیفیکیشن

سرویس `UnifiedNotificationService` به صورت خودکار بهترین روش نوتیفیکیشن را برای هر پلتفرم انتخاب می‌کند:

- **دسکتاپ** (Linux, macOS, Windows): از `local_notifier` استفاده می‌کند
- **موبایل** (Android, iOS): از `notification_master` استفاده می‌کند
- **وب**: از `notification_master` استفاده می‌کند

### مزایا

✅ یک API واحد برای تمام پلتفرم‌ها
✅ انتخاب خودکار بهترین روش
✅ مدیریت خودکار تفاوت‌های پلتفرم
✅ کد تمیز و قابل نگهداری

### مثال کامل

```dart
import 'package:flutter/material.dart';
import 'package:notification_master/notification_master.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await UnifiedNotificationService.initialize(
    appName: 'my_app',
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Master Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'پلتفرم: ${UnifiedNotificationService.getPlatformName()}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: () async {
                await UnifiedNotificationService.showNotification(
                  title: 'سلام',
                  message: 'این در همه پلتفرم‌ها کار می‌کند!',
                );
              },
              child: Text('نمایش نوتیفیکیشن'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 📚 مستندات کامل

- [راهنمای Android](ANDROID_README.md)
- [راهنمای iOS](IOS_README.md)
- [راهنمای نوتیفیکیشن‌های دسکتاپ](DESKTOP_NOTIFICATIONS_GUIDE.md)
- [تحلیل local_notifier](LOCAL_NOTIFIER_ANALYSIS_FA.md)
- [مقایسه پکیج‌ها](COMPARISON_ANALYSIS.md)

## 🎯 مثال‌های کاربردی

### برنامه پیام‌رسانی

```dart
class MessageNotificationService {
  static Future<void> showNewMessage({
    required String senderName,
    required String message,
  }) async {
    await UnifiedNotificationService.showNotificationWithActions(
      title: 'پیام جدید',
      message: '$senderName: $message',
      actions: ['پاسخ', 'نادیده بگیر'],
      onActionClick: (index) {
        if (index == 0) {
          // باز کردن صفحه پاسخ
        }
      },
    );
  }
}
```

### سیستم یادآوری

```dart
class ReminderService {
  static Future<void> showReminder({
    required String title,
    required String description,
  }) async {
    await UnifiedNotificationService.showNotificationWithActions(
      title: '⏰ یادآوری',
      message: title,
      actions: ['انجام شد', 'یادآوری بعدی', 'حذف'],
      onActionClick: (index) {
        switch (index) {
          case 0:
            // علامت‌گذاری به عنوان انجام شده
            break;
          case 1:
            // تنظیم یادآوری بعدی
            break;
          case 2:
            // حذف یادآوری
            break;
        }
      },
    );
  }
}
```

### اعلان‌های سیستمی

```dart
class SystemNotificationService {
  static Future<void> showUpdateAvailable({
    required String version,
  }) async {
    await UnifiedNotificationService.showNotificationWithActions(
      title: '🔄 به‌روزرسانی جدید',
      message: 'نسخه $version در دسترس است',
      actions: ['دانلود', 'بعداً'],
      onActionClick: (index) {
        if (index == 0) {
          // شروع دانلود
        }
      },
    );
  }
}
```

## 🔧 تنظیمات پیشرفته

### فرمت پاسخ سرور برای HTTP Polling

```json
{
  "notifications": [
    {
      "title": "عنوان نوتیفیکیشن",
      "message": "پیام نوتیفیکیشن",
      "bigText": "متن کامل (اختیاری)",
      "channelId": "شناسه کانال (اختیاری)"
    }
  ]
}
```

### مدیریت چند سرویس نوتیفیکیشن

```dart
// بررسی سرویس فعال
String activeService = await notificationMaster.getActiveNotificationService();

// تغییر به Firebase
await notificationMaster.setFirebaseAsActiveService();

// تغییر به Polling
await notificationMaster.startNotificationPolling(
  pollingUrl: 'https://api.example.com/notifications',
  intervalMinutes: 15,
);

// تغییر به Foreground Service
await notificationMaster.startForegroundService(
  pollingUrl: 'https://api.example.com/notifications',
  intervalMinutes: 10,
);
```

## ⚠️ نکات مهم

### Android
- API Level 24+ مورد نیاز است
- کانال‌های نوتیفیکیشن به صورت خودکار برای Android 8.0+ ایجاد می‌شوند
- از WorkManager برای polling قابل اعتماد استفاده می‌شود
- Foreground service نوتیفیکیشن دائمی نمایش می‌دهد

### iOS
- به صورت خودکار مجوز نوتیفیکیشن درخواست می‌شود
- تنظیمات Do Not Disturb سیستم را رعایت می‌کند
- Polling در پس‌زمینه ممکن است توسط iOS محدود شود

### دسکتاپ
- از سیستم نوتیفیکیشن بومی استفاده می‌کند
- ظاهر نوتیفیکیشن مطابق با تم سیستم عامل است
- Linux نیاز به نصب `libnotify-dev` دارد

### وب
- نیاز به HTTPS در محیط production
- مجوز نوتیفیکیشن باید توسط تعامل کاربر درخواست شود
- قابلیت‌های پردازش پس‌زمینه محدود است

## 🐛 عیب‌یابی

### نوتیفیکیشن‌ها نمایش داده نمی‌شوند

```dart
// ابتدا مجوز را بررسی کنید
bool hasPermission = await notificationMaster.checkNotificationPermission();
if (!hasPermission) {
  bool granted = await notificationMaster.requestNotificationPermission();
  print('مجوز: $granted');
}

// وضعیت سرویس را بررسی کنید
String activeService = await notificationMaster.getActiveNotificationService();
print('سرویس فعال: $activeService');
```

### Polling کار نمی‌کند

```dart
// توقف و راه‌اندازی مجدد
await notificationMaster.stopNotificationPolling();
await Future.delayed(Duration(seconds: 2));
await notificationMaster.startNotificationPolling(
  pollingUrl: 'https://your-api.com/notifications',
  intervalMinutes: 15,
);
```

## 🤝 مشارکت

مشارکت شما خوش‌آمد است! لطفاً [راهنمای مشارکت](CONTRIBUTING.md) را مطالعه کنید.

## 📄 مجوز

این پروژه تحت مجوز MIT منتشر شده است. برای جزئیات بیشتر [LICENSE](LICENSE) را ببینید.

## 📞 پشتیبانی

- 📧 ایمیل: swan.dev1993@gmail.com
- 🐛 گزارش مشکلات: [GitHub Issues](https://github.com/swanflutter/notification_master/issues)
- 💬 بحث و گفتگو: [GitHub Discussions](https://github.com/swanflutter/notification_master/discussions)

## 🌟 حمایت از پروژه

اگر این پکیج برای شما مفید بود، لطفاً با دادن ستاره ⭐ در GitHub از ما حمایت کنید!

---

**ساخته شده با ❤️ برای جامعه Flutter**

</div>
