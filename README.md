
# Notification Master

A comprehensive Flutter plugin for managing notifications across all platforms.

---

[![Pub Points](https://img.shields.io/pub/points/permission_master)](https://pub.dev/packages/permission_master/score)
[![Popularity](https://img.shields.io/pub/popularity/permission_master)](https://pub.dev/packages/permission_master)
[![Pub Likes](https://img.shields.io/pub/likes/permission_master)](https://pub.dev/packages/permission_master)
[![GitHub issues](https://img.shields.io/github/issues/SwanFlutter/permission_master)](https://github.com/SwanFlutter/permission_master/issues)
[![GitHub forks](https://img.shields.io/github/forks/SwanFlutter/permission_master)](https://github.com/SwanFlutter/permission_master/network/members)

---


## Platform Support

| Platform | Support | Features                                                                 |
|----------|---------|--------------------------------------------------------------------------|
| Android  | ✅      | Local notifications, custom channels, HTTP polling, Foreground Service  |
| iOS      | ✅      | Local notifications, custom sounds, Badge, HTTP polling                 |
| macOS    | ✅      | Native notifications, HTTP polling                                      |
| Windows  | ✅      | Toast notifications, 7 types, Alarm/Call scenarios, HTTP polling - **[See Guide](WINDOWS_NOTIFICATIONS_GUIDE.md)** |
| Web      | ✅      | Browser Notification API, Permission management                         |
| Linux    | ✅      | Desktop notifications, HTTP polling                                     |

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  notification_master: ^0.0.7
```

Run:


```bash
flutter pub get
```

---

- Android

![Notification_master_github_showcase_e783d3a788](https://github.com/user-attachments/assets/fe87ddb1-4144-4ab7-b2b2-45c1096fbab2)


- Ios


![Notification_master_flutter_plugin_dc39493e02](https://github.com/user-attachments/assets/1fe98992-3c3e-41e4-84f9-6781f7883ed5)
![Notification_master_flutter_plugin_23ec37c185](https://github.com/user-attachments/assets/fffc9b58-08d9-40ae-802c-529ab89d0189)


- Windows


![Screenshot 2026-02-22 042326](https://github.com/user-attachments/assets/d6ad8ce9-63a0-4a19-b727-f792458fbe94)

- Web

![Screenshot 2026-02-22 105300](https://github.com/user-attachments/assets/ae9ca66b-a36b-4662-b941-00b611098e35)


- Mac

![photo_2026-02-25_04-47-00](https://github.com/user-attachments/assets/ab7da4c0-3e30-4b79-b23d-89cd45ed0c4c)



## Platform Setup

### 🤖 Android

Add the following permissions to your app's `android/app/src/main/AndroidManifest.xml` inside the `<manifest>` tag:

```xml
<!-- Required: Internet access for HTTP polling -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- Required for Android 13+ (API 33+): show notifications -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Required: run a foreground service -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />

<!-- Required: foreground service type for HTTP data sync (polling) -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />

<!-- Required: restart polling after device reboot -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

<!-- Optional: vibrate on notification -->
<uses-permission android:name="android.permission.VIBRATE" />

<!-- Optional: keep CPU awake during polling -->
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

Also update the `<activity>` tag in the same file:

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

Make sure `ios/Podfile` starts with:

```ruby
platform :ios, '14.0'
```

After changing, run:

```bash
cd ios
pod install
cd ..
```

#### 2. Info.plist

Add to `ios/Runner/Info.plist` inside the `<dict>` tag:

```xml
<!-- Required: background execution modes -->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
    <string>processing</string>
</array>

<!-- Required: must match the identifier used inside the plugin (fixed value) -->
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.example.notification_master.polling</string>
</array>

<!-- Required: explain why the app sends notifications -->
<key>NSUserNotificationUsageDescription</key>
<string>This app sends notifications to keep you updated.</string>
```

> ⚠️ **Important:** The identifier `com.example.notification_master.polling` is a fixed string hardcoded in the plugin's Swift source. Do **not** replace it with `$(PRODUCT_BUNDLE_IDENTIFIER)` — that would break background task registration.

#### 3. AppDelegate.swift

Replace the content of `ios/Runner/AppDelegate.swift` with:

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

**Why these are required:**
- `import notification_master` — needed to call `NotificationMasterPlugin.registerBackgroundTask()`
- `UNUserNotificationCenterDelegate` — needed to show notifications when app is in foreground
- `registerBackgroundTask()` — registers the background polling task with iOS
- Without `willPresent`, notifications are silently dropped while the app is open

**⚠️ Common Issue — Deployment Target Error:**
If you get a CocoaPods error about minimum deployment target:
- English: [IOS_DEPLOYMENT_TARGET_FIX.md](IOS_DEPLOYMENT_TARGET_FIX.md)
- فارسی: [IOS_DEPLOYMENT_TARGET_FIX_FA.md](IOS_DEPLOYMENT_TARGET_FIX_FA.md)

**📖 Complete iOS setup guide:**
- English: [IOS_SETUP.md](IOS_SETUP.md)
- فارسی: [IOS_SETUP_FA.md](IOS_SETUP_FA.md)

---

### 🌐 Web

No additional setup required. The plugin uses the **Browser Notification API**.
⚠️ The browser must support the Notification API (Chrome, Firefox, Edge).

---

### 🖥️ macOS

#### 1. Entitlements

Add to **both** `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:

```xml
<!-- Required: outbound network access (for HTTP polling) -->
<key>com.apple.security.network.client</key>
<true/>

<!-- Required: show local notifications from the macOS sandbox -->
<key>com.apple.security.usernotifications</key>
<true/>
```

#### 2. Info.plist

Add to `macos/Runner/Info.plist` inside the `<dict>` tag:

```xml
<!-- Required: must match the identifier used inside the plugin (fixed value) -->
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.example.notification_master.polling</string>
</array>

<!-- Required: explain why the app sends notifications -->
<key>NSUserNotificationUsageDescription</key>
<string>This app sends notifications to keep you updated.</string>
```

#### 3. AppDelegate.swift

Replace the content of `macos/Runner/AppDelegate.swift` with:

```swift
import Cocoa
import FlutterMacOS
import notification_master
import UserNotifications

@main
class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Required: show notifications while app is in foreground
    UNUserNotificationCenter.current().delegate = self

    // Required: register background polling task
    NotificationMasterPlugin.registerBackgroundTask()

    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
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

---

### 🪟 Windows

No additional setup required. The plugin auto-detects the platform.

**Windows-Specific Features:**
- ✅ Native Windows Toast Notifications (WinRT API)
- ✅ 7 notification types (Simple, Big Text, Image, Actions, Styled, Heads-Up, Full Screen)
- ✅ Multiple notification scenarios (Default, Alarm, IncomingCall)
- ✅ Custom audio support (Alarm, Call, SMS, Mail, Reminder, etc.)
- ✅ Action buttons with callbacks
- ✅ Attribution text for branding
- ✅ Image support with auto-download
- ✅ Long duration notifications
- ✅ Windows Action Center integration
- ✅ Windows 10/11 compatible

**📖 Complete Windows Guide:**
For detailed documentation, code examples, and best practices for all Windows notification types, see:
- **[Windows Notifications Guide](WINDOWS_NOTIFICATIONS_GUIDE.md)** - Complete guide with examples for all 7 notification types

---

### 🐧 Linux

No additional setup required. The plugin auto-detects the platform.

---

## 🪟 Windows Advanced Features

Windows supports advanced notification types with unique scenarios and audio options:

### Notification Types on Windows:
1. **Simple Toast** - Basic notification
2. **Big Text** - Expandable long text
3. **Image** - Notification with image (local or URL)
4. **Actions** - Interactive buttons
5. **Styled** ⭐ - Professional appearance with attribution text
6. **Heads-Up (Alarm)** ⏰ - High priority with alarm sound (looping)
7. **Full Screen (Call)** 📞 - Incoming call style (looping ringtone)

### Quick Example:
```dart
// Styled notification (professional)
await notificationMaster.showStyledNotification(
  title: 'Meeting Reminder',
  message: 'Team meeting starts in 15 minutes',
);

// Heads-Up (Alarm scenario - stays visible, alarm sound)
await notificationMaster.showHeadsUpNotification(
  title: 'Timer Alert!',
  message: 'Your 5-minute timer has finished',
);

// Full Screen (Call scenario - like incoming call)
await notificationMaster.showFullScreenNotification(
  title: '📞 Incoming Call',
  message: 'John Doe is calling you...',
);
```

**📚 Complete Windows Documentation:**
- **[Windows Notifications Guide](WINDOWS_NOTIFICATIONS_GUIDE.md)** - Detailed guide with all examples, scenarios, audio options, and platform comparison

---

## Basic Usage

### Import

```dart
import 'package:notification_master/notification_master.dart';
```

---

## Methods & Examples

### `checkNotificationPermission()`

Check notification permission status.

```dart
final notificationMaster = NotificationMaster();

bool hasPermission = await notificationMaster.checkNotificationPermission();
print('Permission granted: $hasPermission');
```

---

### `requestNotificationPermission()`

Request permission from the user (required for Android 13+, iOS, and Web).

```dart
final granted = await notificationMaster.requestNotificationPermission();
if (!granted) {
  print('User denied permission');
}
```

---

### `showNotification()`

Display a simple notification.

**Parameters:**
- `id` (optional): Unique notification ID
- `title` (required): Title
- `message` (required): Message
- `channelId`: Channel ID (Android)
- `importance`: Importance level
- `autoCancel`: Auto-close after tap
- `targetScreen`: Navigation route
- `extraData`: Additional data

```dart
// Simplest form
await notificationMaster.showNotification(
  title: 'Welcome',
  message: 'Your app is ready',
);

// With custom ID
await notificationMaster.showNotification(
  id: 42,
  title: 'Order Confirmed',
  message: 'Order #42 has been confirmed',
);

// High importance
await notificationMaster.showNotification(
  title: 'Warning!',
  message: 'Battery is low',
  importance: NotificationImportance.high,
);

// With navigation
await notificationMaster.showNotification(
  title: 'New Message',
  message: 'You have a new message',
  targetScreen: '/messages',
  extraData: {'messageId': '123'},
);

// Persistent notification (no auto-cancel)
await notificationMaster.showNotification(
  title: 'Downloading...',
  message: 'File is downloading',
  autoCancel: false,
);
```

---

### `showStyledNotification()` ⭐ NEW

Display a styled notification with app icon and full text (like modern Android notifications).

**Features:**
- App icon displayed on the left
- Full message text shown
- Sound and vibration enabled
- Timestamp displayed

```dart
await notificationMaster.showStyledNotification(
  title: 'New Update Available',
  message: 'Version 2.0 is now available with new features and improvements',
  channelId: 'updates', // optional
);
```

---

### `showHeadsUpNotification()` ⭐ NEW

Display a heads-up notification that appears from the top of the screen with padding.

**Features:**
- Appears from top of screen
- Has padding around it
- Custom UI styling
- Perfect for urgent messages

```dart
await notificationMaster.showHeadsUpNotification(
  title: '🔔 Urgent Alert',
  message: 'This notification appears from the top of the screen',
);
```

---

### `showFullScreenNotification()` ⭐ NEW

Display a full-screen notification (most intrusive, like incoming calls).

**Features:**
- Takes over the entire screen
- Used for very important alerts
- Similar to incoming call notifications

```dart
await notificationMaster.showFullScreenNotification(
  title: '📞 Incoming Call',
  message: 'John is calling you',
);
```

---

### `showBigTextNotification()`

Notification with expandable long text.

```dart
await notificationMaster.showBigTextNotification(
  title: 'Breaking News',
  message: 'News summary here',
  bigText: 'This is the full and long news text that will be displayed '
           'after expanding the notification and can span multiple paragraphs...',
  importance: NotificationImportance.defaultImportance,
);
```

---

### `showImageNotification()`

Notification with an image.

```dart
await notificationMaster.showImageNotification(
  title: 'New Photo',
  message: 'A friend sent you a photo',
  imageUrl: 'https://example.com/image.jpg',
  channelId: 'media_channel',
);
```

---

### `showNotificationWithActions()`

Notification with action buttons.

```dart
await notificationMaster.showNotificationWithActions(
  title: 'Incoming Call',
  message: 'Ali is calling',
  actions: [
    {'title': 'Answer', 'route': '/call/answer'},
    {'title': 'Reject', 'route': '/call/reject'},
  ],
);
```

---

### `createCustomChannel()`

Create a custom channel (Android 8.0+).

**Important:** Custom channels now properly support sound, vibration, and lights!

```dart
await notificationMaster.createCustomChannel(
  channelId: 'order_updates',
  channelName: 'Order Updates',
  channelDescription: 'Notifications about order status',
  importance: NotificationImportance.high,
  enableLights: true,
  lightColor: 0xFF00FF00,
  enableVibration: true,
  enableSound: true, // ✅ Sound now works properly!
);

// Use the channelId in styled notifications:
await notificationMaster.showStyledNotification(
  title: 'Order Shipped',
  message: 'Your order has been shipped and is on its way',
  channelId: 'order_updates',
);
```

---

## Android Notification Types

### Standard vs Styled Notifications

**Standard Notification:**
- Basic notification without app icon
- Text may be truncated
- Minimal styling

**Styled Notification (Recommended):** ⭐
- App icon displayed on the left
- Full text shown
- Timestamp displayed
- Better visual appearance

```dart
// Use styled notifications for better UX
await notificationMaster.showStyledNotification(
  title: 'New Message',
  message: 'You have received a new message from John',
);
```

### Notification Hierarchy (by intrusiveness)

1. **Standard Notification** - Appears only in notification bar
2. **Styled Notification** - Appears in notification bar with app icon
3. **Heads-Up Notification** - Appears from top of screen with padding
4. **Full Screen Notification** - Takes over entire screen (like calls)

---

## Troubleshooting

### No Sound on Custom Channels
✅ **Fixed!** Custom channels now properly support sound. Make sure to set `enableSound: true` when creating the channel.

### No App Icon in Notifications
✅ **Fixed!** Use `showStyledNotification()` instead of `showNotification()` to display the app icon.

### Notification Not Showing
- Check if permission is granted (Android 13+)
- Verify channel is created before sending notification
- Check Logcat for error messages (filter by "NotificationHelper")

---

### `startNotificationPolling()`

Start periodic polling from a URL to receive notifications.

Expected JSON response format:

```json
{
  "notifications": [
    {
      "id": 1,
      "title": "Title",
      "message": "Notification message",
      "imageUrl": "https://...",
      "bigText": "Long text...",
      "importance": "high",
      "channelId": "my_channel"
    }
  ]
}
```

```dart
await notificationMaster.startNotificationPolling(
  pollingUrl: 'https://api.example.com/notifications',
  intervalMinutes: 15,
);
```

---

### `stopNotificationPolling()`

Stop polling.

```dart
await notificationMaster.stopNotificationPolling();
```

---

### `startForegroundService()`

Start a Foreground Service for continuous polling (Android only).

```dart
await notificationMaster.startForegroundService(
  pollingUrl: 'https://api.example.com/notifications',
  intervalMinutes: 10,
  channelId: 'service_channel',
  channelName: 'Notification Service',
  channelDescription: 'Background service for notifications',
  importance: NotificationImportance.low,
  enableVibration: false,
  enableSound: false,
);
```

---

### `stopForegroundService()`

Stop the Foreground Service.

```dart
await notificationMaster.stopForegroundService();
```

---

### `setFirebaseAsActiveService()`

Set Firebase Cloud Messaging as the active service.

```dart
final success = await notificationMaster.setFirebaseAsActiveService();
print('FCM activated: $success');
```

---

### `getActiveNotificationService()`

Get the name of the active notification service.

```dart
final service = await notificationMaster.getActiveNotificationService();
print('Active service: $service'); // e.g., "firebase" or "none"
```

---

### `getDeviceToken()`

A convenience wrapper that returns whatever push identifier is available on the current device.

> **Important:** If your project already uses `firebase_messaging`, call `FirebaseMessaging.instance.getToken()` directly — that is the canonical way to get an FCM token. `getDeviceToken()` is useful when you want a single cross-platform call that works even without Firebase in the project.

```dart
final token = await notificationMaster.getDeviceToken();

// Identify the source:
// FCM token  → length ~152  (only when firebase_messaging is in the project)
// Android ID → 16 hex chars (Firebase not present on Android)
// UUID       → 36 chars     (iOS identifierForVendor, macOS hostName, etc.)
print('Token: $token');
```

**What you receive per platform:**

| Platform | Firebase present | Firebase absent |
|----------|-----------------|-----------------|
| Android | FCM token (~152 chars) | Android ID (16 hex) |
| iOS | APNS token (hex) | `identifierForVendor` UUID |
| macOS | — | machine hostname |
| Windows | — | MachineGuid from registry |
| Linux | — | `/etc/machine-id` or hostname |
| Web | — | stable UUID in localStorage |

**When Firebase is absent**, pair the token with `getSubscribedTopics()` and register both on your own server. Your server is then responsible for sending push notifications to the right devices.

---

### `subscribeToTopic(String topic)`

Subscribe to a notification topic. Always succeeds — with Firebase it subscribes via FCM, without Firebase it stores the subscription locally so you can sync it to your server.

```dart
final success = await notificationMaster.subscribeToTopic('news');
print('Subscribed: $success');
```

**Platform behavior:**
- **Android with Firebase**: Calls `FirebaseMessaging.getInstance().subscribeToTopic()` and also saves locally
- **Android without Firebase**: Saves to `SharedPreferences` — use with `getDeviceToken()` + `getSubscribedTopics()` to manage subscriptions server-side
- **iOS**: Saves locally to `UserDefaults` — combine with `getDeviceToken()` to manage subscriptions server-side
- **Web/Desktop**: Not supported

---

### `unsubscribeFromTopic(String topic)`

Unsubscribe from a notification topic. Always succeeds — with Firebase it unsubscribes via FCM, without Firebase it removes the local record.

```dart
final success = await notificationMaster.unsubscribeFromTopic('news');
print('Unsubscribed: $success');
```

**Platform behavior:**
- **Android with Firebase**: Calls `FirebaseMessaging.getInstance().unsubscribeFromTopic()` and removes locally
- **Android without Firebase**: Removes from `SharedPreferences`
- **iOS**: Removes from `UserDefaults`
- **Web/Desktop**: Not supported

---

### `getSubscribedTopics()`

Returns the list of topics the device is currently subscribed to. This is the same list that both `subscribeToTopic` and `unsubscribeFromTopic` maintain, regardless of whether Firebase is present.

```dart
final topics = await notificationMaster.getSubscribedTopics();
print('Active topics: $topics'); // e.g. ['news', 'offers', 'alerts']
```

**Platform behavior:**
- **Android with Firebase**: Returns locally cached list (mirrors FCM subscriptions)
- **Android / iOS without Firebase**: Returns locally stored list

#### Complete server-side topic workflow (without Firebase)

```dart
final notificationMaster = NotificationMaster();

// 1. Get the unique device identifier
final token = await notificationMaster.getDeviceToken();

// 2. Subscribe the device to one or more topics
await notificationMaster.subscribeToTopic('news');
await notificationMaster.subscribeToTopic('offers');

// 3. Get the current subscription list
final topics = await notificationMaster.getSubscribedTopics();

// 4. Register token + topics on your server
await myApi.registerDevice(token: token!, topics: topics);
// Your server can now send a push notification to all devices
// subscribed to 'news' by looking up tokens in its database.

// Later — unsubscribe
await notificationMaster.unsubscribeFromTopic('offers');
final updatedTopics = await notificationMaster.getSubscribedTopics();
await myApi.updateDevice(token: token!, topics: updatedTopics);
```

#### Send to a topic from your server (Firebase HTTP v1)

```json
POST https://fcm.googleapis.com/v1/projects/{project_id}/messages:send
{
  "message": {
    "topic": "news",
    "notification": {
      "title": "Breaking News",
      "body": "Something important happened."
    }
  }
}
```

---

## Notification Service Management

The plugin provides a unified notification service management system that allows you to choose between different notification delivery methods. Only one service can be active at a time — starting a new service automatically stops the previous one.

### Available Services

| Service | Method | Battery Usage | Reliability | Use Case |
|---------|--------|---------------|-------------|----------|
| **Polling** | `startNotificationPolling()` | Low | Medium | Periodic background checks (every 15+ min) |
| **Foreground Service** | `startForegroundService()` | High | High | Continuous real-time notifications |
| **Firebase (FCM)** | `setFirebaseAsActiveService()` | Very Low | Very High | Push notifications from server |

### How It Works

1. **Service Selection**: When you start any notification service, the plugin saves the active service type in SharedPreferences and stops any previously running service.

2. **Automatic Switching**: If you start Polling while Foreground Service is running, the Foreground Service is automatically stopped.

3. **State Persistence**: The active service state persists across app restarts. You can check which service is active using `getActiveNotificationService()`.

### Example: Service Manager UI

```dart
class NotificationServiceManager extends StatefulWidget {
  @override
  State<NotificationServiceManager> createState() => _NotificationServiceManagerState();
}

class _NotificationServiceManagerState extends State<NotificationServiceManager> {
  final _nm = NotificationMaster();
  String _activeService = 'none';

  @override
  void initState() {
    super.initState();
    _checkActiveService();
  }

  Future<void> _checkActiveService() async {
    final service = await _nm.getActiveNotificationService();
    setState(() => _activeService = service);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status indicator
        Text('Active: $_activeService',
          style: TextStyle(fontWeight: FontWeight.bold)),

        // Polling option
        ElevatedButton(
          onPressed: () async {
            await _nm.startNotificationPolling(
              pollingUrl: 'https://api.example.com/notifications',
              intervalMinutes: 15,
            );
            _checkActiveService();
          },
          child: Text('Start Polling'),
        ),

        // Foreground service option
        ElevatedButton(
          onPressed: () async {
            await _nm.startForegroundService(
              pollingUrl: 'https://api.example.com/notifications',
              intervalMinutes: 5,
            );
            _checkActiveService();
          },
          child: Text('Start Foreground Service'),
        ),

        // Firebase option
        ElevatedButton(
          onPressed: () async {
            await _nm.setFirebaseAsActiveService();
            _checkActiveService();
          },
          child: Text('Use Firebase (FCM)'),
        ),

        // Stop all
        ElevatedButton(
          onPressed: () async {
            await _nm.stopNotificationPolling();
            await _nm.stopForegroundService();
            _checkActiveService();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('Stop All Services'),
        ),
      ],
    );
  }
}
```

### Service Lifecycle

```
App Start
    │
    ▼
getActiveNotificationService() → "none"
    │
    ▼
startNotificationPolling() → "polling" (Background WorkManager/BGTaskScheduler)
    │
    ▼
startForegroundService() → "foreground" (polling stops automatically)
    │
    ▼
setFirebaseAsActiveService() → "firebase" (foreground service stops automatically)
    │
    ▼
stopNotificationPolling() + stopForegroundService() → "none"
```

---

## Using UnifiedNotificationService

This class provides a unified interface for all platforms.

### Initialization

```dart
import 'package:notification_master/src/unified_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await UnifiedNotificationService.initialize(appName: 'My App');

  runApp(MyApp());
}
```

### Show Notification

```dart
// Simple notification
await UnifiedNotificationService.showNotification(
  title: 'Hello',
  message: 'You have a new message',
);

// With image
await UnifiedNotificationService.showImageNotification(
  title: 'New Photo',
  message: 'A friend sent you a photo',
  imageUrl: 'https://example.com/photo.jpg',
);

// With long text
await UnifiedNotificationService.showBigTextNotification(
  title: 'Newsletter',
  message: 'Summary...',
  bigText: 'Full newsletter text here...',
);

// With action buttons
await UnifiedNotificationService.showNotificationWithActions(
  title: 'Reminder',
  message: 'Meeting in 15 minutes',
  actions: ['OK', 'Remind me later'],
  onActionClick: (index) {
    print('User clicked button $index');
  },
);
```

### Check Platform

```dart
print(UnifiedNotificationService.getPlatformName()); // "Android", "iOS", ...
print(UnifiedNotificationService.isDesktop); // true/false
print(UnifiedNotificationService.isMobile);  // true/false
print(UnifiedNotificationService.isWeb);     // true/false
print(UnifiedNotificationService.isInitialized); // true/false
```

---

## Web Usage

### Key Differences: Web vs. Other Platforms

| Feature            | Mobile/Desktop | Web          |
|--------------------|-----------------|--------------|
| Permission         | OS              | Browser      |
| Foreground Service | ✅              | ❌           |
| Background Polling | ✅              | ❌           |
| Channels           | ✅ (Android)    | ❌ (no-op)   |
| Actions            | ✅              | Limited      |
| Image              | ✅              | Browser-dependent |

### Full Web Example

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:notification_master/notification_master.dart';

class WebNotificationHelper {
  static final _nm = NotificationMaster();

  static Future<bool> setup() async {
    if (!kIsWeb) return false;

    // Check browser support
    final hasPermission = await _nm.checkNotificationPermission();
    if (hasPermission) return true;

    // Request permission (browser shows a prompt)
    final granted = await _nm.requestNotificationPermission();
    if (!granted) {
      print('User denied permission or browser does not support it');
      return false;
    }
    return true;
  }

  static Future<void> notify(String title, String message) async {
    if (!kIsWeb) return;
    await _nm.showNotification(title: title, message: message);
  }
}

// Usage
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await WebNotificationHelper.setup();
  }

  runApp(MyApp());
}
```

---

## Full Example: App Setup

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:notification_master/notification_master.dart';
import 'package:notification_master/src/unified_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UnifiedNotificationService.initialize(appName: 'My App');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(home: HomePage());
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _nm = NotificationMaster();

  Future<void> _init() async {
    final has = await _nm.checkNotificationPermission();
    if (!has) await _nm.requestNotificationPermission();

    // Android: Create custom channel
    if (!kIsWeb) {
      await _nm.createCustomChannel(
        channelId: 'main',
        channelName: 'Main Notifications',
        importance: NotificationImportance.high,
        enableVibration: true,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notification Test')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => _nm.showNotification(
              title: 'Test',
              message: 'This is a test',
              channelId: 'main',
            ),
            child: Text('Simple Notification'),
          ),
          ElevatedButton(
            onPressed: () => _nm.startNotificationPolling(
              pollingUrl: 'https://api.example.com/notifications',
              intervalMinutes: 15,
            ),
            child: Text('Start Polling'),
          ),
          ElevatedButton(
            onPressed: () => _nm.stopNotificationPolling(),
            child: Text('Stop Polling'),
          ),
        ],
      ),
    );
  }
}
```

---

## Notification Importance Levels

| Value                          | Description                          |
|--------------------------------|--------------------------------------|
| `NotificationImportance.high`  | Sound + vibration + top banner      |
| `NotificationImportance.defaultImportance` | Default behavior |
| `NotificationImportance.low`   | No sound                            |
| `NotificationImportance.min`   | Only in notification bar            |

---

## Important Notes

- **Android 13+**: Always request `POST_NOTIFICATIONS` permission in Manifest and code.
- **Web**: Safari has limited support.
- **Foreground Service**: Only supported on Android.
- **Background Polling**: Does not work on Web; polling only occurs while the app is open.
- **Channels**: Only supported on Android 8.0+; ignored on other platforms.
- **App Icon**: Use `showStyledNotification()` to display the app icon in notifications. ⭐
- **Sound**: Custom channels now properly support sound with `enableSound: true`. ✅
- **iOS**: Requires iOS 14.0+. Supports iOS 14 through iOS 26+. 📱

---

## What's New in Latest Version

### ✅ Fixed Issues:
1. **Sound**: Custom channels now properly play notification sounds
2. **App Icon**: Notifications now display the app icon (use `showStyledNotification()`)
3. **Full Text**: Messages are displayed in full without truncation
4. **Better Logging**: Comprehensive logs added for debugging
5. **iOS 12.0+**: Maximum device compatibility (~99% of active iOS devices)

### 🆕 New Methods:
- `showStyledNotification()`: Notification with app icon and full text (recommended)
- `showHeadsUpNotification()`: Notification that appears from top of screen
- `showFullScreenNotification()`: Full-screen notification for urgent alerts
- `getDeviceToken()`: Get device token for push notifications (FCM/APNS)
- `subscribeToTopic()`: Subscribe to a notification topic for targeted push
- `unsubscribeFromTopic()`: Unsubscribe from a notification topic

### 🪟 Windows Platform Enhancements:
Windows now supports **7 notification types** with advanced scenarios:
- Styled notifications with attribution text
- Heads-Up (Alarm scenario) with looping alarm sound
- Full Screen (IncomingCall scenario) with looping ringtone
- Custom audio system (Alarm, Call, SMS, Mail, Reminder, etc.)
- Long duration support
- **[See Windows Guide](WINDOWS_NOTIFICATIONS_GUIDE.md)** for complete examples and documentation

### 📚 Documentation:
- See `NOTIFICATION_TYPES_FA.md` for detailed Persian documentation
- See **[WINDOWS_NOTIFICATIONS_GUIDE.md](WINDOWS_NOTIFICATIONS_GUIDE.md)** for Windows platform guide
- Includes examples and troubleshooting guide

### 🔧 Build Fixes:
- macOS: Fixed BGTaskScheduler compilation errors
- iOS: Set to iOS 14.0 deployment target
- Removed `workmanager` dependency — background polling now uses native APIs directly
- See `BUILD_FIXES.md` for details

---

## License

MIT License - See LICENSE file for details.
