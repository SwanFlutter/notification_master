# Notification Master

A comprehensive Flutter plugin for managing notifications across all platforms with advanced features including HTTP polling, custom channels, and platform-specific optimizations.

## Platform Support

| Platform | Support | Features |
|----------|---------|----------|
| Android  | ✅ Full | Local notifications, custom channels, importance levels, auto-cancel, custom icons, HTTP polling |
| iOS      | ✅ Full | Local notifications, custom sounds, badges, HTTP polling, rich notifications |
| macOS    | ✅ Full | Native notifications, custom sounds, badges, HTTP polling |
| Windows  | ✅ Full | Toast notifications, custom actions, HTTP polling |
| Web      | ✅ Full | Browser notifications, permission handling, HTTP polling |
| Linux    | ✅ Full | Desktop notifications, custom icons, HTTP polling |

## Installation

Add this plugin to your project's `pubspec.yaml` file:

```yaml
dependencies:
  notification_master: ^0.0.4
```

Then run:

```bash
flutter pub get
```

### Android Setup

To use this plugin, you need to add the following permissions to your `android/app/src/main/AndroidManifest.xml` file manually. This gives you full control over which permissions your app requests.

Open `android/app/src/main/AndroidManifest.xml` and add these lines inside the `<manifest>` tag:

```xml
<!-- Internet permission for HTTP notifications -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- For Android 13+ (API level 33+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- For foreground service -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />

<!-- For restarting notification service after device reboot -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

**Note:** The plugin automatically handles `android:enableOnBackInvokedCallback="true"` configuration, so you don't need to add that manually.

```xml
<activity
           android:name=".MainActivity"
           android:exported="true"
           android:launchMode="singleTop"
           android:taskAffinity=""
           android:theme="@style/LaunchTheme"
   ***     android:enableOnBackInvokedCallback="true"
           android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
           android:hardwareAccelerated="true"
           android:windowSoftInputMode="adjustResize">
```

### iOS Setup

For iOS-specific setup instructions, see [IOS_README.md](IOS_README.md).

## Quick Start

```dart
import 'package:notification_master/notification_master.dart';

// Create an instance of the plugin
final notificationMaster = NotificationMaster();

// Check if notification permission is granted
final hasPermission = await notificationMaster.checkNotificationPermission();

// Request notification permission (required for Android 13+)
if (!hasPermission) {
  final granted = await notificationMaster.requestNotificationPermission();
  if (!granted) {
    // Permission denied, show a message to the user
    print('Notification permission denied');
    return;
  }
}
```

## Basic Usage Examples

### Simple Notifications

```dart
// Display a simple notification
await notificationMaster.showNotification(
  title: 'Simple Notification',
  message: 'This is a simple notification',
);

// Display a notification with custom ID
await notificationMaster.showNotification(
  id: 123,
  title: 'Custom ID Notification',
  message: 'This notification has a custom ID',
);

// Display a notification with high importance (Android)
await notificationMaster.showNotification(
  title: 'Important Notification',
  message: 'This is a high importance notification',
  importance: NotificationImportance.high,
);

// Display a notification that does not auto-cancel on tap
await notificationMaster.showNotification(
  title: 'Persistent Notification',
  message: 'This notification does not auto-cancel on tap',
  autoCancel: false,
);

// Display a notification that opens a specific screen when tapped
await notificationMaster.showNotification(
  title: 'Navigation Notification',
  message: 'Tap to open the settings screen',
  payload: 'settings_screen',
);
```
