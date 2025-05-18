# Notification Master

A Flutter plugin for easy notification management on Android 7 and above (API level 24+). This plugin automatically handles all necessary permissions, manifest settings, and notification channels.

## Features

- 🔔 Simple and big text notifications with customizable appearance
- 🖼️ Display images in notifications
- 👆 Custom actions for notifications
- 📱 Automatic creation of notification channels for Android 8 and above (API level 26+)
- 🔐 Professional permission management for Android 13 and above (API level 33+)
- 🌐 HTTP/JSON notification polling with optimized implementation for battery consumption
- 🔄 Automatic restart of notification polling after device reboot
- 👋 Built-in swipe-to-dismiss capability
- 🔋 Foreground service for reliable notification reception
- 🔄 Intelligent management of notification services to prevent conflicts





https://github.com/user-attachments/assets/315d7644-eed1-498b-a55b-cde06f59f7ed





## Installation

Add this plugin to your project's `pubspec.yaml` file:

```yaml
dependencies:
  notification_master: ^0.0.1
```

**Note:** You only need to manually add the INTERNET permission to your `android/app/src/main/AndroidManifest.xml` file. The plugin automatically adds all other required permissions.

```xml
<!-- Internet permission for HTTP notifications -->
<uses-permission android:name="android.permission.INTERNET" />
```

For reference, here are all the permissions that the plugin automatically adds:
You don't need to add these.

```xml
<!-- For Android 13+ (API level 33+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- For foreground service -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />

<!-- For restarting notification service after device reboot -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

Also, add the `android:enableOnBackInvokedCallback="true"` attribute to the `activity` tag:

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

## Usage

### Permission Management

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
  }
}
```

### Simple Notifications

```dart
// Display a simple notification
await notificationMaster.showNotification(
  title: 'Simple Notification',
  message: 'This is a simple notification',
);

// Display a notification with custom priority (for Android < 8.0)
// Priority values: -2 (min), -1 (low), 0 (default), 1 (high), 2 (max)
await notificationMaster.showNotification(
  title: 'High Priority Notification',
  message: 'This is a high priority notification',
  priority: 1, // High priority
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
  targetScreen: '/settings',
);

// Display a notification that passes data to the target screen
await notificationMaster.showNotification(
  title: 'Data Notification',
  message: 'Tap to view product details',
  targetScreen: '/product',
  extraData: {'productId': '12345', 'featured': true},
);
```

### Big Text Notifications

```dart
// Display a big text notification
await notificationMaster.showBigTextNotification(
  title: 'Big Text Notification',
  message: 'This is a big text notification',
  bigText: 'This is an expanded text that is shown when the notification is expanded. This text can be much longer than the main message and can include multiple paragraphs or detailed information.',
);

// Display a big text notification that opens a specific screen when tapped
await notificationMaster.showBigTextNotification(
  title: 'Article Notification',
  message: 'New article available',
  bigText: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam euismod, nisl eget aliquam ultricies, nunc nisl aliquet nunc, quis aliquam nisl nunc eu nisl.',
  targetScreen: '/article',
  extraData: {'articleId': '789', 'category': 'technology'},
);
```

### Image Notifications

```dart
// Display an image notification
await notificationMaster.showImageNotification(
  title: 'Image Notification',
  message: 'This notification includes an image',
  imageUrl: 'https://example.com/image.jpg',
);

// Display a high priority image notification
await notificationMaster.showImageNotification(
  title: 'Important Image Notification',
  message: 'This is an important notification with an image',
  imageUrl: 'https://example.com/important-image.jpg',
  priority: 1, // High priority
);

// Display an image notification that opens a specific screen when tapped
await notificationMaster.showImageNotification(
  title: 'Product Image',
  message: 'Check out our new product',
  imageUrl: 'https://example.com/product.jpg',
  targetScreen: '/product',
  extraData: {'productId': '12345', 'featured': true},
);
```

### Notifications with Custom Actions

