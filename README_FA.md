# Notification Master

یک پلاگین جامع Flutter برای مدیریت نوتیفیکیشن در تمام پلتفرم‌ها.

## پشتیبانی پلتفرم‌ها

| Platform | Support | ویژگی‌ها |
|----------|---------|----------|
| Android  | ✅ | نوتیفیکیشن محلی، کانال سفارشی، HTTP polling، Foreground Service |
| iOS      | ✅ | نوتیفیکیشن محلی، صدای سفارشی، Badge، HTTP polling |
| macOS    | ✅ | نوتیفیکیشن native، HTTP polling |
| Windows  | ✅ | Toast notification، HTTP polling |
| Web      | ✅ | Browser Notification API، مدیریت Permission |
| Linux    | ✅ | Desktop notification، HTTP polling |

---

## نصب

در فایل `pubspec.yaml`:

```yaml
dependencies:
  notification_master: ^0.0.7
```

```bash
flutter pub get
```

---

## راه‌اندازی پلتفرم‌ها

### 🤖 Android

در فایل `android/app/src/main/AndroidManifest.xml` داخل تگ `<manifest>` اضافه کنید:

```xml
<!-- اینترنت برای HTTP polling -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- برای Android 13+ (API 33+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- برای Foreground Service -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />

<!-- برای اجرا بعد از ریستارت دستگاه -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

همچنین در تگ `<activity>` اضافه کنید:

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

مطمئن شوید `ios/Podfile` با این خط شروع می‌شود:

```ruby
platform :ios, '14.0'
```

بعد از تغییر اجرا کنید:

```bash
cd ios
pod install
cd ..
```

#### ۲. Info.plist

در فایل `ios/Runner/Info.plist` داخل تگ `<dict>` اضافه کنید:

```xml
<!-- حالت‌های اجرا در پس‌زمینه -->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
    <string>processing</string>
</array>

<!-- شناسه ثابت task پس‌زمینه — همین مقدار را بنویسید، تغییر ندهید -->
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.example.notification_master.polling</string>
</array>

<!-- توضیح دلیل ارسال نوتیفیکیشن -->
<key>NSUserNotificationUsageDescription</key>
<string>این اپ برای اطلاع‌رسانی به شما نوتیفیکیشن ارسال می‌کند.</string>
```

> ⚠️ **مهم:** مقدار `com.example.notification_master.polling` یک رشته ثابت است که در کد Swift پلاگین هاردکد شده. آن را با `$(PRODUCT_BUNDLE_IDENTIFIER)` جایگزین **نکنید** — وگرنه background task ثبت نخواهد شد.

#### ۳. AppDelegate.swift

محتوای `ios/Runner/AppDelegate.swift` را با این کد جایگزین کنید:

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
    // ضروری: نمایش نوتیفیکیشن هنگام باز بودن اپ
    UNUserNotificationCenter.current().delegate = self

    // ضروری: ثبت task پس‌زمینه
    NotificationMasterPlugin.registerBackgroundTask()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // نمایش نوتیفیکیشن در حالت foreground
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

**چرا این موارد ضروری هستند:**
- `import notification_master` — برای صدا زدن `NotificationMasterPlugin.registerBackgroundTask()` لازم است
- `UNUserNotificationCenterDelegate` — برای نمایش نوتیفیکیشن هنگام باز بودن اپ ضروری است
- `registerBackgroundTask()` — task پس‌زمینه را با iOS ثبت می‌کند
- بدون `willPresent`، نوتیفیکیشن‌ها هنگام باز بودن اپ بی‌صدا حذف می‌شوند

**⚠️ مشکل رایج - خطای Deployment Target:**
اگر خطای CocoaPods مربوط به deployment target دریافت کردید:
- فارسی: [IOS_DEPLOYMENT_TARGET_FIX_FA.md](IOS_DEPLOYMENT_TARGET_FIX_FA.md)
- English: [IOS_DEPLOYMENT_TARGET_FIX.md](IOS_DEPLOYMENT_TARGET_FIX.md)

**📖 راهنمای کامل راه‌اندازی iOS:**
- فارسی: [IOS_SETUP_FA.md](IOS_SETUP_FA.md)
- English: [IOS_SETUP.md](IOS_SETUP.md)

---

### 🌐 Web

نیازی به تنظیم اضافه نیست. پلاگین از **Browser Notification API** استفاده می‌کند.  
⚠️ مرورگر باید از Notification API پشتیبانی کند (Chrome، Firefox، Edge).

---

### 🖥️ macOS

#### ۱. Entitlements

در **هر دو** فایل `macos/Runner/DebugProfile.entitlements` و `macos/Runner/Release.entitlements` اضافه کنید:

```xml
<!-- دسترسی به شبکه برای HTTP polling -->
<key>com.apple.security.network.client</key>
<true/>

