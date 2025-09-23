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

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  notification_master: ^0.0.3
```

Then run:

```bash
flutter pub get
```

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
  targetScreen: '/settings',
);

// Display a notification that passes data to the target screen
await notificationMaster.showNotification(
  title: 'Data Notification',
  message: 'Tap to view product details',
  targetScreen: '/product',
  extraData: {'productId': '12345', 'category': 'electronics'},
);
```

### Big Text Notifications

```dart
// Display a big text notification
await notificationMaster.showBigTextNotification(
  title: 'Article Update',
  message: 'New article published',
  bigText: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
);

// Display a big text notification with navigation
await notificationMaster.showBigTextNotification(
  title: 'Breaking News',
  message: 'Important news update',
  bigText: 'This is a detailed news article that provides comprehensive information about the recent developments. The expanded text allows users to read more details without opening the app.',
  targetScreen: '/news',
  extraData: {'articleId': '789', 'category': 'breaking'},
);

// Display a big text notification with custom channel
await notificationMaster.showBigTextNotification(
  title: 'System Update',
  message: 'Update available',
  bigText: 'A new system update is available with bug fixes and performance improvements. Please update your app to the latest version for the best experience.',
  channelId: 'system_updates',
  importance: NotificationImportance.high,
);
```

### Image Notifications

```dart
// Display an image notification
await notificationMaster.showImageNotification(
  title: 'New Photo',
  message: 'Someone shared a photo with you',
  imageUrl: 'https://example.com/images/photo.jpg',
);

// Display a high priority image notification
await notificationMaster.showImageNotification(
  title: 'Profile Picture Updated',
  message: 'Your friend updated their profile picture',
  imageUrl: 'https://example.com/avatars/user-123.png',
  importance: NotificationImportance.high,
);

// Display an image notification that opens a specific screen
await notificationMaster.showImageNotification(
  title: 'Product Sale',
  message: '50% off on selected items',
  imageUrl: 'https://example.com/products/sale-banner.jpg',
  targetScreen: '/shop',
  extraData: {'saleId': '2023-summer', 'discount': 50},
);

// Display an image notification with auto-cancel disabled
await notificationMaster.showImageNotification(
  title: 'Daily Motivation',
  message: 'Your daily dose of inspiration',
  imageUrl: 'https://example.com/quotes/daily-quote.jpg',
  autoCancel: false,
  channelId: 'motivational',
);
```

### Notifications with Custom Actions

```dart
// Display a notification with multiple actions
await notificationMaster.showNotificationWithActions(
  title: 'Friend Request',
  message: 'John Doe sent you a friend request',
  actions: [
    {'title': 'Accept', 'route': '/accept-friend'},
    {'title': 'Decline', 'route': '/decline-friend'},
  ],
);

// Display a notification with a single action
await notificationMaster.showNotificationWithActions(
  title: 'App Update Available',
  message: 'Version 2.0 is now available',
  actions: [
    {'title': 'Update Now', 'route': '/update'},
  ],
);

// Display a notification with custom actions and target screen
await notificationMaster.showNotificationWithActions(
  title: 'Meeting Reminder',
  message: 'Team meeting in 15 minutes',
  actions: [
    {'title': 'Join Meeting', 'route': '/join-meeting'},
    {'title': 'Remind Later', 'route': '/snooze'},
  ],
  targetScreen: '/calendar',
  extraData: {'meetingId': 'team-daily-001', 'timestamp': '2023-12-01T14:00:00Z'},
);

// Display a notification with actions and custom importance
await notificationMaster.showNotificationWithActions(
  title: 'Security Alert',
  message: 'New login detected from unknown device',
  actions: [
    {'title': 'Review Login', 'route': '/security'},
    {'title': 'Ignore', 'route': '/dismiss'},
  ],
  importance: NotificationImportance.max,
  autoCancel: false,
);
```

## Custom Notification Channels

### Creating Custom Channels

