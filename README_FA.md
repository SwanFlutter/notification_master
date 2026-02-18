# Notification Master

یک پلاگین جامع و آماده برای تولید برای مدیریت نوتیفیکیشن‌ها در تمام پلتفرم‌های Flutter با قابلیت‌های پیشرفته شامل HTTP polling، کانال‌های سفارشی، سرویس foreground و بهینه‌سازی‌های اختصاصی هر پلتفرم.

## 🌟 ویژگی‌های کلیدی

- ✅ **پشتیبانی چند پلتفرمی**: Android، iOS، Web، Linux، macOS، Windows
- 🔄 **HTTP Polling**: دریافت خودکار نوتیفیکیشن از سرور در پس‌زمینه
- 🚀 **سرویس Foreground**: ارسال قابل اعتماد نوتیفیکیشن حتی وقتی اپ بسته است (Android)
- 📱 **نوتیفیکیشن‌های غنی**: متن بزرگ، تصاویر، دکمه‌های اکشن، کانال‌های سفارشی
- 🎨 **قابل سفارشی‌سازی**: اهمیت کانال، صدا، ویبره، رنگ LED
- 🔔 **انواع سرویس**: WorkManager polling، سرویس Foreground، یکپارچگی با Firebase
- 🎯 **پشتیبانی از ناوبری**: Deep linking به صفحات خاص از نوتیفیکیشن
- 🔐 **مدیریت مجوزها**: درخواست و بررسی مجوز به صورت داخلی

## 📊 پشتیبانی پلتفرم‌ها

| پلتفرم | پشتیبانی | ویژگی‌ها |
|----------|---------|----------|
| Android  | ✅ کامل | نوتیفیکیشن محلی، کانال‌های سفارشی، سطوح اهمیت، لغو خودکار، آیکون سفارشی، HTTP polling، سرویس foreground |
| iOS      | ✅ کامل | نوتیفیکیشن محلی، صداهای سفارشی، بج، HTTP polling، نوتیفیکیشن‌های غنی |
| macOS    | ✅ کامل | نوتیفیکیشن‌های بومی، صداهای سفارشی، بج، HTTP polling |
| Windows  | ✅ کامل | Toast notifications، اکشن‌های سفارشی، HTTP polling |
| Web      | ✅ کامل | نوتیفیکیشن مرورگر، مدیریت مجوز، HTTP polling |
| Linux    | ✅ کامل | نوتیفیکیشن دسکتاپ، آیکون‌های سفارشی، HTTP polling |

## 📦 نصب

این پلاگین را به فایل `pubspec.yaml` پروژه خود اضافه کنید:

```yaml
dependencies:
  notification_master: ^0.0.4
```

سپس اجرا کنید:

```bash
flutter pub get
```

## ⚙️ تنظیمات پلتفرم

### تنظیمات Android

مجوزهای زیر را به فایل `android/app/src/main/AndroidManifest.xml` داخل تگ `<manifest>` اضافه کنید:

```xml
<!-- مجوز اینترنت برای نوتیفیکیشن‌های HTTP -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- برای Android 13+ (API level 33+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- برای سرویس foreground -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />

<!-- برای راه‌اندازی مجدد سرویس نوتیفیکیشن بعد از ریستارت دستگاه -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

**نکته:** پلاگین به صورت خودکار `android:enableOnBackInvokedCallback="true"` را پیکربندی می‌کند.

### تنظیمات iOS

برای دستورالعمل‌های تنظیم iOS، فایل [IOS_README.md](IOS_README.md) را ببینید.

## 🚀 شروع سریع

```dart
import 'package:notification_master/notification_master.dart';

// ایجاد یک نمونه از پلاگین
final notificationMaster = NotificationMaster();

// بررسی اینکه آیا مجوز نوتیفیکیشن داده شده است
final hasPermission = await notificationMaster.checkNotificationPermission();

// درخواست مجوز نوتیفیکیشن (الزامی برای Android 13+)
if (!hasPermission) {
  final granted = await notificationMaster.requestNotificationPermission();
  if (!granted) {
    print('مجوز نوتیفیکیشن رد شد');
    return;
  }
}
```


## 📱 استفاده پایه

### نوتیفیکیشن‌های ساده

```dart
// نمایش یک نوتیفیکیشن ساده
await notificationMaster.showNotification(
  title: 'سلام',
  message: 'این یک نوتیفیکیشن ساده است',
);

// نمایش نوتیفیکیشن با ID سفارشی
await notificationMaster.showNotification(
  id: 123,
  title: 'ID سفارشی',
  message: 'این نوتیفیکیشن یک ID سفارشی دارد',
);