<!-- نمایش نوتیفیکیشن محلی در sandbox مک -->
<key>com.apple.security.usernotifications</key>
<true/>
```

#### ۲. Info.plist

در فایل `macos/Runner/Info.plist` داخل تگ `<dict>` اضافه کنید:

```xml
<!-- شناسه ثابت task پس‌زمینه — همین مقدار را بنویسید، تغییر ندهید -->
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.example.notification_master.polling</string>
</array>

<!-- توضیح دلیل ارسال نوتیفیکیشن -->
<key>NSUserNotificationUsageDescription</key>
<string>این اپ برای اطلاع‌رسانی به شما نوتیفیکیشن ارسال می‌کند.</string>
```

#### ۳. AppDelegate.swift

محتوای `macos/Runner/AppDelegate.swift` را با این کد جایگزین کنید:

```swift
import Cocoa
import FlutterMacOS
import notification_master
import UserNotifications

@main
class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    // ضروری: نمایش نوتیفیکیشن هنگام باز بودن اپ
    UNUserNotificationCenter.current().delegate = self

    // ضروری: ثبت task پس‌زمینه
    NotificationMasterPlugin.registerBackgroundTask()

    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  // نمایش نوتیفیکیشن در حالت foreground
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

---

### 🪟 Windows / 🐧 Linux

نیازی به تنظیم اضافه نیست. پلاگین به‌صورت خودکار شناسایی می‌کند.

---

## استفاده پایه

### ایمپورت

```dart
import 'package:notification_master/notification_master.dart';
```

---

## متدها و مثال‌ها

### `checkNotificationPermission()`

بررسی وضعیت Permission نوتیفیکیشن.

```dart
final notificationMaster = NotificationMaster();

bool hasPermission = await notificationMaster.checkNotificationPermission();
print('Permission granted: $hasPermission');
```

---

### `requestNotificationPermission()`

درخواست Permission از کاربر (لازم برای Android 13+ و iOS و Web).

```dart
final granted = await notificationMaster.requestNotificationPermission();
if (!granted) {
  print('کاربر Permission رد کرد');
}
```

---

### `showNotification()`

نمایش یک نوتیفیکیشن ساده.

**پارامترها:**
- `id` (اختیاری): شناسه منحصربه‌فرد نوتیفیکیشن
- `title` (اجباری): عنوان
- `message` (اجباری): متن
- `channelId`: شناسه کانال (Android)
- `importance`: سطح اهمیت
- `autoCancel`: بسته شدن خودکار بعد از لمس
- `targetScreen`: مسیر صفحه برای navigation
- `extraData`: داده اضافه

```dart
// ساده‌ترین حالت
await notificationMaster.showNotification(
  title: 'خوش آمدید',
  message: 'اپلیکیشن شما آماده است',
);

// با ID سفارشی
await notificationMaster.showNotification(
  id: 42,
  title: 'سفارش تایید شد',
  message: 'سفارش شماره ۴۲ تایید شد',
);

// با اهمیت بالا
await notificationMaster.showNotification(
  title: 'هشدار!',
  message: 'باتری رو به اتمام است',
  importance: NotificationImportance.high,
);

// با navigation به صفحه خاص
await notificationMaster.showNotification(
  title: 'پیام جدید',
  message: 'یک پیام جدید دارید',
  targetScreen: '/messages',
  extraData: {'messageId': '123'},
);

// نوتیفیکیشن پایدار (بدون auto-cancel)
await notificationMaster.showNotification(
  title: 'در حال دانلود...',
  message: 'فایل در حال دانلود است',
  autoCancel: false,
);
```