```dart
// Create a high priority channel
await notificationMaster.createCustomChannel(
  channelId: 'urgent_alerts',
  channelName: 'Urgent Alerts',
  channelDescription: 'Channel for critical notifications that require immediate attention',
  importance: NotificationImportance.high,
  enableLights: true,
  lightColor: 0xFFFF0000, // Red color
  enableVibration: true,
  enableSound: true,
);

// Create a silent channel for background updates
await notificationMaster.createCustomChannel(
  channelId: 'background_sync',
  channelName: 'Background Sync',
  channelDescription: 'Silent notifications for background data synchronization',
  importance: NotificationImportance.min,
  enableLights: false,
  enableVibration: false,
  enableSound: false,
);

// Create a media channel with custom settings
await notificationMaster.createCustomChannel(
  channelId: 'media_playback',
  channelName: 'Media Playback',
  channelDescription: 'Notifications for music and video playback controls',
  importance: NotificationImportance.low,
  enableLights: true,
  lightColor: 0xFF00FF00, // Green color
  enableVibration: false,
  enableSound: false,
);

// Create a social channel for messages and interactions
await notificationMaster.createCustomChannel(
  channelId: 'social_updates',
  channelName: 'Social Updates',
  channelDescription: 'Messages, likes, comments, and other social interactions',
  importance: NotificationImportance.defaultImportance,
  enableLights: true,
  lightColor: 0xFF0000FF, // Blue color
  enableVibration: true,
  enableSound: true,
);
```

### Using Custom Channels

```dart
// Use the urgent alerts channel
await notificationMaster.showNotification(
  title: 'Critical System Error',
  message: 'Immediate attention required',
  channelId: 'urgent_alerts',
);

// Use the background sync channel
await notificationMaster.showNotification(
  title: 'Sync Complete',
  message: 'Your data has been synchronized',
  channelId: 'background_sync',
);

// Use the social updates channel
await notificationMaster.showImageNotification(
  title: 'New Message',
  message: 'Sarah sent you a message',
  imageUrl: 'https://example.com/avatars/sarah.jpg',
  channelId: 'social_updates',
  targetScreen: '/chat',
  extraData: {'chatId': 'sarah-123', 'messageId': 'msg-456'},
);
```

## HTTP Notification Polling

### Basic Polling Setup

```dart
// Start notification polling with default settings
await notificationMaster.startNotificationPolling(
  pollingUrl: 'https://your-api.com/notifications',
  intervalMinutes: 15, // Check every 15 minutes
);

// Start polling with custom interval
await notificationMaster.startNotificationPolling(
  pollingUrl: 'https://api.example.com/user/notifications',
  intervalMinutes: 5, // More frequent polling
);

// Stop notification polling
await notificationMaster.stopNotificationPolling();

// Check current service status
String activeService = await notificationMaster.getActiveNotificationService();
print('Active service: $activeService'); // "polling", "foreground", "firebase", or "none"
```

### Expected Server Response Format

Your server should return JSON in the following format:

```json
{
  "notifications": [
    {
      "title": "Welcome Back!",
      "message": "You have 3 new messages",
      "bigText": "John: Hey, are we still meeting today?\nSarah: Don't forget about the presentation\nMike: Thanks for your help yesterday!",
      "channelId": "social_updates"
    },
    {
      "title": "System Maintenance",
      "message": "Scheduled maintenance tonight",
      "bigText": "Our servers will be undergoing maintenance tonight from 2 AM to 4 AM EST. Some features may be temporarily unavailable during this time.",
      "channelId": "system_alerts"
    }
  ]
}
```

### Advanced Polling Examples

```dart
// Start polling for a specific user
await notificationMaster.startNotificationPolling(
  pollingUrl: 'https://api.yourapp.com/notifications?userId=12345&token=abc123',
  intervalMinutes: 10,
);

// Use polling for real-time chat notifications
await notificationMaster.startNotificationPolling(
  pollingUrl: 'https://chat.yourapp.com/api/pending-messages',
  intervalMinutes: 2, // Very frequent for chat
);

// Poll for system updates and maintenance notifications
await notificationMaster.startNotificationPolling(
  pollingUrl: 'https://status.yourapp.com/api/notifications',
  intervalMinutes: 60, // Less frequent for system updates
);
```

## Foreground Service for Reliable Notifications

### Basic Foreground Service