// نمایش نوتیفیکیشن با اهمیت بالا (Android)
await notificationMaster.showNotification(
  title: 'مهم!',
  message: 'این یک نوتیفیکیشن با اهمیت بالا است',
  importance: NotificationImportance.high,
);

// نمایش نوتیفیکیشن پایدار (بعد از کلیک حذف نمی‌شود)
await notificationMaster.showNotification(
  title: 'پایدار',
  message: 'این نوتیفیکیشن بعد از کلیک باقی می‌ماند',
  autoCancel: false,
);

// نمایش نوتیفیکیشن با ناوبری
await notificationMaster.showNotification(
  title: 'باز کردن تنظیمات',
  message: 'برای باز کردن صفحه تنظیمات کلیک کنید',
  targetScreen: '/settings',
  extraData: {'userId': '123', 'action': 'view'},
);
```

### نوتیفیکیشن‌های غنی

```dart
// نوتیفیکیشن با متن بزرگ (قابل گسترش)
await notificationMaster.showBigTextNotification(
  title: 'به‌روزرسانی مقاله',
  message: 'مقاله جدید منتشر شد',
  bigText: 'لورم ایپسوم متن ساختگی با تولید سادگی نامفهوم از صنعت چاپ '
           'و با استفاده از طراحان گرافیک است. چاپگرها و متون بلکه روزنامه '
           'و مجله در ستون و سطرآنچنان که لازم است.',
);

// نوتیفیکیشن با تصویر
await notificationMaster.showImageNotification(
  title: 'عکس جدید',
  message: 'علی یک عکس با شما به اشتراک گذاشت',
  imageUrl: 'https://example.com/photo.jpg',
);

// نوتیفیکیشن با دکمه‌های اکشن
await notificationMaster.showNotificationWithActions(
  title: 'یادآوری جلسه',
  message: 'جلسه تیم تا 10 دقیقه دیگر',
  actions: [
    {'title': 'پیوستن', 'route': '/meeting'},
    {'title': 'به تعویق انداختن', 'route': '/snooze'},
    {'title': 'رد کردن', 'route': '/dismiss'},
  ],
);
```

### کانال‌های سفارشی نوتیفیکیشن (Android 8.0+)

```dart
// ایجاد یک کانال با اولویت بالا با صدا و ویبره
await notificationMaster.createCustomChannel(
  channelId: 'urgent_channel',
  channelName: 'نوتیفیکیشن‌های فوری',
  channelDescription: 'برای نوتیفیکیشن‌های حساس به زمان',
  importance: NotificationImportance.high,
  enableLights: true,
  lightColor: 0xFFFF0000, // قرمز
  enableVibration: true,
  enableSound: true,
);

// ایجاد یک کانال بی‌صدا
await notificationMaster.createCustomChannel(
  channelId: 'silent_channel',
  channelName: 'نوتیفیکیشن‌های بی‌صدا',
  channelDescription: 'بدون صدا یا ویبره',
  importance: NotificationImportance.min,
  enableLights: false,
  enableVibration: false,
  enableSound: false,
);

// استفاده از کانال سفارشی
await notificationMaster.showNotification(
  title: 'فوری!',
  message: 'این از کانال فوری استفاده می‌کند',
  channelId: 'urgent_channel',
);
```


## 🔄 HTTP Polling - دریافت خودکار نوتیفیکیشن

یکی از قدرتمندترین ویژگی‌های Notification Master، قابلیت دریافت خودکار نوتیفیکیشن از سرور شما در بازه‌های زمانی منظم است. این ویژگی برای اپ‌هایی که نیاز به نمایش نوتیفیکیشن‌های سمت سرور دارند بدون پیاده‌سازی Firebase Cloud Messaging عالی است.

### نحوه کار HTTP Polling

پلاگین به صورت دوره‌ای درخواست‌های HTTP GET به سرور شما ارسال می‌کند و پاسخ JSON را پردازش کرده و نوتیفیکیشن‌ها را نمایش می‌دهد. شما می‌توانید بین دو روش polling انتخاب کنید:

1. **Background Polling (WorkManager)**: کم‌مصرف، اما ممکن است وقتی اپ بسته است متوقف شود
2. **Foreground Service**: قابل اعتمادتر، حتی وقتی اپ بسته است ادامه می‌دهد، اما یک نوتیفیکیشن پایدار نمایش می‌دهد

### فرمت پاسخ سرور

سرور شما باید یک پاسخ JSON به این فرمت برگرداند:

```json
{
  "notifications": [
    {
      "title": "عنوان نوتیفیکیشن",
      "message": "متن پیام نوتیفیکیشن",
      "bigText": "متن گسترش‌یافته اختیاری برای استایل متن بزرگ",
      "channelId": "ID کانال سفارشی اختیاری"
    },
    {
      "title": "نوتیفیکیشن دیگر",
      "message": "پیام دیگر"
    }
  ]
}
```

### Background Polling (WorkManager)

بهترین گزینه برای نوتیفیکیشن‌های غیرحیاتی. از Android WorkManager برای وظایف پس‌زمینه کم‌مصرف استفاده می‌کند.

```dart
// شروع background polling
final success = await notificationMaster.startNotificationPolling(
  pollingUrl: 'https://your-server.com/api/notifications',
  intervalMinutes: 15, // هر 15 دقیقه یک بار بررسی کن
);

