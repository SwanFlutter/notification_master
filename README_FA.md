# Notification Master

یک پلاگین جامع Flutter برای مدیریت نوتیفیکیشن در تمام پلتفرم‌ها.

## پشتیبانی پلتفرم‌ها

| Platform | Support | ویژگی‌ها |
|----------|---------|----------|
| Android  | ✅ | نوتیفیکیشن محلی، کانال سفارشی، HTTP polling، Foreground Service |
| iOS      | ✅ | نوتیفیکیشن محلی، صدای سفارشی، Badge، HTTP polling — **[راهنما](IOS_SETUP_FA.md)** |
| macOS    | ✅ | نوتیفیکیشن native، HTTP polling، Background daemon |
| Windows  | ✅ | Toast notification، ۷ نوع، سناریوهای Alarm/Call، HTTP polling، Background daemon — **[راهنما](WINDOWS_NOTIFICATIONS_GUIDE.md)** |
| Web      | ✅ | Browser Notification API، مدیریت Permission |
| Linux    | ✅ | Desktop notification (libnotify)، HTTP polling، Background daemon |

---

## نصب

در فایل `pubspec.yaml`:

```yaml
dependencies:
  notification_master: ^1.0.0
```

```bash
flutter pub get
```

---

## راه‌اندازی پلتفرم‌ها

### 🤖 Android

> ⚠️ **مهم:** پلاگین هیچ permission ای را به‌صورت خودکار در manifest خود اعلام **نمی‌کند**.
> تمام permissionهای مورد نیاز را باید خودتان در فایل
> `android/app/src/main/AndroidManifest.xml` اضافه کنید.
> این کار باعث می‌شود مارکت‌هایی مثل Google Play، بازار و مایکت
> permissionهای حساسی که اپ شما واقعاً استفاده نمی‌کند را flag نزنند.

فقط permissionهایی که اپ شما نیاز دارد را داخل تگ `<manifest>` اضافه کنید:

```xml
<!-- ── برای همه انواع نوتیفیکیشن لازم است ──────────────────────────── -->

<!-- دسترسی به اینترنت برای HTTP polling و نوتیفیکیشن تصویری -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- Android 13+ (API 33+): باید در runtime توسط کاربر تأیید شود -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- ── فقط اگر از startForegroundService() استفاده می‌کنید ──────────── -->

<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />

<!-- ── فقط اگر از startNotificationPolling() یا FGS استفاده می‌کنید ── -->

<!-- راه‌اندازی مجدد بعد از ریستارت دستگاه -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

<!-- ── فقط اگر از scheduleNotification() استفاده می‌کنید ─────────────── -->

<!-- زمان‌بندی دقیق — Android 12+ ممکن است نیاز به تأیید کاربر در تنظیمات داشته باشد -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<!-- فقط برای اپ‌های ساعت/تقویم در Android 13+ به‌صورت خودکار اعطا می‌شود -->
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />

<!-- ── اختیاری ───────────────────────────────────────────────────────── -->

<!-- بررسی وضعیت شبکه قبل از polling -->
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- ویبره هنگام نوتیفیکیشن -->
<uses-permission android:name="android.permission.VIBRATE" />

<!-- نگه داشتن CPU بیدار حین polling -->
<uses-permission android:name="android.permission.WAKE_LOCK" />

<!-- نوتیفیکیشن‌های تمام‌صفحه / تماس ورودی (API 34+ ممکن است نیاز به تنظیم دستی داشته باشد) -->
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
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

#### راه‌اندازی HTTP Polling در اندروید

در اندروید، HTTP polling از طریق `startForegroundService()` (توصیه‌شده) یا `startNotificationPolling()` (مبتنی بر WorkManager) انجام می‌شود.

**`startForegroundService()` — سرویس foreground با نوتیفیکیشن دائمی:**

```dart
await nm.startForegroundService(
  pollingUrl: 'https://your-server.com/api/notifications',
  intervalMinutes: 1,
  channelId: 'polling_channel',
);
```

**`startNotificationPolling()` — job پس‌زمینه WorkManager (ممکن است توسط OS محدود شود):**

```dart
await nm.startNotificationPolling(
  pollingUrl: 'https://your-server.com/api/notifications',
  intervalMinutes: 15, // حداقل WorkManager
);
```

> ℹ️ متد `startBackgroundPollingService()` (daemon process) در اندروید **موجود نیست**. از `startForegroundService()` یا `startNotificationPolling()` استفاده کنید.

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

#### راه‌اندازی HTTP Polling در iOS

در iOS، HTTP polling از `BGTaskScheduler` که در `AppDelegate.swift` ثبت شده استفاده می‌کند. ستاپ در مرحله ۳ بالا این کار را انجام می‌دهد. از `startNotificationPolling()` استفاده کنید:

```dart
await nm.startNotificationPolling(
  pollingUrl: 'https://your-server.com/api/notifications',
  intervalMinutes: 15, // حداقل BGTaskScheduler حدود ۱۵ دقیقه است
);
```

برای توقف:

```dart
await nm.stopNotificationPolling();
```

> ℹ️ متد `startBackgroundPollingService()` (daemon process) در iOS **موجود نیست**. از `startNotificationPolling()` استفاده کنید که `BGAppRefreshTask` ثبت‌شده در `AppDelegate` شما را wrap می‌کند.

> ⚠️ iOS یک حداقل interval حدود ۱۵ دقیقه برای task‌های پس‌زمینه اعمال می‌کند. زمان‌بندی دقیق توسط OS بر اساس باتری، الگوی استفاده و شبکه تعیین می‌شود.

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
<!-- توضیح دلیل ارسال نوتیفیکیشن -->
<key>NSUserNotificationUsageDescription</key>
<string>این اپ برای اطلاع‌رسانی به شما نوتیفیکیشن ارسال می‌کند.</string>
```