```dart
// Start foreground service with default settings
await notificationMaster.startForegroundService(
  pollingUrl: 'https://your-api.com/notifications',
  intervalMinutes: 15,
);

// Stop foreground service
await notificationMaster.stopForegroundService();
```

### Custom Foreground Service Configuration

```dart
// Start foreground service with custom notification channel
await notificationMaster.startForegroundService(
  pollingUrl: 'https://api.yourapp.com/notifications',
  intervalMinutes: 10,
  channelId: 'notification_service',
  channelName: 'Notification Service',
  channelDescription: 'Keeps the app running to receive notifications',
  importance: NotificationImportance.low,
  enableLights: false,
  lightColor: 0xFF00FF00,
  enableVibration: false,
  enableSound: false,
);

// Start foreground service for critical applications
await notificationMaster.startForegroundService(
  pollingUrl: 'https://emergency.yourapp.com/alerts',
  intervalMinutes: 1, // Very frequent for emergency alerts
  channelId: 'emergency_service',
  channelName: 'Emergency Alert Service',
  channelDescription: 'Critical service for emergency notifications',
  importance: NotificationImportance.high,
  enableLights: true,
  lightColor: 0xFFFF0000, // Red for emergency
  enableVibration: true,
  enableSound: true,
);
```

### Service Management Examples

```dart
// Switch from polling to foreground service
await notificationMaster.stopNotificationPolling();
await notificationMaster.startForegroundService(
  pollingUrl: 'https://api.yourapp.com/notifications',
  intervalMinutes: 15,
);

// Switch to Firebase and disable other services
await notificationMaster.setFirebaseAsActiveService();

// Check what service is currently running
String currentService = await notificationMaster.getActiveNotificationService();
switch (currentService) {
  case 'polling':
    print('WorkManager polling is active');
    break;
  case 'foreground':
    print('Foreground service is running');
    break;
  case 'firebase':
    print('Firebase is set as active service');
    break;
  case 'none':
    print('No notification service is active');
    break;
}
```

## Platform-Specific Examples

### Android-Specific Features

```dart
// High priority notification with all Android features
await notificationMaster.showNotification(
  title: 'Android Notification',
  message: 'Full-featured Android notification',
  channelId: 'android_channel',
  importance: NotificationImportance.max,
  autoCancel: true,
);

// Create Android notification channel with all options
await notificationMaster.createCustomChannel(
  channelId: 'android_channel',
  channelName: 'Android Features',
  channelDescription: 'Demonstrates all Android notification features',
  importance: NotificationImportance.high,
  enableLights: true,
  lightColor: 0xFF00FF00,
  enableVibration: true,
  enableSound: true,
);
```

### iOS-Specific Examples

```dart
// iOS notification (automatically adapts platform features)
await notificationMaster.showNotification(
  title: 'iOS Notification',
  message: 'Native iOS notification with badge support',
);

// Rich notification for iOS
await notificationMaster.showImageNotification(
  title: 'iOS Rich Notification',
  message: 'Image notification optimized for iOS',
  imageUrl: 'https://example.com/ios-image.jpg',
);
```

### Web-Specific Examples

```dart
// Check browser notification support
bool hasPermission = await notificationMaster.checkNotificationPermission();
if (!hasPermission) {
  bool granted = await notificationMaster.requestNotificationPermission();
  if (!granted) {
    print('Browser notifications not supported or denied');
    return;
  }
}

// Show web browser notification
await notificationMaster.showNotification(
  title: 'Web Browser Notification',
  message: 'This notification appears in your browser',
);

// Web notification with image
await notificationMaster.showImageNotification(
  title: 'Web Image Notification',
  message: 'Browser notification with icon',
  imageUrl: '/assets/images/notification-icon.png',
);
```

## Complete Usage Examples

### E-commerce App Example

