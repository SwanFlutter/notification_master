# راهنمای راه‌اندازی iOS - Notification Master

راهنمای کامل برای راه‌اندازی و استفاده از Notification Master در iOS.

---

## فهرست مطالب
1. [پیش‌نیازها](#پیشنیازها)
2. [نصب](#نصب)
3. [تنظیمات Podfile](#تنظیمات-podfile)
4. [تنظیمات Info.plist](#تنظیمات-infoplist)
5. [تنظیمات AppDelegate](#تنظیمات-appdelegate)
6. [مجوزها](#مجوزها)
7. [مثال‌های استفاده](#مثالهای-استفاده)
8. [رفع مشکلات](#رفع-مشکلات)

---

## پیش‌نیازها

- **iOS 14.0 یا بالاتر** ⚠️ (الزامی برای پلاگین notification_master)
- Xcode 13.0 یا بالاتر
- CocoaPods نصب شده
- Flutter SDK

### نصب CocoaPods (اگر نصب نیست)

```bash
sudo gem install cocoapods
```

---

## نصب

### 1. اضافه کردن به pubspec.yaml

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

**⚠️ مهم:** اگر خطای مربوط به minimum deployment target دریافت کردید، مطمئن شوید که `ios/Podfile` شما `platform :ios, '14.0'` یا بالاتر دارد.

---

## تنظیمات Podfile

### ساخت/به‌روزرسانی `example/ios/Podfile`

اگر فایل وجود ندارد، آن را با محتوای زیر بسازید:

```ruby
# حداقل نسخه iOS مورد نیاز notification_master
platform :ios, '14.0'

# تنظیمات CocoaPods
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # تنظیم iOS 14.0 برای همه pod ها
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
```

### نکات مهم:

1. **نسخه پلتفرم**: `platform :ios, '14.0'` - **حداقل الزامی**
2. **post_install**: iOS 14.0 را برای همه pod ها تنظیم می‌کند
3. **use_frameworks!**: برای pod های Swift لازم است

---

## تنظیمات Info.plist

به `example/ios/Runner/Info.plist` اضافه کنید:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

---

## تنظیمات AppDelegate

`example/ios/Runner/AppDelegate.swift` را به‌روزرسانی کنید:

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
    UNUserNotificationCenter.current().delegate = self
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
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
  
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    completionHandler()
  }
}
```

---

## مجوزها

```dart
import 'package:notification_master/notification_master.dart';

final nm = NotificationMaster();

bool hasPermission = await nm.checkNotificationPermission();
if (!hasPermission) {
  bool granted = await nm.requestNotificationPermission();
}
```

---

## مثال‌های استفاده

```dart
// نوتیفیکیشن ساده
await nm.showNotification(
  title: 'سلام',
  message: 'نوتیفیکیشن تستی',
);

// با صدا
await nm.showNotification(
  title: 'هشدار',
  message: 'پیام مهم',
  importance: NotificationImportance.high,
);
```

---

## رفع مشکلات

### خطا: Deployment Target خیلی پایین است

**خطا:**
```
CocoaPods could not find compatible versions for pod "notification_master":
required a higher minimum deployment target.
```

**راه‌حل:**
1. `ios/Podfile` را به‌روزرسانی کنید:
```ruby
platform :ios, '14.0'
```

2. پاک‌سازی و نصب مجدد:
```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install
cd ..
```

### Pod Install با خطا مواجه می‌شود

```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install
cd ..
```

### Build با خطا مواجه می‌شود

```bash
flutter clean
cd ios && pod install && cd ..
flutter build ios
```

---

## محدودیت‌های iOS

1. بدون کانال سفارشی (ویژگی Android)
2. سفارشی‌سازی UI محدود
3. حداکثر ۴ دکمه برای هر نوتیفیکیشن
4. برخی ویژگی‌ها در simulator کار نمی‌کنند

---

## لایسنس

MIT License