> ℹ️ **توجه:** `BGTaskSchedulerPermittedIdentifiers` در macOS **لازم نیست**.
> پلاگین برای polling در macOS از یک `Timer` داخلی استفاده می‌کند — `BGTaskScheduler` فقط در iOS موجود است.

#### ۳. AppDelegate.swift

محتوای `macos/Runner/AppDelegate.swift` را با این کد جایگزین کنید:

```swift
import Cocoa
import FlutterMacOS
import UserNotifications

@main
class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    // ضروری: نمایش نوتیفیکیشن هنگام باز بودن اپ
    UNUserNotificationCenter.current().delegate = self
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

> ℹ️ نیازی به `import notification_master` یا `registerBackgroundTask()` در macOS نیست —
> پلاگین delegate نوتیفیکیشن را داخلی مدیریت می‌کند و از polling مبتنی بر `Timer` استفاده می‌کند.

#### راه‌اندازی HTTP Polling در مک‌اواس

مک‌اواس از **دو** حالت polling پشتیبانی می‌کند:

**حالت A — polling داخلی (اپ باید باز باشد):** از `startNotificationPolling()` استفاده کنید. یک `Timer` داخل پروسه Flutter اجرا می‌شود.

```dart
await nm.startNotificationPolling(
  pollingUrl: 'https://your-server.com/api/notifications',
  intervalMinutes: 1,
);
```

**حالت B — Background daemon (بعد از بسته شدن اپ هم کار می‌کند):** از `startBackgroundPollingService()` استفاده کنید. یک باینری Swift مستقل (`notification_master_poller`) کنار `.app` bundle اجرا می‌شود.

```dart
await nm.startBackgroundPollingService(
  pollingUrl: 'https://your-server.com/api/notifications',
  intervalMinutes: 1,
);
```

> ℹ️ باینری `notification_master_poller` هنگام `flutter build macos` به‌صورت خودکار build می‌شود و باید در همان دایرکتوری executable اپ قرار داشته باشد.

---

### 🪟 Windows / 🐧 Linux

نیازی به تنظیم اضافه نیست. پلاگین به‌صورت خودکار شناسایی می‌کند.

#### راه‌اندازی HTTP Polling در ویندوز و لینوکس

هر دو پلتفرم از **background daemon** استفاده می‌کنند — یک پروسه مستقل که بعد از بسته شدن اپ هم ادامه می‌دهد. نیازی به تنظیم اضافه در پروژه نیست؛ باینری daemon هنگام build به‌صورت خودکار ساخته و کپی می‌شود.

```dart
// شروع daemon
await nm.startBackgroundPollingService(
  pollingUrl: 'https://your-server.com/api/notifications',
  intervalMinutes: 1,
);