```dart
class ECommerceNotifications {
  final notificationMaster = NotificationMaster();

  Future<void> setupNotifications() async {
    // Request permissions
    final hasPermission = await notificationMaster.checkNotificationPermission();
    if (!hasPermission) {
      await notificationMaster.requestNotificationPermission();
    }

    // Create custom channels
    await notificationMaster.createCustomChannel(
      channelId: 'order_updates',
      channelName: 'Order Updates',
      channelDescription: 'Updates about your orders',
      importance: NotificationImportance.high,
      enableLights: true,
      lightColor: 0xFF00FF00,
      enableVibration: true,
      enableSound: true,
    );

    await notificationMaster.createCustomChannel(
      channelId: 'promotions',
      channelName: 'Promotions & Offers',
      channelDescription: 'Special offers and discounts',
      importance: NotificationImportance.defaultImportance,
      enableLights: true,
      lightColor: 0xFFFFAA00,
      enableVibration: false,
      enableSound: true,
    );

    // Start polling for order updates
    await notificationMaster.startNotificationPolling(
      pollingUrl: 'https://api.shop.com/user/notifications',
      intervalMinutes: 30,
    );
  }

  Future<void> showOrderShippedNotification(String orderId, String trackingNumber) async {
    await notificationMaster.showNotificationWithActions(
      title: 'Order Shipped! 📦',
      message: 'Your order #$orderId has been shipped',
      channelId: 'order_updates',
      actions: [
        {'title': 'Track Package', 'route': '/tracking'},
        {'title': 'View Order', 'route': '/orders'},
      ],
      targetScreen: '/order-details',
      extraData: {
        'orderId': orderId,
        'trackingNumber': trackingNumber,
        'status': 'shipped',
      },
    );
  }

  Future<void> showPromotionalNotification() async {
    await notificationMaster.showImageNotification(
      title: '🔥 Flash Sale - 50% Off!',
      message: 'Limited time offer on electronics',
      imageUrl: 'https://api.shop.com/images/flash-sale-banner.jpg',
      channelId: 'promotions',
      targetScreen: '/sale',
      extraData: {'saleType': 'flash', 'category': 'electronics'},
    );
  }
}
```

### Social Media App Example

```dart
class SocialNotifications {
  final notificationMaster = NotificationMaster();

  Future<void> setupSocialNotifications() async {
    // Create channels for different social interactions
    await notificationMaster.createCustomChannel(
      channelId: 'messages',
      channelName: 'Messages',
      channelDescription: 'Direct messages and chat notifications',
      importance: NotificationImportance.high,
      enableLights: true,
      lightColor: 0xFF0099FF,
      enableVibration: true,
      enableSound: true,
    );

    await notificationMaster.createCustomChannel(
      channelId: 'social_activity',
      channelName: 'Social Activity',
      channelDescription: 'Likes, comments, follows, and other interactions',
      importance: NotificationImportance.defaultImportance,
      enableLights: true,
      lightColor: 0xFFFF6B6B,
      enableVibration: false,
      enableSound: true,
    );

    // Use foreground service for real-time messaging
    await notificationMaster.startForegroundService(
      pollingUrl: 'https://social-api.com/realtime-notifications',
      intervalMinutes: 1,
      channelId: 'background_service',
      channelName: 'Social Sync',
      channelDescription: 'Keeps you connected with friends',
      importance: NotificationImportance.low,
      enableVibration: false,
      enableSound: false,
    );
  }

  Future<void> showNewMessageNotification(String sender, String message, String avatarUrl) async {
    await notificationMaster.showImageNotification(
      title: sender,
      message: message,
      imageUrl: avatarUrl,
      channelId: 'messages',
      targetScreen: '/chat',
      extraData: {'senderId': sender, 'messagePreview': message},
    );
  }

  Future<void> showSocialActivityNotification() async {
    await notificationMaster.showBigTextNotification(
      title: 'Social Activity',
      message: 'You have 5 new interactions',
      bigText: 'Sarah liked your photo\nJohn commented on your post\nMike started following you\nEmma shared your story\n+1 more activity',
      channelId: 'social_activity',
      targetScreen: '/activity',
    );
  }
}
```

### News App Example

