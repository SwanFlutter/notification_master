# iOS Setup Guide - Notification Master

Complete guide for setting up and using Notification Master on iOS.

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Podfile Configuration](#podfile-configuration)
4. [Info.plist Configuration](#infoplist-configuration)
5. [AppDelegate Configuration](#appdelegate-configuration)
6. [Permissions](#permissions)
7. [Usage Examples](#usage-examples)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- **iOS 14.0 or higher** ⚠️ (Required by notification_master plugin)
- Xcode 13.0 or higher
- CocoaPods installed
- Flutter SDK

### Install CocoaPods (if not installed)

```bash
sudo gem install cocoapods
```

---

## Installation

### 1. Add to pubspec.yaml

```yaml
dependencies:
  notification_master: ^0.0.6
```

### 2. Install dependencies

```bash
flutter pub get
cd ios
pod install
cd ..
```

**⚠️ Important:** If you get an error about minimum deployment target, make sure your `ios/Podfile` has `platform :ios, '14.0'` or higher.

---

## Podfile Configuration

### Create/Update `example/ios/Podfile`

If the file doesn't exist, create it with the following content:

```ruby
# Minimum iOS version required by notification_master
platform :ios, '14.0'

# CocoaPods analytics
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
    
    # Set iOS 14.0 for all pods
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
```

### Key Points:

1. **Platform Version**: `platform :ios, '14.0'` - **Required minimum**
2. **post_install**: Sets iOS 14.0 for all pods
3. **use_frameworks!**: Required for Swift pods

---

## Info.plist Configuration

Add to `ios/Runner/Info.plist` inside the `<dict>` tag:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
    <string>processing</string>
</array>
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER).notificationPolling</string>
</array>
```

---

## AppDelegate Configuration

Update `ios/Runner/AppDelegate.swift`:

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
    // Required: show notifications while app is in foreground
    UNUserNotificationCenter.current().delegate = self

    // Required: register background polling task
    NotificationMasterPlugin.registerBackgroundTask()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // Show notifications while app is in foreground
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound, .badge])
  }

  // Handle notification tap
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    completionHandler()
  }
}
```

**Why each part is needed:**
- `import notification_master` — required to call `NotificationMasterPlugin.registerBackgroundTask()`
- `FlutterImplicitEngineDelegate` — required for newer Flutter versions
- `UNUserNotificationCenterDelegate` — required to show notifications when app is open
- `registerBackgroundTask()` — registers background polling with iOS scheduler
- `willPresent` — without this, iOS silently drops notifications while app is in foreground

---

## Permissions

```dart
import 'package:notification_master/notification_master.dart';

final nm = NotificationMaster();

bool hasPermission = await nm.checkNotificationPermission();
if (!hasPermission) {
  bool granted = await nm.requestNotificationPermission();
}
```

---

## Usage Examples

```dart
// Simple notification
await nm.showNotification(
  title: 'Hello',
  message: 'Test notification',
);

// With sound
await nm.showNotification(
  title: 'Alert',
  message: 'Important message',
  importance: NotificationImportance.high,
);
```

---

## Troubleshooting

### Error: Deployment Target Too Low

**Error:**
```
CocoaPods could not find compatible versions for pod "notification_master":
required a higher minimum deployment target.
```

**Solution:**
1. Update `ios/Podfile`:
```ruby
platform :ios, '14.0'
```

2. Clean and reinstall:
```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install
cd ..
```

### Pod Install Fails

```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install
cd ..
```

### Build Fails

```bash
flutter clean
cd ios && pod install && cd ..
flutter build ios
```

---

## iOS Limitations

1. No custom channels (Android feature)
2. Limited UI customization
3. Max 4 actions per notification
4. Some features don't work in simulator

---

## License

MIT License