---

### `showStyledNotification()` ⭐ جدید

نمایش نوتیفیکیشن استایل‌دار با آیکون اپلیکیشن و متن کامل (مثل نوتیفیکیشن‌های مدرن Android).

**ویژگی‌ها:**
- آیکون اپلیکیشن در سمت چپ نمایش داده می‌شود
- متن کامل پیام نشان داده می‌شود
- صدا و ویبره فعال است
- زمان نمایش داده می‌شود

```dart
await notificationMaster.showStyledNotification(
  title: 'به‌روزرسانی جدید موجود است',
  message: 'نسخه ۲.۰ با ویژگی‌ها و بهبودهای جدید در دسترس است',
  channelId: 'updates', // اختیاری
);
```

---

### `showHeadsUpNotification()` ⭐ جدید

نمایش نوتیفیکیشن heads-up که از بالای صفحه با padding ظاهر می‌شود.

**ویژگی‌ها:**
- از بالای صفحه ظاهر می‌شود
- padding اطراف آن دارد
- استایل UI سفارشی
- برای پیام‌های فوری عالی است

```dart
await notificationMaster.showHeadsUpNotification(
  title: '🔔 هشدار فوری',
  message: 'این نوتیفیکیشن از بالای صفحه ظاهر می‌شود',
);
```

---

### `showFullScreenNotification()` ⭐ جدید

نمایش نوتیفیکیشن تمام صفحه (بیشترین مزاحمت، مثل تماس ورودی).

**ویژگی‌ها:**
- تمام صفحه را می‌گیرد
- برای هشدارهای بسیار مهم استفاده می‌شود
- شبیه نوتیفیکیشن تماس ورودی

```dart
await notificationMaster.showFullScreenNotification(
  title: '📞 تماس ورودی',
  message: 'جان در حال تماس با شماست',
);
```

---

### `showBigTextNotification()`

نوتیفیکیشن با متن طولانی (expandable).

```dart
await notificationMaster.showBigTextNotification(
  title: 'خبر مهم',
  message: 'خلاصه خبر اینجاست',
  bigText: 'این متن کامل و طولانی خبر است که بعد از باز کردن نوتیفیکیشن '
           'نمایش داده می‌شود و می‌تواند چندین پاراگراف باشد...',
  importance: NotificationImportance.defaultImportance,
);
```

---

### `showImageNotification()`

نوتیفیکیشن با تصویر.

```dart
await notificationMaster.showImageNotification(
  title: 'عکس جدید',
  message: 'یک دوست عکسی برای شما فرستاد',
  imageUrl: 'https://example.com/image.jpg',
  channelId: 'media_channel',
);
```

---

### `showNotificationWithActions()`

نوتیفیکیشن با دکمه‌های Action.

```dart
await notificationMaster.showNotificationWithActions(
  title: 'تماس ورودی',
  message: 'علی در حال تماس است',
  actions: [
    {'title': 'پاسخ', 'route': '/call/answer'},
    {'title': 'رد کردن', 'route': '/call/reject'},
  ],
);
```

---

### `createCustomChannel()`

ساخت کانال سفارشی (Android 8.0+).

**مهم:** کانال‌های سفارشی حالا به درستی از صدا، ویبره و چراغ پشتیبانی می‌کنند!

```dart
await notificationMaster.createCustomChannel(
  channelId: 'order_updates',
  channelName: 'به‌روزرسانی سفارش',
  channelDescription: 'نوتیفیکیشن‌های مربوط به وضعیت سفارش',
  importance: NotificationImportance.high,
  enableLights: true,
  lightColor: 0xFF00FF00,
  enableVibration: true,
  enableSound: true, // ✅ صدا حالا کار می‌کنه!
);

// سپس از channelId در نوتیفیکیشن استایل‌دار استفاده کنید:
await notificationMaster.showStyledNotification(
  title: 'سفارش ارسال شد',
  message: 'سفارش شما از انبار خارج شد و در راه است',
  channelId: 'order_updates',
);
```