```dart
// Display a notification with custom actions
await notificationMaster.showNotificationWithActions(
  title: 'Notification with Actions',
  message: 'This notification has custom actions',
  actions: [
    {'title': 'Open Settings', 'route': '/settings'},
    {'title': 'View Profile', 'route': '/profile'},
  ],
);

// Display a notification with a single action
await notificationMaster.showNotificationWithActions(
  title: 'Notification with One Action',
  message: 'This notification has one action',
  actions: [
    {'title': 'Open App', 'route': '/home'},
  ],
);

// Display a notification with custom actions and a specific target screen
await notificationMaster.showNotificationWithActions(
  title: 'Friend Request',
  message: 'John Doe sent you a friend request',
  actions: [
    {'title': 'Accept', 'route': '/accept-friend'},
    {'title': 'Decline', 'route': '/decline-friend'},
  ],
  targetScreen: '/profile',
  extraData: {'userId': '12345', 'requestId': '67890'},
);
```

### HTTP/JSON Notification Polling

You can configure the plugin to fetch notifications from a remote server. The polling service runs continuously in the background and checks for new notifications at regular intervals:

```dart
// Start notification polling
await notificationMaster.startNotificationPolling(
  pollingUrl: 'https://your-api.com/notifications',
  intervalMinutes: 15, // Check every 15 minutes (not a timeout)
);

// Stop notification polling
await notificationMaster.stopNotificationPolling();
```

**Note:** The `intervalMinutes` parameter specifies how often the service checks for new notifications. The service remains active indefinitely until explicitly stopped or the device is shut down (in which case it automatically restarts when the device boots up).

The server should return JSON in the following format:

```json
{
  "notifications": [
    {
      "title": "Notification Title",
      "message": "Notification Message",
      "bigText": "Optional expanded text",
      "channelId": "Optional channel ID"
    }
  ]
}
```

### Foreground Service for Reliable Notification Reception

For more reliable notification reception, you can use the foreground service. This service runs with higher priority than the regular polling service and shows a persistent notification to ensure it keeps running:

```dart
// Start foreground service for notification reception
await notificationMaster.startForegroundService(
  pollingUrl: 'https://your-api.com/notifications',
  intervalMinutes: 15, // Check every 15 minutes (not a timeout)
);

// Start foreground service with custom notification channel
await notificationMaster.startForegroundService(
  pollingUrl: 'https://your-api.com/notifications',
  intervalMinutes: 15,
  channelId: 'foreground_channel',
  channelName: 'Foreground Service',
  channelDescription: 'Channel for foreground service notifications',
  importance: 0, // Default importance
  enableLights: true,
  lightColor: 0xFF0000FF, // Blue color
  enableVibration: false,
  enableSound: true,
);

// Stop foreground service
await notificationMaster.stopForegroundService();
```

**Note:** Similar to the regular polling service, the `intervalMinutes` parameter specifies how often the service checks for new notifications. The foreground service remains active indefinitely until explicitly stopped, providing more reliable notification delivery at the cost of showing a persistent notification to the user.

### Notification Service Management

To prevent conflicts between different notification services, you can use the following methods:

```dart
// Set Firebase as the active notification service
// This will deactivate other active services
await notificationMaster.setFirebaseAsActiveService();

// Get the currently active service
// Possible values: "none", "polling", "foreground", "firebase"
String activeService = await notificationMaster.getActiveNotificationService();
```

## Custom Notification Channels

By default, all notifications use the default notification channel. You can create custom channels with different importance levels, sounds, and visual settings:

### Creating Custom Channels

```dart
// Create a high priority channel
await notificationMaster.createCustomChannel(
  channelId: 'high_priority_channel',
  channelName: 'High Priority',
  channelDescription: 'Channel for important notifications',
  importance: 1, // High importance
  enableLights: true,
  lightColor: 0xFFFF0000, // Red color
  enableVibration: true,
  enableSound: true,
);

// Create a silent channel
await notificationMaster.createCustomChannel(
  channelId: 'silent_channel',
  channelName: 'Silent Notifications',
  channelDescription: 'Channel for silent notifications',
  importance: 4, // Silent importance
  enableLights: false,
  enableVibration: false,
  enableSound: false,
);

// Create a channel for media notifications
await notificationMaster.createCustomChannel(
  channelId: 'media_channel',
  channelName: 'Media',
  channelDescription: 'Channel for media notifications',
  importance: 0, // Default importance
  enableLights: true,
  lightColor: 0xFF00FF00, // Green color
  enableVibration: false,
  enableSound: true,
);
```

