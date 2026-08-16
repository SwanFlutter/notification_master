# Notification Master

یک پلاگین جامع Flutter برای مدیریت نوتیفیکیشن در تمام پلتفرم‌ها.

[![pub package](https://img.shields.io/pub/v/notification_master.svg)](https://pub.dev/packages/notification_master)
[![Pub Points](https://img.shields.io/pub/points/notification_master)](https://pub.dev/packages/permission_master/score)
[![Popularity](https://img.shields.io/pub/popularity/notification_master)](https://pub.dev/packages/permission_master)
[![Pub Likes](https://img.shields.io/pub/likes/notification_master)](https://pub.dev/packages/permission_master)
[![GitHub issues](https://img.shields.io/github/issues/SwanFlutter/notification_master)](https://github.com/SwanFlutter/permission_master/issues)
[![GitHub forks](https://img.shields.io/github/forks/SwanFlutter/notification_master)](https://github.com/SwanFlutter/permission_master/network/members)

---

## پشتیبانی پلتفرم‌ها

| پلتفرم | پشتیبانی | ویژگی‌ها |
|--------|---------|----------|
| Android | ✅ | نوتیفیکیشن محلی، کانال سفارشی، HTTP polling، Foreground Service |
| iOS | ✅ | نوتیفیکیشن محلی، صدای سفارشی، Badge، HTTP polling — **[راهنما](IOS_SETUP_FA.md)** |
| macOS | ✅ | نوتیفیکیشن native، HTTP polling، Background daemon |
| Windows | ✅ | Toast notification، ۷ نوع، سناریوهای Alarm/Call، HTTP polling، Background daemon — **[راهنما](WINDOWS_NOTIFICATIONS_GUIDE.md)** |
| Web | ✅ | Browser Notification API، مدیریت Permission |
| Linux | ✅ | Desktop notification (libnotify)، HTTP polling، Background daemon |

---

## تصاویر

- Android

![Notification_master_github_showcase_e783d3a788](https://github.com/user-attachments/assets/fe87ddb1-4144-4ab7-b2b2-45c1096fbab2)

- iOS

![Notification_master_flutter_plugin_dc39493e02](https://github.com/user-attachments/assets/1fe98992-3c3e-41e4-84f9-6781f7883ed5)
![Notification_master_flutter_plugin_23ec37c185](https://github.com/user-attachments/assets/fffc9b58-08d9-40ae-802c-529ab89d0189)

- Windows

![Screenshot 2026-02-22 042326](https://github.com/user-attachments/assets/d6ad8ce9-63a0-4a19-b727-f792458fbe94)

- Web

![Screenshot 2026-02-22 105300](https://github.com/user-attachments/assets/ae9ca66b-a36b-4662-b941-00b611098e35)

- macOS

![photo_2026-02-25_04-47-00](https://github.com/user-attachments/assets/ab7da4c0-3e30-4b79-b23d-89cd45ed0c4c)

---

## نصب

```yaml
dependencies:
  notification_master: ^1.0.1
```

```bash
flutter pub get
```

---

## فهرست مطالب

1. [راه‌اندازی پلتفرم‌ها](#راه‌اندازی-پلتفرمها)
   - [Android](#-android)
   - [iOS](#-ios)
   - [macOS](#-macos)
   - [Windows](#-windows)
   - [Linux](#-linux)
   - [Web](#-web)
2. [استفاده پایه](#استفاده-پایه)
3. [متدهای نوتیفیکیشن](#متدهای-نوتیفیکیشن)
4. [کانال سفارشی](#createcustomchannel)
5. [Firebase و Push Notification](#firebase-و-push-notification)
6. [مدیریت سرویس](#مدیریت-سرویس)
7. [مثال‌های کامل](#مثالهای-کامل)

---

## راه‌اندازی پلتفرم‌ها

### 🤖 Android

> ⚠️ پلاگین هیچ permission ای را در manifest خود اعلام **نمی‌کند**. فقط permissionهایی که اپ شما واقعاً نیاز دارد را به `android/app/src/main/AndroidManifest.xml` اضافه کنید. این کار از flag شدن توسط Google Play، بازار و مایکت جلوگیری می‌کند.

```xml
<!-- برای همه انواع نوتیفیکیشن لازم است -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />  <!-- Android 13+ -->

<!-- فقط اگر از startForegroundService() استفاده می‌کنید -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />

<!-- فقط اگر از startNotificationPolling() استفاده می‌کنید -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

<!-- فقط اگر از scheduleNotification() استفاده می‌کنید -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />

<!-- اختیاری -->
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
```

همچنین تگ `<activity>` را به‌روزرسانی کنید:

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:enableOnBackInvokedCallback="true"
    ...>
```

---

### 🍎 iOS

#### ۱. Podfile

```ruby
platform :ios, '14.0'
```

```bash
cd ios && pod install && cd ..
```

#### ۲. Info.plist

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
    <string>processing</string>
</array>

<!-- مقدار ثابت است — با $(PRODUCT_BUNDLE_IDENTIFIER) جایگزین نکنید -->
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.example.notification_master.polling</string>
</array>

<key>NSUserNotificationUsageDescription</key>
<string>این اپ برای اطلاع‌رسانی به شما نوتیفیکیشن ارسال می‌کند.</string>
```

#### ۳. AppDelegate.swift

```swift
import Flutter
import UIKit
import notification_master
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UNUserNotificationCenterDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    NotificationMasterPlugin.registerBackgroundTask()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // نمایش نوتیفیکیشن هنگام باز بودن اپ
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound, .badge])
  }

  // مدیریت کلیک روی نوتیفیکیشن
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    completionHandler()
  }
}
```

> ⚠️ **مشکل رایج:** اگر خطای CocoaPods مربوط به deployment target دریافت کردید، [IOS_DEPLOYMENT_TARGET_FIX_FA.md](IOS_DEPLOYMENT_TARGET_FIX_FA.md) را ببینید.
> 📖 **راهنمای کامل iOS:** [IOS_SETUP_FA.md](IOS_SETUP_FA.md)

---

### 🖥️ macOS

#### ۱. Entitlements

در **هر دو** فایل `DebugProfile.entitlements` و `Release.entitlements` اضافه کنید:

```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.usernotifications</key>
<true/>
```

#### ۲. Info.plist

```xml
<key>NSUserNotificationUsageDescription</key>
<string>این اپ برای اطلاع‌رسانی به شما نوتیفیکیشن ارسال می‌کند.</string>
```

#### ۳. AppDelegate.swift

```swift
import Cocoa
import FlutterMacOS
import UserNotifications

@main
class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {

  override func applicationDidFinishLaunching(_ notification: Notification) {
    UNUserNotificationCenter.current().delegate = self
    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  // نمایش نوتیفیکیشن هنگام باز بودن اپ
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound, .badge])
  }

  // مدیریت کلیک روی نوتیفیکیشن
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    completionHandler()
  }
}
```

> نیازی به `import notification_master` یا `registerBackgroundTask()` در macOS نیست.

---

### 🪟 Windows

نیازی به تنظیم اضافه نیست. پلاگین به‌صورت خودکار پلتفرم را شناسایی می‌کند.

**ویژگی‌های پشتیبانی‌شده:**
- ۷ نوع نوتیفیکیشن (Simple، Big Text، Image، Actions، Styled، Heads-Up، Full Screen)
- سناریوهای Alarm و IncomingCall با صدای حلقه‌ای
- دکمه‌های Action، attribution text، پشتیبانی از تصویر
- یکپارچگی با Windows Action Center (ویندوز ۱۰/۱۱)

📖 **راهنمای کامل ویندوز:** [WINDOWS_NOTIFICATIONS_GUIDE.md](WINDOWS_NOTIFICATIONS_GUIDE.md)

---

### 🐧 Linux

یک‌بار روی ماشین build نصب کنید:

```bash
# Ubuntu / Debian
sudo apt-get install libnotify-dev libcurl4-openssl-dev libjson-glib-dev

# Fedora / RHEL
sudo dnf install libnotify-devel libcurl-devel json-glib-devel

# Arch
sudo pacman -S libnotify curl json-glib
```

نیازی به تغییر فایل‌های پروژه نیست. باینری daemon هنگام `flutter build linux` به‌صورت خودکار کامپایل می‌شود.

---

### 🌐 Web

نیازی به تنظیم اضافه نیست. پلاگین از **Browser Notification API** استفاده می‌کند.

> ⚠️ به Chrome، Firefox یا Edge نیاز دارد. Safari پشتیبانی محدود دارد. Background polling در Web موجود نیست.

---

## استفاده پایه

```dart
import 'package:notification_master/notification_master.dart';

final nm = NotificationMaster();

// بررسی و درخواست permission
final granted = await nm.checkNotificationPermission();
if (!granted) await nm.requestNotificationPermission();

// نمایش نوتیفیکیشن
await nm.showNotification(
  title: 'سلام',
  message: 'یک پیام جدید دارید',
);
```

---

## متدهای نوتیفیکیشن

### `showNotification()`

نوتیفیکیشن پایه برای همه پلتفرم‌ها.

```dart
// ساده‌ترین حالت
await nm.showNotification(
  title: 'خوش آمدید',
  message: 'اپلیکیشن شما آماده است',
);

// با همه گزینه‌ها
await nm.showNotification(
  id: 42,
  title: 'سفارش تایید شد',
  message: 'سفارش شماره ۴۲ تایید شد',
  channelId: 'orders',
  importance: NotificationImportance.high,
  autoCancel: true,
  targetScreen: '/orders',
  extraData: {'orderId': '42'},
);
```

---

### `showStyledNotification()` ⭐

آیکون اپ را در سمت چپ نمایش می‌دهد با متن کامل پیام. در Android توصیه می‌شود به جای `showNotification()` استفاده شود.

```dart
await nm.showStyledNotification(
  title: 'به‌روزرسانی جدید',
  message: 'نسخه ۲.۰ با ویژگی‌های جدید در دسترس است',
  channelId: 'updates',
);
```

---

### `showBigTextNotification()`

نوتیفیکیشن قابل گسترش با متن طولانی.

```dart
await nm.showBigTextNotification(
  title: 'خبرنامه',
  message: 'خلاصه خبر اینجاست',
  bigText: 'این متن کامل و طولانی است که بعد از باز کردن نوتیفیکیشن نمایش داده می‌شود...',
  importance: NotificationImportance.defaultImportance,
);
```

---

### `showImageNotification()`

نوتیفیکیشن با تصویر بارگذاری‌شده از URL.

```dart
await nm.showImageNotification(
  title: 'عکس جدید',
  message: 'دوستت عکس فرستاد',
  imageUrl: 'https://example.com/image.jpg',
  channelId: 'media',
);
```

---

### `showNotificationWithActions()`

نوتیفیکیشن با دکمه‌های Action قابل کلیک.

```dart
await nm.showNotificationWithActions(
  title: 'تماس ورودی',
  message: 'علی در حال تماس است',
  actions: [
    {'title': 'پاسخ', 'route': '/call/answer'},
    {'title': 'رد کردن', 'route': '/call/decline'},
  ],
);
```

---

### `showHeadsUpNotification()` ⭐

به صورت بنر از بالای صفحه ظاهر می‌شود. برای پیام‌های فوری مناسب است.

```dart
await nm.showHeadsUpNotification(
  title: '🔔 هشدار فوری',
  message: 'این نوتیفیکیشن از بالای صفحه ظاهر می‌شود',
);
```

---

### `showFullScreenNotification()` ⭐

تمام صفحه را می‌گیرد — فقط برای تماس ورودی یا هشدارهای بحرانی استفاده کنید.

```dart
await nm.showFullScreenNotification(
  title: '📞 تماس ورودی',
  message: 'جان در حال تماس با شماست',
);
```

---

### سلسله مراتب نوتیفیکیشن Android

از کمترین تا بیشترین مزاحمت:

| نوع | محل نمایش |
|-----|-----------|
| `showNotification()` | فقط نوار اعلان |
| `showStyledNotification()` | نوار اعلان با آیکون اپ |
| `showHeadsUpNotification()` | بنر از بالای صفحه |
| `showFullScreenNotification()` | تمام صفحه (تماس / آلارم) |

---

### `createCustomChannel()`

ساخت کانال نوتیفیکیشن سفارشی در Android (نسخه ۸.۰ به بالا). باید قبل از ارسال نوتیفیکیشن به آن کانال فراخوانی شود.

```dart
await nm.createCustomChannel(
  channelId: 'order_updates',
  channelName: 'به‌روزرسانی سفارش',
  channelDescription: 'نوتیفیکیشن‌های مربوط به سفارش‌ها',
  importance: NotificationImportance.high,
  enableLights: true,
  lightColor: 0xFF00FF00,
  enableVibration: true,
  enableSound: true,
);

// سپس از channelId استفاده کنید
await nm.showStyledNotification(
  title: 'سفارش ارسال شد',
  message: 'سفارش شما از انبار خارج شد',
  channelId: 'order_updates',
);
```

---

## سطوح اهمیت

| مقدار | رفتار |
|-------|-------|
| `NotificationImportance.high` | صدا + ویبره + بنر بالا |
| `NotificationImportance.defaultImportance` | رفتار پیش‌فرض سیستم |
| `NotificationImportance.low` | بدون صدا |
| `NotificationImportance.min` | فقط نوار اعلان، بدون صدا |

---

## Firebase و Push Notification

### `setFirebaseAsActiveService()`

Firebase را به عنوان روش فعال تحویل نوتیفیکیشن علامت‌گذاری کنید.

```dart
await nm.setFirebaseAsActiveService();
```

---

### `getDeviceToken()`

بهترین توکن push موجود برای دستگاه فعلی را برمی‌گرداند. اگر `firebase_messaging` در پروژه باشد، توکن FCM را برمی‌گرداند. در غیر این صورت یک شناسه دستگاه برمی‌گرداند.

```dart
final token = await nm.getDeviceToken();
print('Token: $token');
```

| پلتفرم | Firebase موجود | Firebase نیست |
|--------|---------------|--------------|
| Android | توکن FCM (~152 کاراکتر) | Android ID (16 hex) |
| iOS | توکن APNS (hex) | UUID از `identifierForVendor` |
| macOS | — | hostname دستگاه |
| Windows | — | MachineGuid از registry |
| Linux | — | `/etc/machine-id` یا hostname |
| Web | — | UUID پایدار در localStorage |

> اگر از `firebase_messaging` استفاده می‌کنید، `FirebaseMessaging.instance.getToken()` را مستقیم صدا بزنید. `getDeviceToken()` یک wrapper راحت برای حالتی است که Firebase اختیاری باشد.

---

### `subscribeToTopic()` / `unsubscribeFromTopic()`

عضویت یا لغو عضویت از یک topic نوتیفیکیشن. با یا بدون Firebase کار می‌کند.

```dart
await nm.subscribeToTopic('news');
await nm.unsubscribeFromTopic('news');

final topics = await nm.getSubscribedTopics();
print('تاپیک‌های فعال: $topics');
```

**با Firebase:** از `FirebaseMessaging.subscribeToTopic()` استفاده کرده و cache محلی هم نگه می‌دارد.
**بدون Firebase:** در SharedPreferences / UserDefaults محلی ذخیره می‌کند — باید با سرور خودتان sync کنید.

---

## مدیریت سرویس

در هر لحظه فقط یک سرویس پس‌زمینه می‌تواند فعال باشد. شروع سرویس جدید به‌صورت خودکار سرویس قبلی را متوقف می‌کند.

| سرویس | متد | مصرف باتری | قابلیت اطمینان | مناسب برای |
|-------|-----|------------|---------------|-----------|
| Polling | `startNotificationPolling()` | کم | متوسط | بررسی دوره‌ای (هر ۱۵+ دقیقه) |
| Foreground Service | `startForegroundService()` | زیاد | بالا | لحظه‌ای مداوم (فقط Android) |
| Firebase | `setFirebaseAsActiveService()` | خیلی کم | خیلی بالا | push از سرور |

```dart
// بررسی سرویس فعال
final service = await nm.getActiveNotificationService();
print('فعال: $service'); // "polling"، "foreground"، "firebase" یا "none"

// توقف همه
await nm.stopNotificationPolling();
await nm.stopForegroundService();
```

---

## مثال‌های کامل

### مثال ۱ — Firebase Push Notification

این مثال نشان می‌دهد چطور از Firebase Cloud Messaging (FCM) با این پلاگین برای دریافت نوتیفیکیشن‌های ارسالی از سرور استفاده کنید.

**پیش‌نیاز:** پکیج‌های `firebase_messaging` و `firebase_core` را به `pubspec.yaml` اضافه کنید و راه‌اندازی پروژه Firebase را کامل کنید (google-services.json / GoogleService-Info.plist).

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:notification_master/notification_master.dart';

// هندلر پیام پس‌زمینه — باید یک تابع سطح بالا (top-level) باشد
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final nm = NotificationMaster();
  await nm.showStyledNotification(
    title: message.notification?.title ?? 'پیام جدید',
    message: message.notification?.body ?? '',
    channelId: 'fcm_channel',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: FirebaseDemoPage());
  }
}

class FirebaseDemoPage extends StatefulWidget {
  const FirebaseDemoPage({super.key});
  @override
  State<FirebaseDemoPage> createState() => _FirebaseDemoPageState();
}

class _FirebaseDemoPageState extends State<FirebaseDemoPage> {
  final _nm = NotificationMaster();
  String _token = '';
  String _status = '';

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    // ۱. درخواست permission
    final granted = await _nm.checkNotificationPermission();
    if (!granted) await _nm.requestNotificationPermission();

    // ۲. ساخت کانال برای پیام‌های FCM (Android)
    await _nm.createCustomChannel(
      channelId: 'fcm_channel',
      channelName: 'پیام‌های Push',
      channelDescription: 'نوتیفیکیشن‌های Firebase Cloud Messaging',
      importance: NotificationImportance.high,
      enableVibration: true,
      enableSound: true,
    );

    // ۳. Firebase را به عنوان سرویس فعال علامت‌گذاری کنید
    await _nm.setFirebaseAsActiveService();

    // ۴. توکن FCM را برای ارسال به سرور دریافت کنید
    final token = await _nm.getDeviceToken();
    setState(() => _token = token ?? 'در دسترس نیست');

    // ۵. عضویت در topic
    await _nm.subscribeToTopic('all_users');

    // ۶. مدیریت پیام‌های foreground
    FirebaseMessaging.onMessage.listen((message) {
      _nm.showStyledNotification(
        title: message.notification?.title ?? 'پیام جدید',
        message: message.notification?.body ?? '',
        channelId: 'fcm_channel',
      );
    });

    // ۷. مدیریت کلیک روی نوتیفیکیشن در حالت background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final route = message.data['route'];
      if (route != null) {
        Navigator.of(context).pushNamed(route);
      }
    });

    setState(() => _status = 'Firebase آماده است');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دمو Firebase Push')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('وضعیت: $_status'),
            const SizedBox(height: 12),
            Text(
              'توکن FCM:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SelectableText(_token, style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                // تست: نمایش یک نوتیفیکیشن محلی
                await _nm.showStyledNotification(
                  title: 'نوتیفیکیشن تست',
                  message: 'این یک شبیه‌سازی پیام Firebase است',
                  channelId: 'fcm_channel',
                );
              },
              child: const Text('تست نوتیفیکیشن محلی'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final topics = await _nm.getSubscribedTopics();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تاپیک‌ها: $topics')),
                );
              },
              child: const Text('نمایش تاپیک‌های فعال'),
            ),
            const SizedBox(height: 16),
            // ارسال از سرور با FCM HTTP v1 API:
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade100,
              child: const Text(
                'ارسال از سرور شما:\n'
                'POST https://fcm.googleapis.com/v1/projects/{id}/messages:send\n'
                '{\n'
                '  "message": {\n'
                '    "token": "<device_token>",\n'
                '    "notification": { "title": "سلام", "body": "پیام جدید" },\n'
                '    "data": { "route": "/home" }\n'
                '  }\n'
                '}',
                style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### مثال ۲ — HTTP Polling (بدون Firebase)

این مثال نشان می‌دهد چطور سرور خودتان را برای نوتیفیکیشن poll کنید — بدون نیاز به Firebase.

**نحوه کار:** پلاگین به‌صورت دوره‌ای endpoint API شما را صدا می‌زند. وقتی سرور نوتیفیکیشن جدید دارد، آن‌ها را به صورت JSON برمی‌گرداند و پلاگین آن‌ها را به‌صورت محلی نمایش می‌دهد.

**فرمت JSON سرور:**

```json
{
  "notifications": [
    {
      "id": 1,
      "title": "پیام جدید",
      "message": "۳ پیام خوانده‌نشده دارید",
      "imageUrl": "https://example.com/avatar.png",
      "bigText": "متن گسترش‌یافته اختیاری",
      "importance": "high",
      "channelId": "messages"
    }
  ]
}
```

وقتی چیز جدیدی نیست `"notifications": []` برگردانید — پلاگین بی‌صدا skip می‌کند.

```dart
import 'package:flutter/material.dart';
import 'package:notification_master/notification_master.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: PollingDemoPage());
  }
}

class PollingDemoPage extends StatefulWidget {
  const PollingDemoPage({super.key});
  @override
  State<PollingDemoPage> createState() => _PollingDemoPageState();
}

class _PollingDemoPageState extends State<PollingDemoPage> {
  final _nm = NotificationMaster();
  String _activeService = 'none';

  // آدرس endpoint واقعی سرور خود را بنویسید
  static const _pollingUrl = 'https://your-server.com/api/notifications';

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    // ۱. درخواست permission
    final granted = await _nm.checkNotificationPermission();
    if (!granted) await _nm.requestNotificationPermission();

    // ۲. ساخت کانال (Android)
    await _nm.createCustomChannel(
      channelId: 'polling_channel',
      channelName: 'نوتیفیکیشن‌های Polling',
      channelDescription: 'نوتیفیکیشن‌های دریافتی از سرور',
      importance: NotificationImportance.high,
      enableVibration: true,
      enableSound: true,
    );

    // ۳. بررسی سرویس فعال
    final service = await _nm.getActiveNotificationService();
    setState(() => _activeService = service);
  }

  // گزینه الف: WorkManager / BGTaskScheduler (باتری‌دوست، ممکن است OS محدود کند)
  Future<void> _startPolling() async {
    await _nm.startNotificationPolling(
      pollingUrl: _pollingUrl,
      intervalMinutes: 15, // حداقل WorkManager / BGTaskScheduler
    );
    final s = await _nm.getActiveNotificationService();
    setState(() => _activeService = s);
  }

  // گزینه ب: Foreground Service (فقط Android — پایدار، بدون محدودیت)
  Future<void> _startForegroundService() async {
    await _nm.startForegroundService(
      pollingUrl: _pollingUrl,
      intervalMinutes: 1,
      channelId: 'polling_channel',
      channelName: 'سرویس Polling',
      channelDescription: 'سرویس polling پس‌زمینه',
      importance: NotificationImportance.low,
      enableVibration: false,
      enableSound: false,
    );
    final s = await _nm.getActiveNotificationService();
    setState(() => _activeService = s);
  }

  // گزینه ج: Background Daemon (Windows / Linux / macOS — بعد از بسته شدن اپ هم کار می‌کند)
  Future<void> _startDaemon() async {
    final ok = await _nm.startBackgroundPollingService(
      pollingUrl: _pollingUrl,
      intervalMinutes: 1,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('باینری daemon پیدا نشد. ابتدا flutter build را اجرا کنید.'),
        ),
      );
      return;
    }
    final s = await _nm.getActiveNotificationService();
    setState(() => _activeService = s);
  }

  Future<void> _stopAll() async {
    await _nm.stopNotificationPolling();
    await _nm.stopForegroundService();
    await _nm.stopBackgroundPollingService();
    final s = await _nm.getActiveNotificationService();
    setState(() => _activeService = s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دمو HTTP Polling')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: _activeService == 'none'
                  ? Colors.grey.shade200
                  : Colors.green.shade100,
              child: Text(
                'سرویس فعال: $_activeService',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Android — WorkManager (باتری‌دوست):'),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: _startPolling,
              child: const Text('شروع Polling (هر ۱۵ دقیقه)'),
            ),
            const SizedBox(height: 12),
            const Text('Android — Foreground Service (پایدار):'),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: _startForegroundService,
              child: const Text('شروع Foreground Service (هر ۱ دقیقه)'),
            ),
            const SizedBox(height: 12),
            const Text('Windows / Linux / macOS — Background Daemon:'),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: _startDaemon,
              child: const Text('شروع Background Daemon (هر ۱ دقیقه)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: _stopAll,
              child: const Text(
                'توقف همه',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'نکات پلتفرم:\n'
              '• Android WorkManager: حداقل ~۱۵ دقیقه، OS ممکن است بیشتر تاخیر بدهد\n'
              '• Android ForegroundService: نوتیفیکیشن دائمی نشان می‌دهد، بدون تاخیر\n'
              '• iOS: BGTaskScheduler حداقل ~۱۵ دقیقه، زمان‌بندی دقیق با OS است\n'
              '• macOS/Windows/Linux daemon: بعد از بسته شدن اپ هم کار می‌کند',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## ویژگی‌های پیشرفته Windows: ۷ نوع نوتیفیکیشن

```dart
// Styled (حرفه‌ای، با attribution text)
await nm.showStyledNotification(
  title: 'یادآوری جلسه',
  message: 'جلسه تیم ۱۵ دقیقه دیگر شروع می‌شود',
);

// Heads-Up / Alarm (صدای آلارم حلقه‌ای، باقی می‌ماند)
await nm.showHeadsUpNotification(
  title: '⏰ هشدار تایمر',
  message: 'تایمر ۵ دقیقه‌ای شما تمام شد',
);

// Full Screen / IncomingCall (صدای زنگ حلقه‌ای)
await nm.showFullScreenNotification(
  title: '📞 تماس ورودی',
  message: 'جان دو در حال تماس با شماست...',
);
```

📚 همه ۷ نوع با گزینه‌های صدا: **[WINDOWS_NOTIFICATIONS_GUIDE.md](WINDOWS_NOTIFICATIONS_GUIDE.md)**

---

## رفع مشکلات

**کانال سفارشی صدا ندارد** — مطمئن شوید هنگام `createCustomChannel()` مقدار `enableSound: true` را تنظیم کرده‌اید.

**آیکون اپ در نوتیفیکیشن نیست** — به جای `showNotification()` از `showStyledNotification()` استفاده کنید.

**نوتیفیکیشن در Android 13+ نمایش داده نمی‌شود** — قبل از هر نوتیفیکیشنی `requestNotificationPermission()` را صدا بزنید.

**Polling در iOS اجرا نمی‌شود** — iOS BGTaskScheduler بر اساس صلاحدید OS اجرا می‌شود (حداقل ~۱۵ دقیقه). این رفتار طبیعی است.

**Daemon در Windows شروع نمی‌شود** — ابتدا `flutter build windows` را اجرا کنید تا باینری `notification_master_poller.exe` کنار اپ شما ساخته شود.

---

## نکات مهم

- پلاگین permission های Android را به‌صورت خودکار اعلام **نمی‌کند**. فقط آنچه واقعاً نیاز دارید را اضافه کنید.
- Foreground Service فقط در Android موجود است. در دسکتاپ از background daemon استفاده کنید.
- Background polling در Web موجود نیست.
- کانال‌ها فقط در Android 8.0+ مؤثرند؛ در جاهای دیگر نادیده گرفته می‌شوند.
- iOS نیاز به iOS 14.0+ دارد.
- Polling در macOS از یک `Timer` داخلی استفاده می‌کند — با بسته شدن اپ متوقف می‌شود. برای حالت daemon از `startBackgroundPollingService()` استفاده کنید.

---

## لایسنس

MIT License — برای جزئیات فایل [LICENSE](LICENSE) را ببینید.
