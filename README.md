# Notification Master

A comprehensive, production-ready Flutter plugin for managing notifications across all platforms with advanced features including HTTP polling, custom notification channels, foreground services, and platform-specific optimizations.

## 🌟 Key Features

- ✅ **Multi-Platform Support**: Android, iOS, Web, Linux, macOS, Windows
- 🔄 **HTTP Polling**: Automatic background notification fetching from your server
- 🚀 **Foreground Service**: Reliable notification delivery even when app is closed (Android)
- 📱 **Rich Notifications**: Big text, images, action buttons, custom channels
- 🎨 **Customizable**: Channel importance, sounds, vibration, LED colors
- 🔔 **Multiple Service Types**: WorkManager polling, Foreground service, Firebase integration
- 🎯 **Navigation Support**: Deep linking to specific screens from notifications
- 🔐 **Permission Handling**: Built-in permission request and checking

## 📊 Platform Support

| Platform | Support | Features |
|----------|---------|----------|
| Android  | ✅ Full | Local notifications, custom channels, importance levels, auto-cancel, custom icons, HTTP polling, foreground service |
| iOS      | ✅ Full | Local notifications, custom sounds, badges, HTTP polling, rich notifications |
| macOS    | ✅ Full | Native notifications, custom sounds, badges, HTTP polling |
| Windows  | ✅ Full | Toast notifications, custom actions, HTTP polling |
| Web      | ✅ Full | Browser notifications, permission handling, HTTP polling |
| Linux    | ✅ Full | Desktop notifications, custom icons, HTTP polling |

## 📦 Installation

Add this plugin to your project's `pubspec.yaml` file:

```yaml
dependencies:
  notification_master: ^0.0.4
```

Then run:

```bash
flutter pub get
```

## ⚙️ Platform Setup

### Android Setup

Add the following permissions to your `android/app/src/main/AndroidManifest.xml` file inside the `<manifest>` tag:

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

**Note:** The plugin automatically handles `android:enableOnBackInvokedCallback="true"` configuration.

### iOS Setup

For iOS-specific setup instructions, see [IOS_README.md](IOS_README.md).

## 🚀 Quick Start

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
    print('Notification permission denied');
    return;
  }
}
```

## 📱 Basic Usage

### Simple Notifications

```dart
// Display a simple notification
await notificationMaster.showNotification(
  title: 'Hello',
  message: 'This is a simple notification',
);

// Display a notification with custom ID
await notificationMaster.showNotification(
  id: 123,
  title: 'Custom ID',
  message: 'This notification has a custom ID',
);

// Display a high importance notification (Android)
await notificationMaster.showNotification(
  title: 'Important!',
  message: 'This is a high importance notification',
  importance: NotificationImportance.high,
);

// Display a persistent notification (doesn't auto-cancel on tap)
await notificationMaster.showNotification(
  title: 'Persistent',
  message: 'This notification stays after tap',
  autoCancel: false,
);

// Display a notification with navigation
await notificationMaster.showNotification(
  title: 'Open Settings',
  message: 'Tap to open settings screen',
  targetScreen: '/settings',
  extraData: {'userId': '123', 'action': 'view'},
);
```


### Rich Notifications

```dart
// Big text notification (expandable)
await notificationMaster.showBigTextNotification(
  title: 'Article Update',
  message: 'New article published',
  bigText: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
           'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
           'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.',
);

// Image notification
await notificationMaster.showImageNotification(
  title: 'New Photo',
  message: 'John shared a photo with you',
  imageUrl: 'https://example.com/photo.jpg',
);

// Notification with action buttons
await notificationMaster.showNotificationWithActions(
  title: 'Meeting Reminder',
  message: 'Team meeting in 10 minutes',
  actions: [
    {'title': 'Join', 'route': '/meeting'},
    {'title': 'Snooze', 'route': '/snooze'},
    {'title': 'Dismiss', 'route': '/dismiss'},
  ],
);
```

### Custom Notification Channels (Android 8.0+)

```dart
// Create a high priority channel with sound and vibration
await notificationMaster.createCustomChannel(
  channelId: 'urgent_channel',
  channelName: 'Urgent Notifications',
  channelDescription: 'For time-sensitive notifications',
  importance: NotificationImportance.high,
  enableLights: true,
  lightColor: 0xFFFF0000, // Red
  enableVibration: true,
  enableSound: true,
);

// Create a silent channel
await notificationMaster.createCustomChannel(
  channelId: 'silent_channel',
  channelName: 'Silent Notifications',
  channelDescription: 'No sound or vibration',
  importance: NotificationImportance.min,
  enableLights: false,
  enableVibration: false,
  enableSound: false,
);

