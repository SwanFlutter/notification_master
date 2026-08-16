# Notification Master

A comprehensive Flutter plugin for managing notifications across all platforms.

[![pub package](https://img.shields.io/pub/v/notification_master.svg)](https://pub.dev/packages/notification_master)
[![Pub Points](https://img.shields.io/pub/points/notification_master)](https://pub.dev/packages/permission_master/score)
[![Popularity](https://img.shields.io/pub/popularity/notification_master)](https://pub.dev/packages/permission_master)
[![Pub Likes](https://img.shields.io/pub/likes/notification_master)](https://pub.dev/packages/permission_master)
[![GitHub issues](https://img.shields.io/github/issues/SwanFlutter/notification_master)](https://github.com/SwanFlutter/permission_master/issues)
[![GitHub forks](https://img.shields.io/github/forks/SwanFlutter/notification_master)](https://github.com/SwanFlutter/permission_master/network/members)

---

## Platform Support

| Platform | Support | Features |
|----------|---------|----------|
| Android  | ✅ | Local notifications, custom channels, HTTP polling, Foreground Service |
| iOS      | ✅ | Local notifications, custom sounds, Badge, HTTP polling — **[See Guide](IOS_SETUP.md)** |
| macOS    | ✅ | Native notifications, HTTP polling, Background daemon |
| Windows  | ✅ | Toast notifications, 7 types, Alarm/Call scenarios, HTTP polling, Background daemon — **[See Guide](WINDOWS_NOTIFICATIONS_GUIDE.md)** |
| Web      | ✅ | Browser Notification API, Permission management |
| Linux    | ✅ | Desktop notifications (libnotify), HTTP polling, Background daemon |

---

## Screenshots

- Android

![Notification_master_github_showcase_e783d3a788](https://github.com/user-attachments/assets/fe87ddb1-4144-4ab7-b2b2-45c1096fbab2)

- iOS

![Notification_master_flutter_plugin_dc39493e02](https://github.com/user-attachments/assets/1fe98992-3c3e-41e4-84f9-6781f7883ed5)
![Notification_master_flutter_plugin_23ec37c185](https://github.com/user-attachments/assets/fffc9b58-08d9-40ae-802c-529ab89d0189)

- Windows

![Screenshot 2026-02-22 042326](https://github.com/user-attachments/assets/d6ad8ce9-63a0-4a19-b727-f792458fbe94)

- Web

![Screenshot 2026-02-22 105300](https://github.com/user-attachments/assets/ae9ca66b-a36b-4662-b941-00b611098e35)

- macOS

![photo_2026-02-25_04-47-00](https://github.com/user-attachments/assets/ab7da4c0-3e30-4b79-b23d-89cd45ed0c4c)

---

## Installation

```yaml
dependencies:
  notification_master: ^1.0.1
```

```bash
flutter pub get
```

---

## Table of Contents

1. [Platform Setup](#platform-setup)
   - [Android](#-android)
   - [iOS](#-ios)
   - [macOS](#-macos)
   - [Windows](#-windows)
   - [Linux](#-linux)
   - [Web](#-web)
2. [Basic Usage](#basic-usage)
3. [Notification Methods](#notification-methods)
4. [Channels](#createcustomchannel)
5. [Firebase & Push Notifications](#firebase--push-notifications)
6. [Service Management](#service-management)
7. [Complete Examples](#complete-examples)

---

## Platform Setup

### 🤖 Android

> ⚠️ The plugin does **not** declare any permissions in its own manifest. Add only the permissions your app actually uses to `android/app/src/main/AndroidManifest.xml`.

```xml
<!-- Required for all notification types -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />  <!-- Android 13+ -->

<!-- Required only if you use startForegroundService() -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />

<!-- Required only if you use startNotificationPolling() -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

<!-- Required only if you use scheduleNotification() -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />

<!-- Optional -->
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
```

Also update the `<activity>` tag:

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:enableOnBackInvokedCallback="true"
    ...>
```

---

### 🍎 iOS

#### 1. Podfile

```ruby
platform :ios, '14.0'
```

```bash
cd ios && pod install && cd ..
```

#### 2. Info.plist

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
    <string>processing</string>
</array>

<!-- Fixed value — do NOT replace with $(PRODUCT_BUNDLE_IDENTIFIER) -->
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.example.notification_master.polling</string>
</array>

<key>NSUserNotificationUsageDescription</key>
<string>This app sends notifications to keep you updated.</string>
```

#### 3. AppDelegate.swift

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
    UNUserNotificationCenter.current().delegate = self
    NotificationMasterPlugin.registerBackgroundTask()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound, .badge])
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    completionHandler()
  }
}
```

> ⚠️ **Common Issue:** If you get a CocoaPods deployment target error, see [IOS_DEPLOYMENT_TARGET_FIX.md](IOS_DEPLOYMENT_TARGET_FIX.md).
> 📖 **Full iOS guide:** [IOS_SETUP.md](IOS_SETUP.md)

---

### 🖥️ macOS

#### 1. Entitlements

Add to both `DebugProfile.entitlements` and `Release.entitlements`:

```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.usernotifications</key>
<true/>
```

#### 2. Info.plist

```xml
<key>NSUserNotificationUsageDescription</key>
<string>This app sends notifications to keep you updated.</string>
```

#### 3. AppDelegate.swift

```swift
import Cocoa
import FlutterMacOS
import UserNotifications

@main
class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {

  override func applicationDidFinishLaunching(_ notification: Notification) {
    UNUserNotificationCenter.current().delegate = self
    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound, .badge])
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    completionHandler()
  }
}
```

> No `import notification_master` or `registerBackgroundTask()` needed on macOS.

---

### 🪟 Windows

No additional setup required. The plugin auto-detects the platform.

**Supported features:**
- 7 notification types (Simple, Big Text, Image, Actions, Styled, Heads-Up, Full Screen)
- Alarm and IncomingCall scenarios with looping audio
- Action buttons, attribution text, image support
- Windows Action Center integration (Windows 10/11)

📖 **Full Windows guide:** [WINDOWS_NOTIFICATIONS_GUIDE.md](WINDOWS_NOTIFICATIONS_GUIDE.md)

---

### 🐧 Linux

Install system dependencies once on the build machine:

```bash
# Ubuntu / Debian
sudo apt-get install libnotify-dev libcurl4-openssl-dev libjson-glib-dev

# Fedora / RHEL
sudo dnf install libnotify-devel libcurl-devel json-glib-devel

# Arch
sudo pacman -S libnotify curl json-glib
```

No project-level config changes needed. The daemon binary is compiled automatically with `flutter build linux`.

---

### 🌐 Web

No setup required. The plugin uses the **Browser Notification API**.

> ⚠️ Requires Chrome, Firefox, or Edge. Safari has limited support. Background polling is not available on Web.

---

## Basic Usage

```dart
import 'package:notification_master/notification_master.dart';

final nm = NotificationMaster();

// Check and request permission
final granted = await nm.checkNotificationPermission();
if (!granted) await nm.requestNotificationPermission();

// Show a notification
await nm.showNotification(
  title: 'Hello',
  message: 'You have a new message',
);
```

---

## Notification Methods

### `showNotification()`

Basic notification for all platforms.

```dart
// Simple
await nm.showNotification(
  title: 'Welcome',
  message: 'Your app is ready',
);

// With all options
await nm.showNotification(
  id: 42,
  title: 'Order Confirmed',
  message: 'Order #42 has been confirmed',
  channelId: 'orders',
  importance: NotificationImportance.high,
  autoCancel: true,
  targetScreen: '/orders',
  extraData: {'orderId': '42'},
);
```

---

### `showStyledNotification()` ⭐

Shows the app icon on the left with full message text. Recommended over `showNotification()` on Android.

```dart
await nm.showStyledNotification(
  title: 'New Update Available',
  message: 'Version 2.0 is now available with new features',
  channelId: 'updates',
);
```

---

### `showBigTextNotification()`

Expandable notification with long text.

```dart
await nm.showBigTextNotification(
  title: 'Newsletter',
  message: 'Short summary here',
  bigText: 'This is the full text that appears when the notification is expanded...',
  importance: NotificationImportance.defaultImportance,
);
```

---

### `showImageNotification()`

Notification with an image loaded from a URL.

```dart
await nm.showImageNotification(
  title: 'New Photo',
  message: 'A friend sent you a photo',
  imageUrl: 'https://example.com/image.jpg',
  channelId: 'media',
);
```

---

### `showNotificationWithActions()`

Notification with tappable action buttons.

```dart
await nm.showNotificationWithActions(
  title: 'Incoming Call',
  message: 'Ali is calling',
  actions: [
    {'title': 'Answer', 'route': '/call/answer'},
    {'title': 'Decline', 'route': '/call/decline'},
  ],
);
```

---

### `showHeadsUpNotification()` ⭐

Appears as a banner from the top of the screen. Good for urgent messages.

```dart
await nm.showHeadsUpNotification(
  title: '🔔 Urgent Alert',
  message: 'This notification appears from the top of the screen',
);
```

---

### `showFullScreenNotification()` ⭐

Takes over the full screen — use for incoming calls or critical alerts only.

```dart
await nm.showFullScreenNotification(
  title: '📞 Incoming Call',
  message: 'John is calling you',
);
```

---

### Android Notification Hierarchy

From least to most intrusive:

| Type | Appears |
|------|---------|
| `showNotification()` | Notification bar only |
| `showStyledNotification()` | Notification bar with app icon |
| `showHeadsUpNotification()` | Banner from top of screen |
| `showFullScreenNotification()` | Entire screen (calls / alarms) |

---

### `createCustomChannel()`

Create a custom Android notification channel (Android 8.0+). Must be called before sending notifications to that channel.

```dart
await nm.createCustomChannel(
  channelId: 'order_updates',
  channelName: 'Order Updates',
  channelDescription: 'Notifications about your orders',
  importance: NotificationImportance.high,
  enableLights: true,
  lightColor: 0xFF00FF00,
  enableVibration: true,
  enableSound: true,
);

// Then use it
await nm.showStyledNotification(
  title: 'Order Shipped',
  message: 'Your order is on its way',
  channelId: 'order_updates',
);
```

---

## Notification Importance Levels

| Value | Behavior |
|-------|----------|
| `NotificationImportance.high` | Sound + vibration + banner |
| `NotificationImportance.defaultImportance` | Default OS behavior |
| `NotificationImportance.low` | No sound |
| `NotificationImportance.min` | Notification bar only, no sound |

---

## Firebase & Push Notifications

### `setFirebaseAsActiveService()`

Mark Firebase as the active notification delivery method.

```dart
await nm.setFirebaseAsActiveService();
```

---

### `getDeviceToken()`

Returns the best available push token for the current device. If `firebase_messaging` is in the project, returns the FCM token. Otherwise returns a device identifier.

```dart
final token = await nm.getDeviceToken();
print('Token: $token');
```

| Platform | Firebase present | Firebase absent |
|----------|-----------------|-----------------|
| Android | FCM token (~152 chars) | Android ID (16 hex) |
| iOS | APNS token (hex) | `identifierForVendor` UUID |
| macOS | — | machine hostname |
| Windows | — | MachineGuid from registry |
| Linux | — | `/etc/machine-id` or hostname |
| Web | — | stable UUID in localStorage |

> If you already use `firebase_messaging`, call `FirebaseMessaging.instance.getToken()` directly — `getDeviceToken()` is a convenience wrapper for when Firebase is optional.

---

### `subscribeToTopic()` / `unsubscribeFromTopic()`

Subscribe or unsubscribe from a notification topic. Works with or without Firebase.

```dart
await nm.subscribeToTopic('news');
await nm.unsubscribeFromTopic('news');

final topics = await nm.getSubscribedTopics();
print('Active topics: $topics');
```

**With Firebase:** Calls `FirebaseMessaging.subscribeToTopic()` and caches locally.
**Without Firebase:** Stores locally in SharedPreferences / UserDefaults — sync with your server manually.

---

## Service Management

Only one background service can be active at a time. Starting a new one automatically stops the previous.

| Service | Method | Battery | Reliability | Best for |
|---------|--------|---------|-------------|---------|
| Polling | `startNotificationPolling()` | Low | Medium | Periodic checks (15+ min) |
| Foreground Service | `startForegroundService()` | High | High | Continuous real-time (Android) |
| Firebase | `setFirebaseAsActiveService()` | Very Low | Very High | Server push |

```dart
// Check what's active
final service = await nm.getActiveNotificationService();
print('Active: $service'); // "polling", "foreground", "firebase", or "none"

// Stop all
await nm.stopNotificationPolling();
await nm.stopForegroundService();
```

---

## Complete Examples

### Example 1 — Firebase Push Notifications

This example shows how to use Firebase Cloud Messaging (FCM) with this plugin to receive server-sent push notifications.

**Prerequisites:** Add `firebase_messaging` and `firebase_core` to your `pubspec.yaml` and complete the Firebase project setup (google-services.json / GoogleService-Info.plist).

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:notification_master/notification_master.dart';

// Background message handler — must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final nm = NotificationMaster();
  await nm.showStyledNotification(
    title: message.notification?.title ?? 'New message',
    message: message.notification?.body ?? '',
    channelId: 'fcm_channel',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: FirebaseDemoPage());
  }
}

class FirebaseDemoPage extends StatefulWidget {
  const FirebaseDemoPage({super.key});
  @override
  State<FirebaseDemoPage> createState() => _FirebaseDemoPageState();
}

class _FirebaseDemoPageState extends State<FirebaseDemoPage> {
  final _nm = NotificationMaster();
  String _token = '';
  String _status = '';

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    // 1. Request permission
    final granted = await _nm.checkNotificationPermission();
    if (!granted) await _nm.requestNotificationPermission();

    // 2. Create channel for FCM messages (Android)
    await _nm.createCustomChannel(
      channelId: 'fcm_channel',
      channelName: 'Push Notifications',
      channelDescription: 'Firebase Cloud Messaging notifications',
      importance: NotificationImportance.high,
      enableVibration: true,
      enableSound: true,
    );

    // 3. Mark Firebase as active service
    await _nm.setFirebaseAsActiveService();

    // 4. Get the FCM token to send to your server
    final token = await _nm.getDeviceToken();
    setState(() => _token = token ?? 'unavailable');

    // 5. Subscribe to topics
    await _nm.subscribeToTopic('all_users');

    // 6. Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      _nm.showStyledNotification(
        title: message.notification?.title ?? 'New message',
        message: message.notification?.body ?? '',
        channelId: 'fcm_channel',
      );
    });

    // 7. Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final route = message.data['route'];
      if (route != null) {
        Navigator.of(context).pushNamed(route);
      }
    });

    setState(() => _status = 'Firebase ready');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Push Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $_status'),
            const SizedBox(height: 12),
            Text(
              'FCM Token:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SelectableText(_token, style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                // Test: show a local notification manually
                await _nm.showStyledNotification(
                  title: 'Test Notification',
                  message: 'This simulates a Firebase push message',
                  channelId: 'fcm_channel',
                );
              },
              child: const Text('Test Local Notification'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final topics = await _nm.getSubscribedTopics();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Topics: $topics')),
                );
              },
              child: const Text('Show Subscribed Topics'),
            ),
            const SizedBox(height: 8),
            // Send from server using FCM HTTP v1 API:
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade100,
              child: const Text(
                'Send from your server:\n'
                'POST https://fcm.googleapis.com/v1/projects/{id}/messages:send\n'
                '{\n'
                '  "message": {\n'
                '    "token": "<device_token>",\n'
                '    "notification": { "title": "Hello", "body": "World" },\n'
                '    "data": { "route": "/home" }\n'
                '  }\n'
                '}',
                style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### Example 2 — HTTP Polling (Local / Without Firebase)

This example shows how to poll your own server for notifications — no Firebase required.

**How it works:** The plugin periodically calls your API endpoint. When your server has new notifications, it returns them as JSON and the plugin displays them locally.

**Server JSON format:**

```json
{
  "notifications": [
    {
      "id": 1,
      "title": "New message",
      "message": "You have 3 unread messages",
      "imageUrl": "https://example.com/avatar.png",
      "bigText": "Optional expanded text",
      "importance": "high",
      "channelId": "messages"
    }
  ]
}
```

Return `"notifications": []` when there is nothing new — the plugin skips silently.

```dart
import 'package:flutter/material.dart';
import 'package:notification_master/notification_master.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: PollingDemoPage());
  }
}

class PollingDemoPage extends StatefulWidget {
  const PollingDemoPage({super.key});
  @override
  State<PollingDemoPage> createState() => _PollingDemoPageState();
}

class _PollingDemoPageState extends State<PollingDemoPage> {
  final _nm = NotificationMaster();
  String _activeService = 'none';

  // Replace with your actual API endpoint
  static const _pollingUrl = 'https://your-server.com/api/notifications';

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    // 1. Request permission
    final granted = await _nm.checkNotificationPermission();
    if (!granted) await _nm.requestNotificationPermission();

    // 2. Create channel (Android)
    await _nm.createCustomChannel(
      channelId: 'polling_channel',
      channelName: 'Polling Notifications',
      channelDescription: 'Notifications from server polling',
      importance: NotificationImportance.high,
      enableVibration: true,
      enableSound: true,
    );

    // 3. Check currently active service
    final service = await _nm.getActiveNotificationService();
    setState(() => _activeService = service);
  }

  // Option A: WorkManager / BGTaskScheduler (battery-friendly, OS may throttle)
  Future<void> _startPolling() async {
    await _nm.startNotificationPolling(
      pollingUrl: _pollingUrl,
      intervalMinutes: 15, // minimum enforced by WorkManager / BGTaskScheduler
    );
    final s = await _nm.getActiveNotificationService();
    setState(() => _activeService = s);
  }

  // Option B: Foreground Service (Android only — persistent, not throttled)
  Future<void> _startForegroundService() async {
    await _nm.startForegroundService(
      pollingUrl: _pollingUrl,
      intervalMinutes: 1,
      channelId: 'polling_channel',
      channelName: 'Polling Service',
      channelDescription: 'Background polling service',
      importance: NotificationImportance.low,
      enableVibration: false,
      enableSound: false,
    );
    final s = await _nm.getActiveNotificationService();
    setState(() => _activeService = s);
  }

  // Option C: Background Daemon (Windows / Linux / macOS — survives app close)
  Future<void> _startDaemon() async {
    final ok = await _nm.startBackgroundPollingService(
      pollingUrl: _pollingUrl,
      intervalMinutes: 1,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daemon binary not found. Run flutter build first.')),
      );
      return;
    }
    final s = await _nm.getActiveNotificationService();
    setState(() => _activeService = s);
  }

  Future<void> _stopAll() async {
    await _nm.stopNotificationPolling();
    await _nm.stopForegroundService();
    await _nm.stopBackgroundPollingService();
    final s = await _nm.getActiveNotificationService();
    setState(() => _activeService = s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HTTP Polling Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: _activeService == 'none'
                  ? Colors.grey.shade200
                  : Colors.green.shade100,
              child: Text(
                'Active service: $_activeService',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Android — WorkManager (battery-friendly):'),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: _startPolling,
              child: const Text('Start Polling (15 min interval)'),
            ),
            const SizedBox(height: 12),
            const Text('Android — Foreground Service (persistent):'),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: _startForegroundService,
              child: const Text('Start Foreground Service (1 min)'),
            ),
            const SizedBox(height: 12),
            const Text('Windows / Linux / macOS — Background Daemon:'),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: _startDaemon,
              child: const Text('Start Background Daemon (1 min)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: _stopAll,
              child: const Text(
                'Stop All',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Platform notes:\n'
              '• Android WorkManager: minimum ~15 min, OS may delay further\n'
              '• Android ForegroundService: shows persistent notification, not throttled\n'
              '• iOS: BGTaskScheduler minimum ~15 min, exact timing up to the OS\n'
              '• macOS/Windows/Linux daemon: survives app close, runs until stopped',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Windows Advanced: 7 Notification Types

```dart
// Styled (professional, with attribution text)
await nm.showStyledNotification(
  title: 'Meeting Reminder',
  message: 'Team meeting starts in 15 minutes',
);

// Heads-Up / Alarm (looping alarm sound, stays visible)
await nm.showHeadsUpNotification(
  title: '⏰ Timer Alert',
  message: 'Your 5-minute timer has finished',
);

// Full Screen / IncomingCall (looping ringtone)
await nm.showFullScreenNotification(
  title: '📞 Incoming Call',
  message: 'John Doe is calling you...',
);
```

📚 All 7 types with audio options: **[WINDOWS_NOTIFICATIONS_GUIDE.md](WINDOWS_NOTIFICATIONS_GUIDE.md)**

---

## Troubleshooting

**No sound on custom channel** — make sure `enableSound: true` is set when calling `createCustomChannel()`.

**No app icon in notification** — use `showStyledNotification()` instead of `showNotification()`.

**Notification not showing on Android 13+** — call `requestNotificationPermission()` before showing any notification.

**iOS background polling not firing** — iOS BGTaskScheduler fires at OS discretion (~15 min minimum). This is expected behavior.

**Windows daemon not starting** — run `flutter build windows` first so the `notification_master_poller.exe` binary exists next to your app.

---

## Important Notes

- The plugin does **not** auto-declare Android permissions. Add only what your app uses.
- Foreground Service is Android-only. Use the background daemon on desktop platforms.
- Background polling is not available on Web.
- Channels are only effective on Android 8.0+; ignored elsewhere.
- iOS requires iOS 14.0+.
- macOS polling uses an in-process `Timer` — stops when app closes. Use `startBackgroundPollingService()` for daemon mode.

---

## License

MIT License — see the [LICENSE](LICENSE) file for details.