if (success) {
  print('Background polling شروع شد');
}

// توقف background polling
await notificationMaster.stopNotificationPolling();
```

**مزایا:**
- کم‌مصرف
- بهینه‌سازی باتری Android را رعایت می‌کند
- برای نوتیفیکیشن‌های غیرحیاتی مناسب است

**معایب:**
- ممکن است وقتی اپ بسته است یا دستگاه در حالت Doze است متوقف شود
- تضمینی برای اجرا در بازه‌های زمانی دقیق نیست

### Foreground Service Polling (توصیه می‌شود برای قابلیت اعتماد)

بهترین گزینه برای نوتیفیکیشن‌های حیاتی. یک نوتیفیکیشن پایدار ایجاد می‌کند اما تحویل قابل اعتماد را تضمین می‌کند.

```dart
// شروع foreground service با کانال سفارشی
final success = await notificationMaster.startForegroundService(
  pollingUrl: 'https://your-server.com/api/notifications',
  intervalMinutes: 15,
  channelId: 'polling_service',
  channelName: 'سرویس نوتیفیکیشن',
  channelDescription: 'اپ را در حال بررسی نوتیفیکیشن‌های جدید نگه می‌دارد',
  importance: NotificationImportance.low, // اهمیت پایین برای نوتیفیکیشن سرویس
  enableSound: false,
  enableVibration: false,
);

if (success) {
  print('Foreground service شروع شد');
}

// توقف foreground service
await notificationMaster.stopForegroundService();
```

**مزایا:**
- حتی وقتی اپ بسته است به کار خود ادامه می‌دهد
- تحویل نوتیفیکیشن قابل اعتمادتر
- تحت تأثیر بهینه‌سازی باتری نیست

**معایب:**
- یک نوتیفیکیشن پایدار نمایش می‌دهد (الزامی توسط Android)
- مصرف باتری کمی بیشتر

### بررسی سرویس فعال

```dart
// دریافت سرویس نوتیفیکیشن فعال فعلی
final activeService = await notificationMaster.getActiveNotificationService();

switch (activeService) {
  case 'none':
    print('هیچ سرویس نوتیفیکیشنی فعال نیست');
    break;
  case 'polling':
    print('Background polling فعال است');
    break;
  case 'foreground':
    print('Foreground service فعال است');
    break;
  case 'firebase':
    print('Firebase Cloud Messaging فعال است');
    break;
}
```

### مثال کامل HTTP Polling

```dart
import 'package:flutter/material.dart';
import 'package:notification_master/notification_master.dart';

class NotificationPollingExample extends StatefulWidget {
  @override
  _NotificationPollingExampleState createState() => _NotificationPollingExampleState();
}

class _NotificationPollingExampleState extends State<NotificationPollingExample> {
  final _notificationMaster = NotificationMaster();
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  Future<void> _setupNotifications() async {
    // درخواست مجوز
    final hasPermission = await _notificationMaster.checkNotificationPermission();
    if (!hasPermission) {
      await _notificationMaster.requestNotificationPermission();
    }

    // ایجاد کانال‌های سفارشی
    await _notificationMaster.createCustomChannel(
      channelId: 'server_notifications',
      channelName: 'نوتیفیکیشن‌های سرور',
      channelDescription: 'نوتیفیکیشن‌ها از سرور',
      importance: NotificationImportance.high,
      enableSound: true,
      enableVibration: true,
    );

    // بررسی اینکه آیا polling از قبل فعال است
    final activeService = await _notificationMaster.getActiveNotificationService();
    setState(() {
      _isPolling = activeService == 'polling' || activeService == 'foreground';
    });
  }

