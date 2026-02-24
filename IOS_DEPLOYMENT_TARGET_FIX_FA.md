# رفع خطا: iOS Deployment Target

## مشکل

هنگام اجرای `pod install`، این خطا را دریافت می‌کنید:

```
CocoaPods could not find compatible versions for pod "notification_master":
Specs satisfying the dependency were found, but they required a higher minimum deployment target.
```

## علت اصلی

پلاگین `notification_master` نیاز به **iOS 14.0 یا بالاتر** دارد، اما Podfile شما روی iOS 12.0 تنظیم شده است.

---

## راه‌حل

### مرحله 1: به‌روزرسانی Podfile

فایل `example/ios/Podfile` را باز کنید و تغییر دهید:

```ruby
# قدیمی (iOS 12.0)
platform :ios, '12.0'
```

به:

```ruby
# جدید (iOS 14.0 - الزامی برای notification_master)
platform :ios, '14.0'
```

### مرحله 2: به‌روزرسانی post_install

در همان Podfile، بخش `post_install` را پیدا کنید و تغییر دهید:

```ruby
# قدیمی
config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
```

به:

```ruby
# جدید
config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
```

### مرحله 3: پاک‌سازی و نصب مجدد

این دستورات را اجرا کنید:

```bash
cd example/ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install
cd ../..
```

### مرحله 4: پاک‌سازی Flutter Build

```bash
flutter clean
flutter pub get
```

### مرحله 5: اجرای مجدد

```bash
flutter run
```

---

## مثال کامل Podfile

`example/ios/Podfile` شما باید این شکلی باشد:

```ruby
# حداقل نسخه iOS مورد نیاز پلاگین notification_master
platform :ios, '14.0'

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

  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      # تنظیم حداقل iOS deployment target به 14.0 (الزامی برای notification_master)
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['SWIFT_VERSION'] = '5.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
```

---

## تایید

بعد از انجام این مراحل، اجرا کنید:

```bash
cd example/ios
pod install
```

باید این پیام را ببینید:

```
Analyzing dependencies
Downloading dependencies
Installing notification_master
...
Pod installation complete!
```

---

## هنوز مشکل دارید؟

### مشکل: Flutter می‌گوید "Updating minimum iOS deployment target to 13.0"

این فقط یک هشدار است. Flutter به طور خودکار آن را به 14.0 به‌روزرسانی می‌کند وقتی نیاز پلاگین را تشخیص می‌دهد.

### مشکل: Build در Xcode با خطا مواجه می‌شود

1. `example/ios/Runner.xcworkspace` را در Xcode باز کنید
2. Runner target را انتخاب کنید
3. به "Build Settings" بروید
4. "iOS Deployment Target" را جستجو کنید
5. آن را روی "iOS 14.0" تنظیم کنید

---

## چرا iOS 14.0؟

پلاگین `notification_master` از API های iOS استفاده می‌کند که فقط در iOS 14.0 و بالاتر موجود هستند:
- ویژگی‌های UserNotifications framework
- بهبودهای background task
- مدیریت مدرن نوتیفیکیشن

---

## خلاصه

✅ `platform :ios, '12.0'` را به `platform :ios, '14.0'` تغییر دهید  
✅ `IPHONEOS_DEPLOYMENT_TARGET` را به `'14.0'` در post_install به‌روزرسانی کنید  
✅ pod ها را پاک کرده و دوباره نصب کنید  
✅ Flutter build را پاک کنید  

تمام! راه‌اندازی iOS شما حالا باید درست کار کند.
