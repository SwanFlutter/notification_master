
# iOS Setup Guide - Notification Master

راهنمای کامل برای تنظیم و استفاده از Notification Master در iOS.

---

## فهرست مطالب
1. [پیش‌نیازها](#پیش‌نیازها)
2. [نصب](#نصب)
3. [پیکربندی Podfile](#پیکربندی-podfile)
4. [پیکربندی Info.plist](#پیکربندی-infoplist)
5. [پیکربندی AppDelegate](#پیکربندی-appdelegate)
6. [مجوزها](#مجوزها)
7. [مثال‌های استفاده](#مثال‌های-استفاده)
8. [رفع مشکلات](#رفع-مشکلات)

---

## پیش‌نیازها

- iOS 12.0 یا بالاتر
- Xcode 13.0 یا بالاتر
- CocoaPods نصب شده
- Flutter SDK

### نصب CocoaPods (در صورت عدم نصب)

```bash
sudo gem install cocoapods
```

---

## نصب

### 1. افزودن به `pubspec.yaml`

```yaml
dependencies:
  notification_master: ^0.0.5
```

### 2. نصب وابستگی‌ها

```bash
flutter pub get
cd ios
pod install
cd ..
```

---

## پیکربندی Podfile

### ایجاد/به‌روزرسانی `example/ios/Podfile`

در صورت عدم وجود فایل، آن را با محتوای زیر ایجاد کنید:

```ruby
# Uncomment this line to define a global platform for your project
platform :ios, '12.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  # Add this if you need Firebase Cloud Messaging
  # pod 'Firebase/Messaging'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    # Fix for Xcode 14+
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'

      # Disable bitcode
      config.build_settings['ENABLE_BITCODE'] = 'NO'

      # Fix for arm64 simulator
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
    end
  end
end
```

### نکات کلیدی در Podfile:

1. **نسخه پلتفرم**: `platform :ios, '12.0'` - حداقل نسخه iOS
2. **use_frameworks!**: برای پکیج‌های Swift ضروری است
3. **use_modular_headers!**: برای سازگاری بهتر سربرگ‌های مدولار را فعال می‌کند
4. **هدف استقرار**: برای همه پدها روی iOS 12.0 تنظیم شده است

---

## پیکربندی Info.plist

### به‌روزرسانی `example/ios/Runner/Info.plist`

کلیدهای زیر را داخل تگ `<dict>` اضافه کنید:

```xml
<!-- Background Modes for Notifications -->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>

<!-- Notification Permission Description (Optional but recommended) -->
<key>NSUserNotificationAlertStyle</key>
<string>alert</string>

<!-- App Transport Security (if using HTTP polling) -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <!-- Add specific domains if needed -->
    <key>NSExceptionDomains</key>
    <dict>
        <key>your-api-domain.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### کلیدهای مهم Info.plist:

- **UIBackgroundModes**: اجازه دریافت اعلان‌ها در پس‌زمینه را می‌دهد
- **NSUserNotificationAlertStyle**: سبک نمایش اعلان را تنظیم می‌کند
- **NSAppTransportSecurity**: در صورت استفاده از HTTP (نه HTTPS) برای نظرسنجی لازم است

---

## پیکربندی AppDelegate

### به‌روزرسانی `example/ios/Runner/AppDelegate.swift`

محتوا را با موارد زیر جایگزین کنید:

```swift
import UIKit
import Flutter
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Set notification delegate
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle notification when app is in foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  // Handle notification tap
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    print("Notification tapped with userInfo: \(userInfo)")
    completionHandler()
  }
}
```

---

## مجوزها

### درخواست مجوز اعلان

```dart
import 'package:notification_master/notification_master.dart';

final notificationMaster = NotificationMaster();

// بررسی مجوز
bool hasPermission = await notificationMaster.checkNotificationPermission();

if (!hasPermission) {
  // درخواست مجوز (نمایش دیالوگ سیستم iOS)
  bool granted = await notificationMaster.requestNotificationPermission();

  if (granted) {
    print('✅ مجوز اعلان داده شد');
  } else {
    print('❌ مجوز اعلان رد شد');
  }
}
```

---

## مثال‌های استفاده

### 1. اعلان ساده

```dart
await notificationMaster.showNotification(
  title: 'Hello iOS',
  message: 'این یک اعلان آزمایشی است',
);
```

### 2. اعلان با صدا

```dart
await notificationMaster.showNotification(
  title: 'پیام جدید',
  message: 'شما یک پیام جدید دارید',
  importance: NotificationImportance.high,
);
```

### 3. اعلان با متن بزرگ

```dart
await notificationMaster.showBigTextNotification(
  title: 'مقاله طولانی',
  message: 'خلاصه...',
  bigText: 'متن کامل مقاله...',
);
```

### 4. اعلان با تصویر

```dart
await notificationMaster.showImageNotification(
  title: 'عکس جدید',
  message: 'این عکس را ببینید',
  imageUrl: 'https://example.com/photo.jpg',
);
```

### 5. نظرسنجی HTTP

```dart
// شروع نظرسنجی
await notificationMaster.startNotificationPolling(
  pollingUrl: 'https://api.example.com/notifications',
  intervalMinutes: 15,
);

// توقف نظرسنجی
await notificationMaster.stopNotificationPolling();
```

---

## رفع مشکلات

### مشکل 1: اعلان‌ها نمایش داده نمی‌شوند

**راه‌حل:**
1. بررسی کنید مجوز داده شده است
2. مطمئن شوید `UNUserNotificationCenter.current().delegate = self` در AppDelegate تنظیم شده است
3. تنظیمات iOS > Notifications > برنامه شما را بررسی کنید

### مشکل 2: بدون صدا

**راه‌حل:**
1. از `importance: NotificationImportance.high` استفاده کنید
2. بررسی کنید دستگاه در حالت سکوت نیست
3. تنظیمات اعلان را در تنظیمات iOS بررسی کنید

### مشکل 3: خطا در نصب Pod

**راه‌حل:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install
cd ..
```

### مشکل 4: خطا در ساخت

**راه‌حل:**
```bash
flutter clean
rm -rf ~/Library/Developer/Xcode/DerivedData
flutter pub get
cd ios && pod install && cd ..
flutter build ios
```

---

## محدودیت‌های اعلان iOS

1. **بدون کانال‌های سفارشی**: iOS از کانال‌های اعلان به سبک اندروید پشتیبانی نمی‌کند
2. **سفارشی‌سازی محدود**: اعلان‌های iOS سفارشی‌سازی UI محدودی دارند
3. **عملیات**: محدود به 4 عمل در هر اعلان
4. **شبیه‌ساز**: برخی ویژگی‌ها در شبیه‌ساز کار نمی‌کنند

---

## بهترین روش‌ها

1. همیشه قبل از نمایش اعلان‌ها مجوز بگیرید
2. اعلان‌های پیش‌زمینه را با `willPresent` مدیریت کنید
3. کلیک‌های اعلان را با `didReceive` مدیریت کنید
4. روی دستگاه واقعی تست کنید، نه فقط شبیه‌ساز
5. کاربران را با اعلان‌های زیاد اسپم نکنید

---