  Future<void> _togglePolling() async {
    if (_isPolling) {
      // توقف polling
      await _notificationMaster.stopNotificationPolling();
      await _notificationMaster.stopForegroundService();
      setState(() => _isPolling = false);
    } else {
      // شروع foreground service برای تحویل قابل اعتماد
      final success = await _notificationMaster.startForegroundService(
        pollingUrl: 'https://your-server.com/api/notifications',
        intervalMinutes: 15,
        channelId: 'polling_service',
        channelName: 'سرویس نوتیفیکیشن',
        importance: NotificationImportance.low,
      );
      
      if (success) {
        setState(() => _isPolling = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('مثال HTTP Polling')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isPolling ? 'Polling فعال' : 'Polling غیرفعال',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _togglePolling,
              child: Text(_isPolling ? 'توقف Polling' : 'شروع Polling'),
            ),
          ],
        ),
      ),
    );
  }
}
```


### مثال پیاده‌سازی سرور (PHP)

```php
<?php
header('Content-Type: application/json');

// مثال: برگرداندن نوتیفیکیشن‌ها از دیتابیس یا هر منبع دیگر
$notifications = [
    [
        'title' => 'پیام جدید',
        'message' => 'شما یک پیام جدید از علی دارید',
        'bigText' => 'علی می‌گوید: سلام، آیا فردا ساعت 10 صبح برای جلسه در دسترس هستید؟',
        'channelId' => 'server_notifications'
    ],
    [
        'title' => 'به‌روزرسانی سیستم',
        'message' => 'یک به‌روزرسانی جدید در دسترس است',
        'channelId' => 'server_notifications'
    ]
];

echo json_encode(['notifications' => $notifications]);
?>
```

### مثال پیاده‌سازی سرور (Node.js/Express)

```javascript
const express = require('express');
const app = express();

app.get('/api/notifications', (req, res) => {
  const notifications = [
    {
      title: 'پیام جدید',
      message: 'شما یک پیام جدید از علی دارید',
      bigText: 'علی می‌گوید: سلام، آیا فردا ساعت 10 صبح برای جلسه در دسترس هستید؟',
      channelId: 'server_notifications'
    },
    {
      title: 'به‌روزرسانی سیستم',
      message: 'یک به‌روزرسانی جدید در دسترس است',
      channelId: 'server_notifications'
    }
  ];

  res.json({ notifications });
});

app.listen(3000, () => {
  console.log('سرور روی پورت 3000 در حال اجرا است');
});
```

### مثال پیاده‌سازی سرور (Python/Flask)

```python
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/api/notifications')
def get_notifications():
    notifications = [
        {
            'title': 'پیام جدید',
            'message': 'شما یک پیام جدید از علی دارید',
            'bigText': 'علی می‌گوید: سلام، آیا فردا ساعت 10 صبح برای جلسه در دسترس هستید؟',
            'channelId': 'server_notifications'
        },
        {
            'title': 'به‌روزرسانی سیستم',
            'message': 'یک به‌روزرسانی جدید در دسترس است',
            'channelId': 'server_notifications'
        }
    ]
    
    return jsonify({'notifications': notifications})

if __name__ == '__main__':
    app.run(port=3000)
```

## 🔥 یکپارچگی با Firebase

اگر از Firebase Cloud Messaging استفاده می‌کنید، می‌توانید آن را به عنوان سرویس فعال تنظیم کنید:

```dart
// تنظیم Firebase به عنوان سرویس نوتیفیکیشن فعال
// این کار هر سرویس نوتیفیکیشن فعال دیگری (polling یا foreground) را غیرفعال می‌کند
await notificationMaster.setFirebaseAsActiveService();
```

## 🎯 ناوبری و Deep Linking

مدیریت کلیک روی نوتیفیکیشن و ناوبری به صفحات خاص:

```dart
// نمایش نوتیفیکیشن با داده‌های ناوبری
await notificationMaster.showNotification(
  title: 'سفارش تحویل داده شد',
  message: 'سفارش شماره 12345 شما تحویل داده شد',
  targetScreen: '/order-details',
  extraData: {
    'orderId': '12345',
    'status': 'delivered',
    'timestamp': DateTime.now().toIso8601String(),
  },
);