// Use the custom channel
await notificationMaster.showNotification(
  title: 'Urgent!',
  message: 'This uses the urgent channel',
  channelId: 'urgent_channel',
);
```

## 🔄 HTTP Polling - Automatic Notification Fetching

One of the most powerful features of Notification Master is the ability to automatically fetch notifications from your server at regular intervals. This is perfect for apps that need to display server-side notifications without implementing Firebase Cloud Messaging.

📖 **For detailed HTTP Polling guide, see [HTTP_POLLING_GUIDE.md](HTTP_POLLING_GUIDE.md)**

### How HTTP Polling Works

The plugin periodically sends HTTP GET requests to your server and processes the JSON response to display notifications. You can choose between two polling methods:

1. **Background Polling (WorkManager)**: Battery-efficient, but may stop when app is closed
2. **Foreground Service**: More reliable, continues even when app is closed, but shows a persistent notification

### Server Response Format

Your server should return a JSON response in this format:

```json
{
  "notifications": [
    {
      "title": "Notification Title",
      "message": "Notification message body",
      "bigText": "Optional expanded text for big text style",
      "channelId": "Optional custom channel ID"
    },
    {
      "title": "Another Notification",
      "message": "Another message"
    }
  ]
}
```

### Background Polling (WorkManager)

Best for non-critical notifications. Uses Android WorkManager for battery-efficient background tasks.

```dart
// Start background polling
final success = await notificationMaster.startNotificationPolling(
  pollingUrl: 'https://your-server.com/api/notifications',
  intervalMinutes: 15, // Check every 15 minutes
);

if (success) {
  print('Background polling started');
}

// Stop background polling
await notificationMaster.stopNotificationPolling();
```

**Pros:**
- Battery efficient
- Respects Android's battery optimization
- Good for non-critical notifications

**Cons:**
- May stop when app is closed or device is in Doze mode
- Not guaranteed to run at exact intervals

### Foreground Service Polling (Recommended for Reliability)

Best for critical notifications. Creates a persistent notification but ensures reliable delivery.

```dart
// Start foreground service with custom channel
final success = await notificationMaster.startForegroundService(
  pollingUrl: 'https://your-server.com/api/notifications',
  intervalMinutes: 15,
  channelId: 'polling_service',
  channelName: 'Notification Service',
  channelDescription: 'Keeps the app checking for new notifications',
  importance: NotificationImportance.low, // Low importance for the service notification
  enableSound: false,
  enableVibration: false,
);

if (success) {
  print('Foreground service started');
}

// Stop foreground service
await notificationMaster.stopForegroundService();
```

**Pros:**
- Continues running even when app is closed
- More reliable notification delivery
- Not affected by battery optimization

**Cons:**
- Shows a persistent notification (required by Android)
- Slightly higher battery usage

### Check Active Service

```dart
// Get the currently active notification service
final activeService = await notificationMaster.getActiveNotificationService();

switch (activeService) {
  case 'none':
    print('No notification service is active');
    break;
  case 'polling':
    print('Background polling is active');
    break;
  case 'foreground':
    print('Foreground service is active');
    break;
  case 'firebase':
    print('Firebase Cloud Messaging is active');
    break;
}
```

### Complete HTTP Polling Example

```dart
import 'package:flutter/material.dart';
import 'package:notification_master/notification_master.dart';

class NotificationPollingExample extends StatefulWidget {
  @override
  _NotificationPollingExampleState createState() => _NotificationPollingExampleState();
}

class _NotificationPollingExampleState extends State<NotificationPollingExample> {
  final _notificationMaster = NotificationMaster();
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  Future<void> _setupNotifications() async {
    // Request permission
    final hasPermission = await _notificationMaster.checkNotificationPermission();
    if (!hasPermission) {
      await _notificationMaster.requestNotificationPermission();
    }

    // Create custom channels
    await _notificationMaster.createCustomChannel(
      channelId: 'server_notifications',
      channelName: 'Server Notifications',
      channelDescription: 'Notifications from server',
      importance: NotificationImportance.high,
      enableSound: true,
      enableVibration: true,
    );

    // Check if polling is already active
    final activeService = await _notificationMaster.getActiveNotificationService();
    setState(() {
      _isPolling = activeService == 'polling' || activeService == 'foreground';
    });
  }