// توقف daemon
await nm.stopBackgroundPollingService();

// بررسی وضعیت
final running = await nm.isBackgroundPollingRunning();
```

راهنمای کامل daemon را در ادامه ببینید.

---

### 🪟 ویندوز — HTTP Polling (Background Daemon)

پولینگ در ویندوز با Android/iOS فرق دارد. به جای یک job سیستمی مانند WorkManager، پلاگین یک **پروسه مستقل** (`notification_master_poller.exe`) راه‌اندازی می‌کند که حتی بعد از بسته شدن اپ اصلی به پولینگ سرور و نمایش toast ادامه می‌دهد.

#### نحوه کار

```
Flutter app  ──startBackgroundPollingService()──►  notification_master_poller.exe
                                                          │
                                  ┌───────────────────────┘
                                  │  URL + interval را از registry می‌خواند
                                  │  هر N دقیقه سرور را poll می‌کند
                                  │  toast ویندوز را از طریق WinToast نشان می‌دهد
                                  │  لاگ → notification_master_poller.log
                                  └──► بعد از بسته شدن/ریستارت اپ زنده می‌ماند
```

فایل اجرایی daemon هنگام `flutter build windows` یا `flutter run` به‌صورت خودکار build می‌شود — نیازی به مرحله جداگانه build نیست.

#### مرحله ۱ — راه‌اندازی Dart (مثل سایر پلتفرم‌ها)

```dart
import 'package:notification_master/notification_master.dart';

final nm = NotificationMaster();

// ۱. بررسی / درخواست permission
final granted = await nm.checkNotificationPermission();
if (!granted) await nm.requestNotificationPermission();

// ۲. راه‌اندازی background poller daemon
//    پروسه daemon کنار .exe اپ شما اجرا می‌شود.
final ok = await nm.startBackgroundPollingService(
  pollingUrl: 'https://your-server.com/api/notifications',
  intervalMinutes: 1, // حداقل توصیه‌شده: ۱
);

if (!ok) {
  // .exe daemon پیدا نشد — مطمئن شوید با flutter build windows build کرده‌اید
  debugPrint('راه‌اندازی background poller شکست خورد');
}
```

#### مرحله ۲ — فرمت JSON سرور

endpoint سرور شما باید JSON با این ساختار دقیق برگرداند:

```json
{
  "notifications": [
    {
      "title": "پیام جدید",
      "message": "۳ پیام خوانده‌نشده دارید",
      "bigText": "متن گسترش‌یافته اختیاری که در toast نمایش داده می‌شود",
      "imageUrl": "https://example.com/avatar.png",
      "channelId": "high_priority_channel"
    }
  ]
}
```

- وقتی چیز جدیدی نیست آرایه **خالی** برگردانید (`"notifications": []`) — daemon بی‌صدا skip می‌کند.
- فیلدهای `bigText`، `imageUrl` و `channelId` اختیاری هستند.

#### مرحله ۳ — توقف daemon

```dart
await nm.stopBackgroundPollingService();
```

پروسه daemon متوقف شده و رکورد registry پاک می‌شود. راه‌اندازی بعدی اپ آن را به‌صورت خودکار مجدداً شروع نمی‌کند.

#### بررسی وضعیت daemon

```dart
final running = await nm.isBackgroundPollingRunning();
print('Daemon در حال اجرا: $running');
```

#### خواندن لاگ daemon

daemon یک فایل لاگ کنار `.exe` اپ می‌نویسد:

```
<build-output>\runner\Debug\notification_master_poller.log
```

می‌توانید آن را در runtime داخل debug panel اپ نمایش دهید:

```dart
import 'dart:io';

