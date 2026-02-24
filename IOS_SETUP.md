Here is the complete, non-repeating version of the **iOS Setup Guide for Notification Master** in English:

---

# iOS Setup Guide - Notification Master

A complete guide for setting up and using **Notification Master** on iOS.

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

- iOS 12.0 or higher
- Xcode 13.0 or higher
- CocoaPods installed
- Flutter SDK

### Install CocoaPods (if not installed)

```bash
sudo gem install cocoapods
```

---

## Installation

### 1. Add to `pubspec.yaml`

```yaml
dependencies:
  notification_master: ^0.0.5
```

### 2. Install dependencies

```bash
flutter pub get
cd ios
pod install
cd ..
```

---

## Podfile Configuration

### Create/Update `example/ios/Podfile`

If the file doesn’t exist, create it with the following content:

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

### Key Points in Podfile:

1. **Platform Version**: `platform :ios, '12.0'` – Minimum iOS version
2. **use_frameworks!**: Required for Swift pods
3. **use_modular_headers!**: Enables modular headers for better compatibility
4. **Deployment Target**: Set to iOS 12.0 for all pods

---

## Info.plist Configuration

### Update `example/ios/Runner/Info.plist`

Add the following keys inside the `<dict>` tag:

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

### Important Info.plist Keys:

- **UIBackgroundModes**: Allows the app to receive notifications in the background
- **NSUserNotificationAlertStyle**: Sets the notification display style
- **NSAppTransportSecurity**: Required if using HTTP (not HTTPS) for polling

---

## AppDelegate Configuration

### Update `example/ios/Runner/AppDelegate.swift`

Replace the content with:

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

## Permissions

### Request Notification Permission

```dart
import 'package:notification_master/notification_master.dart';

final notificationMaster = NotificationMaster();

// Check permission
bool hasPermission = await notificationMaster.checkNotificationPermission();

if (!hasPermission) {
  // Request permission (shows iOS system dialog)
  bool granted = await notificationMaster.requestNotificationPermission();

  if (granted) {
    print('✅ Notification permission granted');
  } else {
    print('❌ Notification permission denied');
  }
}
```

---

## Usage Examples

### 1. Simple Notification

```dart
await notificationMaster.showNotification(
  title: 'Hello iOS',
  message: 'This is a test notification',
);
```

### 2. Notification with Sound

```dart
await notificationMaster.showNotification(
  title: 'New Message',
  message: 'You have a new message',
  importance: NotificationImportance.high,
);
```

### 3. Big Text Notification

```dart
await notificationMaster.showBigTextNotification(
  title: 'Long Article',
  message: 'Summary...',
  bigText: 'Full article text...',
);
```

### 4. Image Notification

```dart
await notificationMaster.showImageNotification(
  title: 'New Photo',
  message: 'Check out this photo',
  imageUrl: 'https://example.com/photo.jpg',
);
```

### 5. HTTP Polling

```dart
// Start polling
await notificationMaster.startNotificationPolling(
  pollingUrl: 'https://api.example.com/notifications',
  intervalMinutes: 15,
);

// Stop polling
await notificationMaster.stopNotificationPolling();
```

---

## Troubleshooting

### Issue 1: Notifications Not Showing

**Solution:**
1. Check if permission is granted
2. Verify `UNUserNotificationCenter.current().delegate = self` in AppDelegate
3. Check iOS Settings > Notifications > Your App

### Issue 2: No Sound

**Solution:**
1. Use `importance: NotificationImportance.high`
2. Check if the device is not in silent mode
3. Verify notification settings in iOS Settings

### Issue 3: Pod Install Fails

**Solution:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install
cd ..
```

### Issue 4: Build Fails

**Solution:**
```bash
flutter clean
rm -rf ~/Library/Developer/Xcode/DerivedData
flutter pub get
cd ios && pod install && cd ..
flutter build ios
```

---

## iOS Notification Limitations

1. **No Custom Channels**: iOS does not support Android-style notification channels
2. **Limited Customization**: iOS notifications have limited UI customization
3. **Actions**: Limited to 4 actions per notification
4. **Simulator**: Some features do not work in the simulator

---

## Best Practices

1. Always request permission before showing notifications
2. Handle foreground notifications with `willPresent`
3. Handle notification taps with `didReceive`
4. Test on a real device, not just the simulator
5. Do not spam users with too many notifications

---

## License

MIT License – See the LICENSE file for details.