---

## انواع نوتیفیکیشن Android

### نوتیفیکیشن معمولی در مقابل استایل‌دار

**نوتیفیکیشن معمولی:**
- نوتیفیکیشن پایه بدون آیکون اپلیکیشن
- متن ممکن است کوتاه شود
- استایل حداقلی

**نوتیفیکیشن استایل‌دار (توصیه می‌شود):** ⭐
- آیکون اپلیکیشن در سمت چپ نمایش داده می‌شود
- متن کامل نشان داده می‌شود
- زمان نمایش داده می‌شود
- ظاهر بصری بهتر

```dart
// برای تجربه کاربری بهتر از نوتیفیکیشن استایل‌دار استفاده کنید
await notificationMaster.showStyledNotification(
  title: 'پیام جدید',
  message: 'شما یک پیام جدید از جان دریافت کرده‌اید',
);
```

### سلسله مراتب نوتیفیکیشن (بر اساس مزاحمت)

1. **نوتیفیکیشن معمولی** - فقط در نوار اعلان ظاهر می‌شود
2. **نوتیفیکیشن استایل‌دار** - در نوار اعلان با آیکون اپلیکیشن ظاهر می‌شود
3. **Heads-Up Notification** - از بالای صفحه با padding ظاهر می‌شود
4. **Full Screen Notification** - تمام صفحه را می‌گیرد (مثل تماس)

---

## رفع مشکلات

### کانال سفارشی صدا نداره
✅ **حل شد!** کانال‌های سفارشی حالا به درستی از صدا پشتیبانی می‌کنند. مطمئن شوید هنگام ساخت کانال `enableSound: true` را تنظیم کنید.

### آیکون اپلیکیشن در نوتیفیکیشن نمایش داده نمیشه
✅ **حل شد!** به جای `showNotification()` از `showStyledNotification()` استفاده کنید تا آیکون اپلیکیشن نمایش داده شود.

### نوتیفیکیشن نمایش داده نمیشه
- بررسی کنید که Permission داده شده باشد (Android 13+)
- تایید کنید که کانال قبل از ارسال نوتیفیکیشن ساخته شده باشد
- Logcat را برای پیام‌های خطا بررسی کنید (فیلتر با "NotificationHelper")

---

### `startNotificationPolling()`

شروع polling دوره‌ای از یک URL برای دریافت نوتیفیکیشن.

فرمت JSON پاسخ سرور:

```json
{
  "notifications": [
    {
      "id": 1,
      "title": "عنوان",
      "message": "متن نوتیفیکیشن",
      "imageUrl": "https://...",
      "bigText": "متن بلند...",
      "importance": "high",
      "channelId": "my_channel"
    }
  ]
}
```

```dart
await notificationMaster.startNotificationPolling(
  pollingUrl: 'https://api.example.com/notifications',
  intervalMinutes: 15,
);
```

---

### `stopNotificationPolling()`

توقف polling.

```dart
await notificationMaster.stopNotificationPolling();
```

---

### `startForegroundService()`

شروع Foreground Service برای polling مداوم (Android).

```dart
await notificationMaster.startForegroundService(
  pollingUrl: 'https://api.example.com/notifications',
  intervalMinutes: 10,
  channelId: 'service_channel',
  channelName: 'سرویس نوتیفیکیشن',
  channelDescription: 'سرویس پس‌زمینه برای دریافت نوتیفیکیشن',
  importance: NotificationImportance.low,
  enableVibration: false,
  enableSound: false,
);
```

---

### `stopForegroundService()`

توقف Foreground Service.

```dart
await notificationMaster.stopForegroundService();
```

---

### `setFirebaseAsActiveService()`

تنظیم Firebase Cloud Messaging به عنوان سرویس فعال.

```dart
final success = await notificationMaster.setFirebaseAsActiveService();
print('FCM فعال شد: $success');
```

---

### `getActiveNotificationService()`