  Future<void> _togglePolling() async {
    if (_isPolling) {
      // Stop polling
      await _notificationMaster.stopNotificationPolling();
      await _notificationMaster.stopForegroundService();
      setState(() => _isPolling = false);
    } else {
      // Start foreground service for reliable delivery
      final success = await _notificationMaster.startForegroundService(
        pollingUrl: 'https://your-server.com/api/notifications',
        intervalMinutes: 15,
        channelId: 'polling_service',
        channelName: 'Notification Service',
        importance: NotificationImportance.low,
      );
      
      if (success) {
        setState(() => _isPolling = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('HTTP Polling Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isPolling ? 'Polling Active' : 'Polling Inactive',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _togglePolling,
              child: Text(_isPolling ? 'Stop Polling' : 'Start Polling'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Server Implementation Example (PHP)

```php
<?php
header('Content-Type: application/json');

// Example: Return notifications from database or any source
$notifications = [
    [
        'title' => 'New Message',
        'message' => 'You have a new message from John',
        'bigText' => 'John says: Hey, are you available for a meeting tomorrow at 10 AM?',
        'channelId' => 'server_notifications'
    ],
    [
        'title' => 'System Update',
        'message' => 'A new update is available',
        'channelId' => 'server_notifications'
    ]
];

echo json_encode(['notifications' => $notifications]);
?>
```

### Server Implementation Example (Node.js/Express)

```javascript
const express = require('express');
const app = express();

app.get('/api/notifications', (req, res) => {
  const notifications = [
    {
      title: 'New Message',
      message: 'You have a new message from John',
      bigText: 'John says: Hey, are you available for a meeting tomorrow at 10 AM?',
      channelId: 'server_notifications'
    },
    {
      title: 'System Update',
      message: 'A new update is available',
      channelId: 'server_notifications'
    }
  ];

  res.json({ notifications });
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

## 🔥 Firebase Integration

If you're using Firebase Cloud Messaging, you can set it as the active service:

```dart
// Set Firebase as the active notification service
// This will disable any other active notification services (polling or foreground)
await notificationMaster.setFirebaseAsActiveService();
```

## 🎯 Navigation & Deep Linking

Handle notification taps and navigate to specific screens:

```dart
// Show notification with navigation data
await notificationMaster.showNotification(
  title: 'Order Delivered',
  message: 'Your order #12345 has been delivered',
  targetScreen: '/order-details',
  extraData: {
    'orderId': '12345',
    'status': 'delivered',
    'timestamp': DateTime.now().toIso8601String(),
  },
);

// In your app, handle the navigation
// The plugin will automatically navigate to the targetScreen
// and pass the extraData as route arguments
```

## 📋 Notification Importance Levels (Android)

```dart
enum NotificationImportance {
  min,      // Minimal importance, no sound
  low,      // Low importance, no sound
  defaultImportance, // Default importance, makes sound
  high,     // High importance, makes sound and appears as heads-up
  max,      // Maximum importance, makes sound and appears as heads-up
}
```

## 🔧 Advanced Features

### Check Permission Status

```dart
final hasPermission = await notificationMaster.checkNotificationPermission();
if (!hasPermission) {
  // Show explanation to user before requesting
  final granted = await notificationMaster.requestNotificationPermission();
}
```

### Get Platform Version

```dart
final version = await notificationMaster.getPlatformVersion();
print('Platform version: $version');
```

## 📱 Platform-Specific Notes

### Android
- Requires Android 7.0+ (API level 24+)
- Notification permission required for Android 13+ (API level 33+)
- Custom channels supported on Android 8.0+ (API level 26+)
- Foreground service requires `FOREGROUND_SERVICE` permission

### iOS
- Requires iOS 10.0+
- Permission request shows system dialog
- Custom sounds must be added to the app bundle

### Web
- Requires HTTPS (except localhost)
- Permission request shows browser dialog
- Not all features supported (e.g., custom channels)

### Desktop (Linux, macOS, Windows)
- Native notification system integration
- Some features may vary by platform

## 🐛 Troubleshooting

### Notifications not showing on Android 13+
Make sure you've requested the `POST_NOTIFICATIONS` permission:
```dart
await notificationMaster.requestNotificationPermission();
```

### HTTP Polling not working
1. Check that you've added `INTERNET` permission to AndroidManifest.xml
2. Verify your server URL is correct and accessible
3. Ensure your server returns the correct JSON format
4. For emulators, use `10.0.2.2` instead of `localhost`

### Foreground service stops unexpectedly
1. Make sure you've added all required permissions
2. Check that battery optimization is disabled for your app
3. Verify the polling URL is valid and returns proper JSON

### Notifications not showing on iOS
1. Check that you've configured iOS permissions correctly
2. Verify notification permission is granted
3. Check iOS notification settings for your app

## 📚 Example App

Check out the [example](example/) directory for a complete working example with:
- Simple notifications
- Rich notifications (big text, images, actions)
- Custom channels
- HTTP polling (both background and foreground)
- Service management
- Platform-specific examples

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Links

- [GitHub Repository](https://github.com/SwanFlutter/notification_master)
- [pub.dev Package](https://pub.dev/packages/notification_master)
- [Issue Tracker](https://github.com/SwanFlutter/notification_master/issues)

## 📞 Support

If you have any questions or issues, please:
1. Check the [example app](example/)
2. Read the [documentation](https://pub.dev/packages/notification_master)
3. Open an [issue on GitHub](https://github.com/SwanFlutter/notification_master/issues)

---