Future<void> printDaemonLog() async {
  final dir = File(Platform.resolvedExecutable).parent.path;
  final log = File('$dir\\notification_master_poller.log');
  if (await log.exists()) {
    final lines = await log.readAsLines();
    for (final l in lines.reversed.take(30)) debugPrint(l);
  }
}
```

یک لاگ سالم معمولی این‌گونه است:

```
[NM-POLLER] [10:00:01.234] Daemon started. AUMI=NotificationMaster...
[NM-POLLER] [10:00:01.235] PollingLoop: WinToast thread-instance initialized OK
[NM-POLLER] [10:00:01.312] PollOnce: requesting https://your-server.com/api/notifications
[NM-POLLER] [10:00:01.580] PollOnce: got 228 bytes
[NM-POLLER] [10:00:01.581] ShowFromJson: title='پیام جدید' message='...' result=1234 err=0
```

`err=0` یعنی toast با موفقیت نمایش داده شد.

#### Deduplication (جلوگیری از تکرار)

daemon به‌صورت خودکار از نمایش مجدد نوتیفیکیشنی که `title + message` آن در **۱ ساعت** گذشته نشان داده شده جلوگیری می‌کند. این کار از flood شدن کاربر هنگامی که سرور همان ردیف تحویل‌داده‌نشده را برمی‌گرداند جلوگیری می‌کند. لاگ نشان می‌دهد:

```
[NM-POLLER] ShowFromJson: SKIPPED (already shown recently): title='...'
```

#### مثال کامل کاربردی

فایل `example/lib/simple_polling_page.dart` یک UI کامل دارد که شامل:
- شروع / توقف background daemon
- Force poll برای تست فوری
- نمایش لاگ daemon داخل اپ
- کمک‌کننده SQL برای reset کردن ردیف‌های `delivered_at` حین توسعه

---

### 🐧 لینوکس — HTTP Polling (Background Daemon)

لینوکس از همان معماری daemon ویندوز استفاده می‌کند. یک باینری مستقل C++ به نام `notification_master_poller` به عنوان یک پروسه جداگانه راه‌اندازی می‌شود و بعد از بسته شدن اپ اصلی هم به کار ادامه می‌دهد.

#### نحوه کار

```
Flutter app  ──startBackgroundPollingService()──►  notification_master_poller  (ELF binary)
                                                          │
                                  ┌───────────────────────┘
                                  │  URL + interval را از
                                  │  ~/.config/notification_master/poller.conf می‌خواند
                                  │  هر N دقیقه سرور را poll می‌کند (libcurl)
                                  │  notification از طریق libnotify نمایش می‌دهد
                                  │  لاگ → notification_master_poller.log
                                  └──► بعد از بسته شدن/ریستارت اپ زنده می‌ماند