// در اپ خود، ناوبری را مدیریت کنید
// پلاگین به صورت خودکار به targetScreen ناوبری می‌کند
// و extraData را به عنوان آرگومان‌های مسیر ارسال می‌کند
```

## 📋 سطوح اهمیت نوتیفیکیشن (Android)

```dart
enum NotificationImportance {
  min,      // حداقل اهمیت، بدون صدا
  low,      // اهمیت پایین، بدون صدا
  defaultImportance, // اهمیت پیش‌فرض، با صدا
  high,     // اهمیت بالا، با صدا و نمایش به صورت heads-up
  max,      // حداکثر اهمیت، با صدا و نمایش به صورت heads-up
}
```

## 🔧 ویژگی‌های پیشرفته

### بررسی وضعیت مجوز

```dart
final hasPermission = await notificationMaster.checkNotificationPermission();
if (!hasPermission) {
  // نمایش توضیح به کاربر قبل از درخواست
  final granted = await notificationMaster.requestNotificationPermission();
}
```

### دریافت نسخه پلتفرم

```dart
final version = await notificationMaster.getPlatformVersion();
print('نسخه پلتفرم: $version');
```

## 📱 نکات اختصاصی پلتفرم

### Android
- نیاز به Android 7.0+ (API level 24+)
- مجوز نوتیفیکیشن برای Android 13+ (API level 33+) الزامی است
- کانال‌های سفارشی در Android 8.0+ (API level 26+) پشتیبانی می‌شوند
- سرویس foreground نیاز به مجوز `FOREGROUND_SERVICE` دارد

### iOS
- نیاز به iOS 10.0+
- درخواست مجوز دیالوگ سیستم را نمایش می‌دهد
- صداهای سفارشی باید به app bundle اضافه شوند

### Web
- نیاز به HTTPS (به جز localhost)
- درخواست مجوز دیالوگ مرورگر را نمایش می‌دهد
- همه ویژگی‌ها پشتیبانی نمی‌شوند (مثلاً کانال‌های سفارشی)

### دسکتاپ (Linux، macOS، Windows)
- یکپارچگی با سیستم نوتیفیکیشن بومی
- برخی ویژگی‌ها ممکن است بسته به پلتفرم متفاوت باشند

## 🐛 عیب‌یابی

### نوتیفیکیشن‌ها در Android 13+ نمایش داده نمی‌شوند
مطمئن شوید که مجوز `POST_NOTIFICATIONS` را درخواست کرده‌اید:
```dart
await notificationMaster.requestNotificationPermission();
```

### HTTP Polling کار نمی‌کند
1. بررسی کنید که مجوز `INTERNET` را به AndroidManifest.xml اضافه کرده‌اید
2. URL سرور خود را بررسی کنید که صحیح و قابل دسترس باشد
3. مطمئن شوید سرور شما فرمت JSON صحیح را برمی‌گرداند
4. برای امولاتورها، از `10.0.2.2` به جای `localhost` استفاده کنید

### سرویس Foreground به طور غیرمنتظره متوقف می‌شود
1. مطمئن شوید همه مجوزهای مورد نیاز را اضافه کرده‌اید
2. بررسی کنید که بهینه‌سازی باتری برای اپ شما غیرفعال است
3. URL polling را بررسی کنید که معتبر است و JSON مناسب برمی‌گرداند

### نوتیفیکیشن‌ها در iOS نمایش داده نمی‌شوند
1. بررسی کنید که مجوزهای iOS را به درستی پیکربندی کرده‌اید
2. مجوز نوتیفیکیشن را بررسی کنید که داده شده است
3. تنظیمات نوتیفیکیشن iOS را برای اپ خود بررسی کنید

## 📚 اپ نمونه

برای یک مثال کامل و کاربردی، دایرکتوری [example](example/) را بررسی کنید که شامل:
- نوتیفیکیشن‌های ساده
- نوتیفیکیشن‌های غنی (متن بزرگ، تصاویر، اکشن‌ها)
- کانال‌های سفارشی
- HTTP polling (هم background و هم foreground)
- مدیریت سرویس
- مثال‌های اختصاصی هر پلتفرم

## 🤝 مشارکت

مشارکت‌ها خوش‌آمد هستند! لطفاً با خیال راحت یک Pull Request ارسال کنید.

## 📄 مجوز

این پروژه تحت مجوز MIT منتشر شده است - برای جزئیات فایل LICENSE را ببینید.

## 🔗 لینک‌ها

- [مخزن GitHub](https://github.com/SwanFlutter/notification_master)
- [پکیج pub.dev](https://pub.dev/packages/notification_master)
- [ردیاب مشکلات](https://github.com/SwanFlutter/notification_master/issues)

## 📞 پشتیبانی

اگر سوال یا مشکلی دارید، لطفاً:
1. [اپ نمونه](example/) را بررسی کنید
2. [مستندات](https://pub.dev/packages/notification_master) را بخوانید
3. یک [issue در GitHub](https://github.com/SwanFlutter/notification_master/issues) باز کنید

---