دریافت نام سرویس نوتیفیکیشن فعال.

```dart
final service = await notificationMaster.getActiveNotificationService();
print('سرویس فعال: $service'); // مثلاً: "firebase" یا "none"
```

---

### `getDeviceToken()`

دریافت توکن دستگاه برای نوتیفیکیشن‌های push. توکن FCM در Android، توکن APNS در iOS، یا شناسه منحصربه‌فرد دستگاه به عنوان fallback برمی‌گرداند.

```dart
final token = await notificationMaster.getDeviceToken();
print('توکن دستگاه: $token');
```

**رفتار در هر پلتفرم:**
- **Android**: اگر Firebase Messaging در دسترس باشد توکن FCM، در غیر این صورت Android ID
- **iOS**: اگر APNS token در دسترس باشد آن را برمی‌گرداند، در غیر این صورت `identifierForVendor` UUID
- **Web/Desktop**: پشتیبانی نمی‌شود (null برمی‌گرداند)

---

### `subscribeToTopic(String topic)`

عضویت در یک موضوع (topic) نوتیفیکیشن. در Android/iOS با Firebase، این متد در FCM topic عضو می‌شود.

```dart
// عضویت در یک topic
final success = await notificationMaster.subscribeToTopic('news');
print('عضو شد: $success');

// ارسال نوتیفیکیشن به همه اعضای یک topic
// (از سرور شما): https://fcm.googleapis.com/v1/projects/{project}/messages:send
// {
//   "message": {
//     "topic": "news",
//     "notification": { "title": "خبر فوری", "body": "..." }
//   }
// }
```

**رفتار در هر پلتفرم:**
- **Android**: از Firebase Messaging `subscribeToTopic()` استفاده می‌کند (اگر در دسترس باشد)
- **iOS**: عضویت را به صورت محلی ذخیره می‌کند (با Firebase برای پیام‌رسانی topic سمت سرور استفاده کنید)
- **Web/Desktop**: پشتیبانی نمی‌شود

---

### `unsubscribeFromTopic(String topic)`

لغو عضویت از یک topic نوتیفیکیشن. همیشه موفق می‌شود — با Firebase از FCM لغو می‌کند، بدون Firebase رکورد محلی را حذف می‌کند.

```dart
final success = await notificationMaster.unsubscribeFromTopic('news');
print('لغو عضویت: $success');
```

**رفتار در هر پلتفرم:**
- **Android با Firebase**: `FirebaseMessaging.getInstance().unsubscribeFromTopic()` را صدا می‌زند و لوکال هم حذف می‌کند
- **Android بدون Firebase**: از `SharedPreferences` حذف می‌کند
- **iOS**: از `UserDefaults` حذف می‌کند
- **macOS / Windows / Linux**: از storage محلی حذف می‌کند

---

### `getSubscribedTopics()`

لیست topic‌هایی که دستگاه در حال حاضر در آن‌ها عضو است را برمی‌گرداند.

```dart
final topics = await notificationMaster.getSubscribedTopics();
print('تاپیک‌های فعال: $topics'); // مثلاً: ['news', 'offers', 'alerts']
```

**رفتار در هر پلتفرم:**
- **Android با Firebase**: لیست cache شده محلی که همتای FCM است
- **همه پلتفرم‌ها بدون Firebase**: لیست ذخیره شده محلی

#### جریان کامل server-side بدون Firebase

```dart
final notificationMaster = NotificationMaster();

// ۱. دریافت شناسه دستگاه
final token = await notificationMaster.getDeviceToken();

// ۲. عضویت در topic‌ها
await notificationMaster.subscribeToTopic('news');
await notificationMaster.subscribeToTopic('offers');

// ۳. دریافت لیست topic‌های فعال
final topics = await notificationMaster.getSubscribedTopics();

// ۴. ثبت token + topic‌ها روی سرور شما
await myApi.registerDevice(token: token!, topics: topics);
// سرور شما می‌تواند نوتیفیکیشن push به همه دستگاه‌های
// عضو 'news' ارسال کند

// بعداً — لغو عضویت
await notificationMaster.unsubscribeFromTopic('offers');
final updatedTopics = await notificationMaster.getSubscribedTopics();
await myApi.updateDevice(token: token!, topics: updatedTopics);
```