```

**پیش‌نیازها:** `libnotify`، `libcurl`، `libjson-glib` — روی Ubuntu/Fedora/Arch به صورت پیش‌فرض موجودند.

#### راه‌اندازی Dart (مثل ویندوز)

```dart
final ok = await nm.startBackgroundPollingService(
  pollingUrl: 'https://your-server.com/api/notifications',
  intervalMinutes: 1,
);
```

#### فایل config

daemon از `~/.config/notification_master/poller.conf` می‌خواند:

```ini
[poller]
url      = https://your-server.com/api/notifications
interval = 1
enabled  = 1
```

پلاگین این فایل را قبل از راه‌اندازی daemon به طور خودکار می‌نویسد.

#### لاگ daemon

کنار فایل اجرایی daemon نوشته می‌شود:

```
[NM-POLLER] [10:00:01.123] daemon started — pid=12345
[NM-POLLER] [10:00:01.200] polling_loop: requesting https://your-server.com/...
[NM-POLLER] [10:00:01.380] polling_loop: got 228 bytes
[NM-POLLER] [10:00:01.381] show_notification: title='پیام جدید' body='...'
```

---

### 🍎 مک‌اواس — HTTP Polling (Background Daemon)

مک‌اواس از یک باینری مستقل Swift به نام `notification_master_poller` استفاده می‌کند که به عنوان یک پروسه جداگانه اجرا می‌شود. از `UNUserNotificationCenter` برای نوتیفیکیشن و `URLSession` برای HTTP استفاده می‌کند.

#### نحوه کار

```
Flutter app  ──startBackgroundPollingService()──►  notification_master_poller  (Swift binary)
                                                          │
                                  ┌───────────────────────┘
                                  │  URL + interval را از
                                  │  UserDefaults (suite: com.notification-master.poller)
                                  │  می‌خواند
                                  │  هر N دقیقه poll می‌کند (URLSession)
                                  │  notification از طریق UNUserNotificationCenter
                                  │    (fallback به osascript اگر permission رد شود)
                                  │  لاگ → notification_master_poller.log
                                  └──► بعد از بسته شدن/ریستارت اپ زنده می‌ماند
```

#### راه‌اندازی Dart (مثل ویندوز/لینوکس)

```dart
final ok = await nm.startBackgroundPollingService(
  pollingUrl: 'https://your-server.com/api/notifications',
  intervalMinutes: 1,
);
```

#### ذخیره‌سازی config

در `UserDefaults` با suite `com.notification-master.poller` ذخیره می‌شود:

| کلید | مقدار |
|------|-------|
| `nm_bg_poll_url` | آدرس endpoint |
| `nm_bg_poll_interval` | interval به دقیقه |
| `nm_bg_poll_enabled` | `"1"` = در حال اجرا، `"0"` = توقف |

#### Permission نوتیفیکیشن

daemon هنگام راه‌اندازی از `UNUserNotificationCenter` درخواست مجوز می‌کند. اگر رد شود، به `osascript`'s `display notification` که بدون bundle ID کار می‌کند fallback می‌کند.

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

- **Permission های Android:** پلاگین هیچ permission ای را به‌صورت خودکار اعلام **نمی‌کند**. فقط permissionهایی که اپ شما واقعاً نیاز دارد را به `android/app/src/main/AndroidManifest.xml` اضافه کنید — بخش راه‌اندازی Android را ببینید.
- **Android 13+**: حتماً `POST_NOTIFICATIONS` Permission را در runtime از کاربر درخواست دهید.
- **Web**: مرورگر Safari پشتیبانی محدود دارد.
- **Foreground Service**: فقط Android پشتیبانی می‌کند.
- **Background Polling**: در Web کار نمی‌کند؛ فقط در حین باز بودن اپ polling انجام می‌شود.
- **کانال‌ها**: فقط Android 8.0+ پشتیبانی می‌کند؛ در سایر پلتفرم‌ها نادیده گرفته می‌شود.
- **آیکون اپلیکیشن**: از `showStyledNotification()` برای نمایش آیکون اپلیکیشن در نوتیفیکیشن استفاده کنید. ⭐
- **صدا**: کانال‌های سفارشی حالا به درستی با `enableSound: true` صدا پخش می‌کنند. ✅
- **iOS**: نیاز به iOS 14.0+ دارد. از iOS 14 تا iOS 26+ پشتیبانی می‌کند. 📱
- **Polling در macOS**: از یک `Timer` داخلی استفاده می‌کند — با بسته شدن اپ polling متوقف می‌شود. `BGTaskScheduler` فقط در iOS موجود است.

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