### Using Custom Channels

```dart
// Use a custom channel for a simple notification
await notificationMaster.showNotification(
  title: 'High Priority Notification',
  message: 'This notification uses the high priority channel',
  channelId: 'high_priority_channel',
);

// Use a custom channel for a big text notification
await notificationMaster.showBigTextNotification(
  title: 'Silent Notification',
  message: 'This notification uses the silent channel',
  bigText: 'This is a silent notification with expanded text content.',
  channelId: 'silent_channel',
);

// Use a custom channel for an image notification
await notificationMaster.showImageNotification(
  title: 'Media Notification',
  message: 'This notification uses the media channel',
  imageUrl: 'https://example.com/album-cover.jpg',
  channelId: 'media_channel',
);
```

## Importance Levels

When creating custom channels, you can use the `NotificationImportance` enum:

```dart
// Use the NotificationImportance enum for better type safety
await notificationMaster.createCustomChannel(
  channelId: 'high_priority_channel',
  channelName: 'High Priority',
  channelDescription: 'Channel for important notifications',
  importance: NotificationImportance.high,
  enableLights: true,
  lightColor: 0xFFFF0000, // Red color
  enableVibration: true,
  enableSound: true,
);

// Available importance levels:
// NotificationImportance.defaultImportance - Makes sound (NotificationManager.IMPORTANCE_DEFAULT)
// NotificationImportance.high - Makes sound and appears as heads-up notification (NotificationManager.IMPORTANCE_HIGH)
// NotificationImportance.low - No sound (NotificationManager.IMPORTANCE_LOW)
// NotificationImportance.min - No sound and does not appear in status bar (NotificationManager.IMPORTANCE_MIN)
// NotificationImportance.silent - No sound and no vibration (NotificationManager.IMPORTANCE_NONE)
```

These importance levels correspond directly to Android's `NotificationManager` importance constants.

## Swipe-to-Dismiss Capability

All notifications created with this plugin have built-in swipe-to-dismiss capability. Users can dismiss notifications by swiping them away.

## HTTP/JSON Notification Polling Details

The HTTP/JSON notification polling feature uses Android's WorkManager for background tasks with optimized battery consumption. The polling interval is configurable, and the plugin automatically restarts polling after device reboot.

```dart
// Start polling with a custom interval (in minutes)
await notificationMaster.startNotificationPolling(
  pollingUrl: 'https://your-api.com/notifications',
  intervalMinutes: 30, // Check every 30 minutes
);
```

### How Polling Works

1. When you call `startNotificationPolling()`, the plugin sets up a recurring background task using Android's WorkManager.
2. This task runs continuously in the background, checking for new notifications at the specified interval.
3. The service remains active indefinitely until you explicitly call `stopNotificationPolling()` or the device is shut down.
4. If the device is restarted, the polling service automatically resumes when the device boots up.
5. The service only makes network requests when the device has an internet connection, saving battery life.
6. WorkManager intelligently schedules the polling tasks to minimize battery impact, potentially batching them with other background tasks.

### Server Response Format

The server should return JSON in this format:
```json
{
  "notifications": [
    {
      "title": "Notification Title",
      "message": "Notification Message",
      "bigText": "Optional expanded text",
      "channelId": "Optional channel ID"
    }
  ]
}
```

## Permissions

For Android 13 and above (API level 33+), the plugin automatically manages the `POST_NOTIFICATIONS` permission. The permission request is shown to the user with a standard Android dialog:

```dart
// Check current permission status
final hasPermission = await notificationMaster.checkNotificationPermission();

// Request permission if needed
if (!hasPermission) {
  final granted = await notificationMaster.requestNotificationPermission();
  if (granted) {
    // Permission granted, show a notification
    await notificationMaster.showNotification(
      title: 'Permission Granted',
      message: 'Thank you for allowing notifications',
    );
  } else {
    // Permission denied, show a message to the user
    print('Please enable notifications in the app settings to receive important updates');
  }
}
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