---

## مدیریت سرویس نوتیفیکیشن

پلاگین یک سیستم مدیریت یکپارچه سرویس نوتیفیکیشن فراهم می‌کند که به شما اجازه می‌دهد روش تحویل نوتیفیکیشن را انتخاب کنید. فقط یک سرویس می‌تواند در هر زمان فعال باشد — شروع سرویس جدید به طور خودکار سرویس قبلی را متوقف می‌کند.

### سرویس‌های موجود

| سرویس | متد | مصرف باتری | قابلیت اطمینان | مورد استفاده |
|-------|-----|-----------|---------------|-------------|
| **Polling** | `startNotificationPolling()` | کم | متوسط | بررسی‌های دوره‌ای پس‌زمینه (هر ۱۵+ دقیقه) |
| **Foreground Service** | `startForegroundService()` | زیاد | بالا | نوتیفیکیشن‌های لحظه‌ای مداوم |
| **Firebase (FCM)** | `setFirebaseAsActiveService()` | خیلی کم | خیلی بالا | نوتیفیکیشن‌های push از سرور |

### نحوه کار

1. **انتخاب سرویس**: وقتی هر سرویس نوتیفیکیشنی را شروع می‌کنید، پلاگین نوع سرویس فعال را در SharedPreferences ذخیره کرده و هر سرویس در حال اجرای قبلی را متوقف می‌کند.

2. **تغییر خودکار**: اگر Polling را شروع کنید در حالی که Foreground Service در حال اجراست، Foreground Service به طور خودکار متوقف می‌شود.

3. **حفظ وضعیت**: وضعیت سرویس فعال در بازراهای مجدد اپ حفظ می‌شود. می‌توانید بررسی کنید کدام سرویس فعال است با `getActiveNotificationService()`.

### مثال: رابط مدیریت سرویس

```dart
class NotificationServiceManager extends StatefulWidget {
  @override
  State<NotificationServiceManager> createState() => _NotificationServiceManagerState();
}

class _NotificationServiceManagerState extends State<NotificationServiceManager> {
  final _nm = NotificationMaster();
  String _activeService = 'none';

  @override
  void initState() {
    super.initState();
    _checkActiveService();
  }

  Future<void> _checkActiveService() async {
    final service = await _nm.getActiveNotificationService();
    setState(() => _activeService = service);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // نمایشگر وضعیت
        Text('فعال: $_activeService',
          style: TextStyle(fontWeight: FontWeight.bold)),

        // گزینه Polling
        ElevatedButton(
          onPressed: () async {
            await _nm.startNotificationPolling(
              pollingUrl: 'https://api.example.com/notifications',
              intervalMinutes: 15,
            );
            _checkActiveService();
          },
          child: Text('شروع Polling'),
        ),

        // گزینه Foreground Service
        ElevatedButton(
          onPressed: () async {
            await _nm.startForegroundService(
              pollingUrl: 'https://api.example.com/notifications',
              intervalMinutes: 5,
            );
            _checkActiveService();
          },
          child: Text('شروع Foreground Service'),
        ),

        // گزینه Firebase
        ElevatedButton(
          onPressed: () async {
            await _nm.setFirebaseAsActiveService();
            _checkActiveService();
          },
          child: Text('استفاده از Firebase (FCM)'),
        ),

        // توقف همه
        ElevatedButton(
          onPressed: () async {
            await _nm.stopNotificationPolling();
            await _nm.stopForegroundService();
            _checkActiveService();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('توقف همه سرویس‌ها'),
        ),
      ],
    );
  }
}
```

### چرخه حیات سرویس

```
شروع اپ
    │
    ▼
getActiveNotificationService() → "none"
    │
    ▼
startNotificationPolling() → "polling" (Background WorkManager/BGTaskScheduler)
    │
    ▼
startForegroundService() → "foreground" (polling به طور خودکار متوقف می‌شود)
    │
    ▼
setFirebaseAsActiveService() → "firebase" (foreground service به طور خودکار متوقف می‌شود)
    │
    ▼
stopNotificationPolling() + stopForegroundService() → "none"
```