```dart
class NewsNotifications {
  final notificationMaster = NotificationMaster();

  Future<void> setupNewsNotifications() async {
    // Create channels for different news categories
    await notificationMaster.createCustomChannel(
      channelId: 'breaking_news',
      channelName: 'Breaking News',
      channelDescription: 'Urgent breaking news alerts',
      importance: NotificationImportance.max,
      enableLights: true,
      lightColor: 0xFFFF0000,
      enableVibration: true,
      enableSound: true,
    );

    await notificationMaster.createCustomChannel(
      channelId: 'daily_digest',
      channelName: 'Daily Digest',
      channelDescription: 'Your daily news summary',
      importance: NotificationImportance.defaultImportance,
      enableLights: false,
      enableVibration: false,
      enableSound: false,
    );

    // Poll for breaking news frequently
    await notificationMaster.startNotificationPolling(
      pollingUrl: 'https://news-api.com/breaking-news',
      intervalMinutes: 10,
    );
  }

  Future<void> showBreakingNewsNotification(String headline, String summary, String imageUrl) async {
    await notificationMaster.showImageNotification(
      title: '🚨 BREAKING: $headline',
      message: summary,
      imageUrl: imageUrl,
      channelId: 'breaking_news',
      targetScreen: '/article',
      extraData: {'category': 'breaking', 'urgent': true},
      autoCancel: false,
    );
  }

  Future<void> showDailyDigestNotification(List<String> headlines) async {
    await notificationMaster.showBigTextNotification(
      title: '📰 Daily News Digest',
      message: '${headlines.length} top stories today',
      bigText: headlines.join('\n\n'),
      channelId: 'daily_digest',
      targetScreen: '/digest',
      extraData: {'type': 'daily_digest', 'date': DateTime.now().toIso8601String()},
    );
  }
}
```

## Platform Considerations

### Android
- **API Level 24+** required for full functionality
- Notification channels are automatically created for Android 8.0+
- Uses WorkManager for reliable background polling
- Foreground services show persistent notification

### iOS
- Automatically requests notification permissions
- Respects system Do Not Disturb settings
- Background polling may be limited by iOS background app refresh
- Rich notifications support images and actions

### Web
- Requires HTTPS in production
- Browser notification permissions must be requested by user interaction
- Service Worker support for persistent notifications
- Limited background processing capabilities

### macOS/Windows/Linux
- Native desktop notification systems
- Full support for actions and rich content
- Platform-appropriate styling and behavior

## Troubleshooting

### Common Issues

**Notifications not appearing:**
```dart
// Check permissions first
bool hasPermission = await notificationMaster.checkNotificationPermission();
if (!hasPermission) {
  bool granted = await notificationMaster.requestNotificationPermission();
  print('Permission granted: $granted');
}

// Verify service status
String activeService = await notificationMaster.getActiveNotificationService();
print('Active service: $activeService');
```

**Polling not working:**
```dart
// Stop and restart polling
await notificationMaster.stopNotificationPolling();
await Future.delayed(Duration(seconds: 2));
await notificationMaster.startNotificationPolling(
  pollingUrl: 'https://your-api.com/notifications',
  intervalMinutes: 15,
);
```

**Foreground service issues:**
```dart
// Stop foreground service completely
await notificationMaster.stopForegroundService();

// Check current service status
String service = await notificationMaster.getActiveNotificationService();
if (service != 'none') {
  print('Service still active: $service');
}
```

## Advanced Features

### Service Management
```dart
// Switch between different notification services
class NotificationServiceManager {
  final notificationMaster = NotificationMaster();

  Future<void> switchToFirebase() async {
    // Stop other services and use Firebase
    await notificationMaster.stopForegroundService();
    await notificationMaster.stopNotificationPolling();
    await notificationMaster.setFirebaseAsActiveService();
  }

  Future<void> switchToPolling() async {
    await notificationMaster.stopForegroundService();
    await notificationMaster.startNotificationPolling(
      pollingUrl: 'https://api.example.com/notifications',
      intervalMinutes: 15,
    );
  }

  Future<void> switchToForegroundService() async {
    await notificationMaster.stopNotificationPolling();
    await notificationMaster.startForegroundService(
      pollingUrl: 'https://api.example.com/notifications',
      intervalMinutes: 15,
    );
  }
}
```

This comprehensive documentation provides practical examples for every feature of the Notification Master plugin across all supported platforms. Each example includes real-world usage scenarios and proper error handling.

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.


## Support

- 📧 Email: swan.dev1993@gmail.com
- 🐛 Issues: [GitHub Issues](https://github.com/swanflutter/notification_master/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/swanflutter/notification_master/discussions)


