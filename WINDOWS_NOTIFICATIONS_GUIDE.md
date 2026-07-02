# Windows Notifications Guide

This guide explains all the notification types available on Windows using the Notification Master plugin.

## 📋 Table of Contents

- [Basic Setup](#basic-setup)
- [Notification Types](#notification-types)
- [Platform Comparison](#platform-comparison)
- [Advanced Features](#advanced-features)

---

## 🛠️ Basic Setup

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  notification_master: ^0.0.6
```

### Import

```dart
import 'package:notification_master/notification_master.dart';
```

### Initialize

```dart
final _notificationMaster = NotificationMaster();

// Check permission
final hasPermission = await _notificationMaster.checkNotificationPermission();
```

**Note:** Windows doesn't require explicit permission for toast notifications. The `checkNotificationPermission()` will always return `true`.

---

## 🔔 Notification Types

### 1. Simple Toast Notification

Basic Windows toast notification that appears in the Action Center.

```dart
final notificationId = await _notificationMaster.showNotification(
  id: 100, // Optional custom ID
  title: 'Simple Notification',
  message: 'This is a basic Windows toast notification',
  channelId: 'default', // Optional
);
```

**Features:**
- ✅ Appears in Windows Action Center
- ✅ Auto-dismisses after a few seconds
- ✅ Default system sound
- ✅ Standard duration (Short)

---

### 2. Big Text Notification

Notification with expandable long text content.

```dart
final notificationId = await _notificationMaster.showBigTextNotification(
  title: 'Long Message',
  message: 'Short summary here',
  bigText: 'This is a very long message that will be displayed in full. '
           'Perfect for news updates, detailed messages, or any content '
           'that requires more space than a simple notification.',
  channelId: 'big_text_channel', // Optional
);
```

**Features:**
- ✅ Supports up to 3 lines of text
- ✅ Expandable in Action Center
- ✅ Default system sound
- ✅ Standard duration

---

### 3. Image Notification

Notification with an image (local file or URL).

```dart
final notificationId = await _notificationMaster.showImageNotification(
  title: 'Image Notification',
  message: 'Check out this image!',
  imageUrl: 'https://example.com/image.jpg', // HTTP/HTTPS URL or local file path
  channelId: 'image_channel', // Optional
);
```

**Features:**
- ✅ Supports HTTP/HTTPS image URLs
- ✅ Supports local file paths (e.g., `C:\path\to\image.jpg`)
- ✅ Auto-downloads and caches network images
- ✅ Displays image below text

**Supported Formats:** JPG, PNG, GIF

**Note:** Network images are automatically downloaded to a temporary location and cleaned up by Windows.

---

### 4. Notification with Action Buttons

Notification with interactive buttons (up to 5 actions).

```dart
final notificationId = await _notificationMaster.showNotificationWithActions(
  title: 'Action Notification',
  message: 'Click a button to respond',
  actions: [
    {'title': 'Accept', 'route': '/action/accept'},
    {'title': 'Decline', 'route': '/action/decline'},
    {'title': 'View Details', 'route': '/action/details'},
  ],
  channelId: 'action_channel', // Optional
);
```

**Features:**
- ✅ Up to 5 action buttons
- ✅ Each button can have a custom label
- ✅ Route information for navigation
- ✅ Buttons appear below the notification

---

### 5. Styled Notification ⭐ NEW

Windows-styled notification with attribution text (who sent the notification).

```dart
final notificationId = await _notificationMaster.showStyledNotification(
  title: 'Styled Notification',
  message: 'This notification has a professional appearance',
  channelId: 'styled_channel', // Optional
);
```

**Features:**
- ✅ Attribution text: "Notification Master" appears at bottom
- ✅ Long duration (stays visible longer)
- ✅ 4 lines of text support
- ✅ Default system sound
- ✅ Professional appearance

**When to use:**
- Company/organization notifications
- Official announcements
- Branding purposes

---

### 6. Heads-Up Notification (Alarm) ⏰ NEW

High-priority notification that stays visible longer with alarm sound.

```dart
final notificationId = await _notificationMaster.showHeadsUpNotification(
  title: 'Important Alert!',
  message: 'This notification requires your attention',
);
```

**Features:**
- ✅ Uses Windows **Alarm scenario**
- ✅ Alarm sound (looping)
- ✅ Long duration (stays on screen)
- ✅ Cannot be easily dismissed
- ✅ High visibility

**Audio:** Windows system alarm sound (continuous loop until dismissed)

**When to use:**
- Time-sensitive alerts
- Important reminders
- Critical warnings
- Countdown timers

**⚠️ Warning:** Use sparingly! This notification is intrusive and will keep playing sound until the user dismisses it.

---

### 7. Full Screen Notification (Incoming Call) 📞 NEW

Most intrusive notification type, similar to an incoming phone call.

```dart
final notificationId = await _notificationMaster.showFullScreenNotification(
  title: 'Incoming Call',
  message: 'John Doe is calling you...',
);
```

**Features:**
- ✅ Uses Windows **IncomingCall scenario**
- ✅ Call ringtone sound (looping)
- ✅ Long duration (stays visible)
- ✅ Highest priority notification
- ✅ Full-screen-like behavior

**Audio:** Windows system call sound (continuous loop until dismissed)

**When to use:**
- Incoming VoIP/video calls
- Urgent alerts requiring immediate action
- Emergency notifications
- Meeting/appointment reminders

**⚠️ Warning:** This is the MOST intrusive notification type. Only use for critical, time-sensitive events that require immediate user attention!

---

## 🎵 Audio Options (Advanced)

Windows supports different system sounds for notifications:

### Available Sounds:
- **Default** — Standard notification sound
- **IM** — Instant messaging sound
- **Mail** — Email notification sound
- **SMS** — Text message sound
- **Reminder** — Reminder/alert sound
- **Alarm** — Alarm sound (looping)
- **Call** — Phone call ringtone (looping)

### How to use:
Currently, audio is automatically selected based on the scenario:
- `showNotification()` → Default sound
- `showStyledNotification()` → Default sound
- `showHeadsUpNotification()` → Alarm sound (looping)
- `showFullScreenNotification()` → Call sound (looping)

---

## 📊 Platform Comparison

| Feature | Windows | Linux | macOS | Android | iOS |
|---------|---------|-------|-------|---------|-----|
| Simple Toast | ✅ | ✅ | ✅ | ✅ | ✅ |
| Big Text | ✅ | ✅ | ✅ | ✅ | ✅ |
| Images | ✅ | ⚠️ | ✅ | ✅ | ✅ |
| Actions | ✅ | ⚠️ | ✅ | ✅ | ✅ |
| Styled | ✅ | ❌ | ❌ | ✅ | ❌ |
| Heads-Up | ✅ | ❌ | ❌ | ✅ | ❌ |
| Full Screen | ✅ | ❌ | ❌ | ✅ | ❌ |
| Custom Audio | ✅ | ❌ | ⚠️ | ✅ | ⚠️ |
| Long Duration | ✅ | ❌ | ❌ | ✅ | ❌ |
| Attribution Text | ✅ | ❌ | ❌ | ❌ | ❌ |

**Legend:**
- ✅ Fully supported
- ⚠️ Limited support
- ❌ Not supported

### Notes:

**Linux:**
- Uses `libnotify` which is very basic
- Images and actions have limited support depending on the desktop environment (GNOME, KDE, etc.)
- No scenario support
- No custom audio
- Notifications auto-dismiss quickly

**macOS:**
- Uses `UserNotifications` framework
- Good support for basic notifications
- No scenario types (Alarm, Call)
- Limited audio customization
- Notifications appear in Notification Center

**Why Windows has more features:**
- Windows uses the modern **WinRT Toast Notification API**
- Supports multiple scenarios designed for different use cases
- Built-in support for alarms and calls
- Rich audio system
- Long-duration notifications

---

## 🎯 Best Practices

### When to use each type:

1. **Simple Toast** → General notifications, updates, confirmations
2. **Big Text** → News articles, message previews, detailed updates
3. **Image** → Photo sharing, product updates, visual content
4. **Actions** → Yes/No questions, quick actions, surveys
5. **Styled** → Official announcements, branded messages
6. **Heads-Up (Alarm)** → Timers, important reminders, deadlines
7. **Full Screen (Call)** → VoIP calls, emergency alerts, urgent meetings

### Don't:
- ❌ Don't use Heads-Up or Full Screen for routine notifications
- ❌ Don't spam users with too many notifications
- ❌ Don't use looping audio for non-critical alerts
- ❌ Don't use Full Screen unless absolutely necessary

### Do:
- ✅ Use appropriate notification types for the content
- ✅ Provide meaningful titles and messages
- ✅ Test on Windows 10/11 to verify appearance
- ✅ Respect user preferences and notification settings
- ✅ Use action buttons for quick responses

---

## 🔧 Advanced Features

### Duration Control

- **Short Duration**: Auto-dismiss after ~5 seconds
- **Long Duration**: Stays visible for ~25 seconds

Currently controlled by the notification type:
- Simple, Big Text, Image, Actions → Short duration
- Styled, Heads-Up, Full Screen → Long duration

### Attribution Text

Only available in `showStyledNotification()`. The text "Notification Master" appears at the bottom of the notification to indicate the source.

### Hero Images

Currently not exposed in the API but supported by WinToast. May be added in future versions.

---

## 🐛 Troubleshooting

### Notification doesn't appear?
- Check Windows notification settings (Settings → System → Notifications)
- Ensure your app is allowed to show notifications
- Check Windows Action Center to see if the notification was received

### No sound?
- Check Windows volume settings
- Verify notification sounds are enabled in Windows settings
- For Heads-Up and Full Screen, ensure the scenario is correctly set

### Image not loading?
- Verify the URL is accessible
- Check if the image format is supported (JPG, PNG, GIF)
- For local files, ensure the path is correct and accessible

---

## 📚 Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:notification_master/notification_master.dart';

class WindowsNotificationDemo extends StatelessWidget {
  final _nm = NotificationMaster();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Windows Notifications')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: () => _nm.showNotification(
              title: 'Simple',
              message: 'Basic notification',
            ),
            child: Text('1. Simple Toast'),
          ),
          ElevatedButton(
            onPressed: () => _nm.showBigTextNotification(
              title: 'Long Message',
              message: 'Summary',
              bigText: 'Very long detailed text here...',
            ),
            child: Text('2. Big Text'),
          ),
          ElevatedButton(
            onPressed: () => _nm.showImageNotification(
              title: 'Image',
              message: 'With picture',
              imageUrl: 'https://picsum.photos/400/200',
            ),
            child: Text('3. With Image'),
          ),
          ElevatedButton(
            onPressed: () => _nm.showNotificationWithActions(
              title: 'Actions',
              message: 'Choose an option',
              actions: [
                {'title': 'Yes', 'route': '/yes'},
                {'title': 'No', 'route': '/no'},
              ],
            ),
            child: Text('4. With Actions'),
          ),
          ElevatedButton(
            onPressed: () => _nm.showStyledNotification(
              title: 'Styled',
              message: 'Professional appearance',
            ),
            child: Text('5. Styled'),
          ),
          ElevatedButton(
            onPressed: () => _nm.showHeadsUpNotification(
              title: 'Important!',
              message: 'Requires attention',
            ),
            child: Text('6. Heads-Up (Alarm)'),
          ),
          ElevatedButton(
            onPressed: () => _nm.showFullScreenNotification(
              title: 'Incoming Call',
              message: 'John is calling...',
            ),
            child: Text('7. Full Screen (Call)'),
          ),
        ],
      ),
    );
  }
}
```

---

## 📝 Version History

- **v0.0.6** — Added `showStyledNotification`, `showHeadsUpNotification`, `showFullScreenNotification`
- **v0.0.5** — Initial Windows support with basic notifications

---

## 📄 License

MIT License — See LICENSE file for details.