---

## استفاده از UnifiedNotificationService

این کلاس یک رابط یکپارچه برای تمام پلتفرم‌ها فراهم می‌کند.

### مقداردهی اولیه

```dart
import 'package:notification_master/src/unified_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await UnifiedNotificationService.initialize(appName: 'اپ من');
  
  runApp(MyApp());
}
```

### نمایش نوتیفیکیشن

```dart
// نوتیفیکیشن ساده
await UnifiedNotificationService.showNotification(
  title: 'سلام',
  message: 'یک پیام جدید دارید',
);

// با تصویر
await UnifiedNotificationService.showImageNotification(
  title: 'عکس جدید',
  message: 'دوستت عکس فرستاد',
  imageUrl: 'https://example.com/photo.jpg',
);

// با متن بلند
await UnifiedNotificationService.showBigTextNotification(
  title: 'خبرنامه',
  message: 'خلاصه...',
  bigText: 'متن کامل خبرنامه اینجاست...',
);

// با دکمه Action
await UnifiedNotificationService.showNotificationWithActions(
  title: 'یادآوری',
  message: 'جلسه در ۱۵ دقیقه دیگر',
  actions: ['باشه', 'بعداً یادم بیار'],
  onActionClick: (index) {
    print('کاربر روی دکمه $index کلیک کرد');
  },
);
```

### بررسی پلتفرم

```dart
print(UnifiedNotificationService.getPlatformName()); // "Android", "iOS", ...
print(UnifiedNotificationService.isDesktop); // true/false
print(UnifiedNotificationService.isMobile);  // true/false
print(UnifiedNotificationService.isWeb);     // true/false
print(UnifiedNotificationService.isInitialized); // true/false
```

---

## استفاده در Web

### تفاوت‌های مهم Web با پلتفرم‌های دیگر

| ویژگی | Mobile/Desktop | Web |
|-------|---------------|-----|
| Permission | سیستم‌عامل | مرورگر |
| Foreground Service | ✅ | ❌ |
| Background Polling | ✅ | ❌ |
| Channels | ✅ Android | ❌ (no-op) |
| Actions | ✅ | محدود |
| Image | ✅ | بستگی به مرورگر |

### مثال کامل Web

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:notification_master/notification_master.dart';

class WebNotificationHelper {
  static final _nm = NotificationMaster();

  static Future<bool> setup() async {
    if (!kIsWeb) return false;

    // بررسی support مرورگر
    final hasPermission = await _nm.checkNotificationPermission();
    if (hasPermission) return true;

    // درخواست Permission (مرورگر یک پنجره نشان می‌دهد)
    final granted = await _nm.requestNotificationPermission();
    if (!granted) {
      print('کاربر Permission رد کرد یا مرورگر پشتیبانی نمی‌کند');
      return false;
    }
    return true;
  }

  static Future<void> notify(String title, String message) async {
    if (!kIsWeb) return;
    await _nm.showNotification(title: title, message: message);
  }
}

// استفاده
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    await WebNotificationHelper.setup();
  }
  
  runApp(MyApp());
}
```

---

## مثال کامل - راه‌اندازی در اپ

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:notification_master/notification_master.dart';
import 'package:notification_master/src/unified_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UnifiedNotificationService.initialize(appName: 'اپ من');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(home: HomePage());
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _nm = NotificationMaster();

  Future<void> _init() async {
    final has = await _nm.checkNotificationPermission();
    if (!has) await _nm.requestNotificationPermission();

    // Android: ساخت کانال سفارشی
    if (!kIsWeb) {
      await _nm.createCustomChannel(
        channelId: 'main',
        channelName: 'اعلان‌های اصلی',
        importance: NotificationImportance.high,
        enableVibration: true,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('نوتیفیکیشن تست')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => _nm.showNotification(
              title: 'تست',
              message: 'این یک تست است',
              channelId: 'main',
            ),
            child: Text('نوتیفیکیشن ساده'),
          ),
          ElevatedButton(
            onPressed: () => _nm.startNotificationPolling(
              pollingUrl: 'https://api.example.com/notifications',
              intervalMinutes: 15,
            ),
            child: Text('شروع Polling'),
          ),
          ElevatedButton(
            onPressed: () => _nm.stopNotificationPolling(),
            child: Text('توقف Polling'),
          ),
        ],
      ),
    );
  }
}
```

