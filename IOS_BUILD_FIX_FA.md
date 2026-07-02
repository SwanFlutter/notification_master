# راهنمای رفع مشکل Build در iOS

## مشکلات حل شده

✅ **اشتباه تایپی در کد Swift اصلاح شد**: `FlurError` → `FlutterError`
✅ **نسخه به اپ example اضافه شد**: `version: 1.0.0+1`

---

## رفع سریع مشکل

این دستورات رو در پوشه `example` اجرا کنید:

```bash
# پاک کردن همه چیز
flutter clean
rm -rf ios/Pods ios/Podfile.lock

# نصب مجدد
flutter pub get
cd ios
pod install
cd ..

# Build
flutter run
```

---

## یا از اسکریپت استفاده کنید

```bash
chmod +x ios_build_fix.sh
./ios_build_fix.sh
```

---

## مراحل دستی

### 1. پاک کردن Build فلاتر

```bash
cd example
flutter clean
```

### 2. حذف iOS Pods

```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
```

### 3. نصب مجدد وابستگی‌ها

```bash
pod install
cd ..
flutter pub get
```

### 4. Build

```bash
flutter run
```

---

## اگر هنوز مشکل دارید

### مشکل: هشدار تنظیمات CocoaPods

اگر این پیام رو می‌بینید:
> CocoaPods did not set the base configuration of your project

**راه‌حل:**

1. فایل `example/ios/Runner.xcworkspace` رو در Xcode باز کنید
2. پروژه Runner رو در پنل چپ انتخاب کنید
3. Target Runner رو انتخاب کنید
4. به تب "Build Settings" بروید
5. "Base Configuration" رو جستجو کنید
6. برای هر configuration (Debug, Release, Profile):
   - تنظیم کنید روی: `Pods-Runner.debug.xcconfig` (یا config مربوطه)

### مشکل: عدم تطابق Deployment Target

اگر خطای deployment target می‌بینید:

**راه‌حل:**

1. فایل `example/ios/Podfile` رو باز کنید
2. مطمئن شوید این کد در `post_install` هست:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
```

3. اجرا کنید:
```bash
cd ios
pod install
cd ..
```

### مشکل: خطاهای Swift Compiler

اگر خطای کامپایل Swift می‌بینید:

**راه‌حل:**

1. مطمئن شوید از Xcode 13.0 یا بالاتر استفاده می‌کنید
2. نسخه Swift رو بررسی کنید:
```bash
swift --version
```

3. Derived data رو پاک کنید:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

4. Build مجدد:
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

---

## تایید

بعد از رفع مشکل، باید این رو ببینید:

```
✓ Built build/ios/iphoneos/Runner.app
Launching lib/main.dart on iPhone in debug mode...
```

---

## خطاهای رایج و راه‌حل‌ها

### خطا: "Cannot find 'FlutterError' in scope"

**حل شد!** این یک اشتباه تایپی در کد بود. قبلاً اصلاح شده.

### خطا: "Missing build name (CFBundleShortVersionString)"

**حل شد!** `version: 1.0.0+1` به `example/pubspec.yaml` اضافه شد.

### خطا: "Module 'notification_master' not found"

**راه‌حل:**
```bash
cd example/ios
pod deintegrate
pod install
cd ../..
flutter clean
flutter pub get
cd example
flutter run
```

---

## نیاز به کمک بیشتر؟

ببینید:
- [IOS_SETUP_FA.md](IOS_SETUP_FA.md) - راهنمای کامل راه‌اندازی iOS
- [IOS_SETUP.md](IOS_SETUP.md) - English guide

---

## لایسنس

MIT License