---

## سطوح اهمیت (NotificationImportance)

| مقدار | توضیح |
|-------|-------|
| `NotificationImportance.high` | صدا + ویبره + بنر بالا |
| `NotificationImportance.defaultImportance` | رفتار پیش‌فرض |
| `NotificationImportance.low` | بدون صدا |
| `NotificationImportance.min` | فقط در نوار اعلان |

---

## نکات مهم

- **Android 13+**: حتماً `POST_NOTIFICATIONS` Permission را در Manifest و کد درخواست دهید.
- **Web**: مرورگر Safari پشتیبانی محدود دارد.
- **Foreground Service**: فقط Android پشتیبانی می‌کند.
- **Background Polling**: در Web کار نمی‌کند؛ فقط در حین باز بودن اپ polling انجام می‌شود.
- **کانال‌ها**: فقط Android 8.0+ پشتیبانی می‌کند؛ در سایر پلتفرم‌ها نادیده گرفته می‌شود.
- **آیکون اپلیکیشن**: از `showStyledNotification()` برای نمایش آیکون اپلیکیشن در نوتیفیکیشن استفاده کنید. ⭐
- **صدا**: کانال‌های سفارشی حالا به درستی با `enableSound: true` صدا پخش می‌کنند. ✅
- **iOS**: نیاز به iOS 14.0+ دارد. از iOS 14 تا iOS 26+ پشتیبانی می‌کند. 📱

---

## تغییرات نسخه جدید

### ✅ مشکلات حل شده:
1. **صدا**: کانال‌های سفارشی حالا به درستی صدای نوتیفیکیشن را پخش می‌کنند
2. **آیکون اپلیکیشن**: نوتیفیکیشن‌ها حالا آیکون اپلیکیشن را نمایش می‌دهند (از `showStyledNotification()` استفاده کنید)
3. **متن کامل**: پیام‌ها به صورت کامل و بدون کوتاه شدن نمایش داده می‌شوند
4. **لاگ‌های بهتر**: لاگ‌های جامع برای دیباگ اضافه شده‌اند
5. **iOS 14.0+**: سازگاری گسترده (iPhone 6s و جدیدتر، ~95% دستگاه‌های فعال)

### 🆕 متدهای جدید:
- `showStyledNotification()`: نوتیفیکیشن با آیکون اپلیکیشن و متن کامل (توصیه می‌شود)
- `showHeadsUpNotification()`: نوتیفیکیشن که از بالای صفحه ظاهر می‌شود
- `showFullScreenNotification()`: نوتیفیکیشن تمام صفحه برای هشدارهای فوری
- `getDeviceToken()`: دریافت توکن دستگاه برای نوتیفیکیشن‌های push (FCM/APNS)
- `subscribeToTopic()`: عضویت در یک topic نوتیفیکیشن برای ارسال هدفمند
- `unsubscribeFromTopic()`: لغو عضویت از یک topic نوتیفیکیشن

### 📚 مستندات:
- فایل `NOTIFICATION_TYPES_FA.md` را برای مستندات کامل فارسی ببینید
- شامل مثال‌ها و راهنمای رفع مشکلات

### 🔧 رفع مشکلات Build:
- macOS: خطاهای کامپایل BGTaskScheduler برطرف شد
- iOS: به iOS 14.0 deployment target تنظیم شد
- حذف وابستگی `workmanager` — polling پس‌زمینه حالا از APIهای بومی استفاده می‌کند
- برای جزئیات `BUILD_FIXES.md` را ببینید

---

## لایسنس

MIT License - برای جزئیات فایل LICENSE را ببینید.