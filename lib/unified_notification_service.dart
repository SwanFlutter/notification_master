import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:notification_master/notification_master.dart';
// Uncomment when local_notifier is added to pubspec.yaml
// import 'package:local_notifier/local_notifier.dart';

/// Unified Notification Service
///
/// This service provides a unified interface for showing notifications
/// across all platforms (Android, iOS, Web, Linux, macOS, Windows).
///
/// It automatically uses the best notification system for each platform:
/// - Desktop (Linux, macOS, Windows): local_notifier
/// - Mobile (Android, iOS): notification_master
/// - Web: notification_master
///
/// Usage:
/// ```dart
/// // Initialize once in main()
/// await UnifiedNotificationService.initialize(appName: 'my_app');
///
/// // Show notifications anywhere
/// await UnifiedNotificationService.showNotification(
///   title: 'Hello',
///   message: 'World',
/// );
/// ```
class UnifiedNotificationService {
  static final NotificationMaster _notificationMaster = NotificationMaster();
  static bool _isInitialized = false;
  static String? _appName;

  /// Initialize notification service for all platforms
  ///
  /// Must be called before showing any notifications.
  /// Typically called in main() after WidgetsFlutterBinding.ensureInitialized()
  ///
  /// Parameters:
  /// - [appName]: Name of your application
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await UnifiedNotificationService.initialize(appName: 'MyApp');
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> initialize({required String appName}) async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('UnifiedNotificationService: Already initialized');
      }
      return;
    }

    _appName = appName;

    try {
      // Initialize desktop notifications
      if (_isDesktopPlatform()) {
        // Uncomment when local_notifier is added
        // await localNotifier.setup(
        //   appName: appName,
        //   shortcutPolicy: ShortcutPolicy.requireCreate,
        // );
        if (kDebugMode) {
          print(
            'UnifiedNotificationService: Desktop notifications initialized',
          );
        }
      }

      // Initialize mobile/web notifications
      if (_isMobilePlatform() || kIsWeb) {
        final hasPermission = await _notificationMaster
            .checkNotificationPermission();
        if (!hasPermission) {
          final granted = await _notificationMaster
              .requestNotificationPermission();
          if (kDebugMode) {
            print(
              'UnifiedNotificationService: Permission ${granted ? "granted" : "denied"}',
            );
          }
        }
      }

      _isInitialized = true;
      if (kDebugMode) {
        print(
          'UnifiedNotificationService: Initialized successfully on ${getPlatformName()}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedNotificationService: Initialization failed: $e');
      }
    }
  }

  /// Show a simple notification on any platform
  ///
  /// Parameters:
  /// - [title]: Notification title (required)
  /// - [message]: Notification message/body (required)
  /// - [subtitle]: Notification subtitle (optional, macOS only)
  /// - [silent]: Whether notification should be silent (default: false)
  /// - [onClick]: Callback when notification is clicked (desktop only)
  /// - [onShow]: Callback when notification is shown (desktop only)
  /// - [onClose]: Callback when notification is closed (desktop only)
  ///
  /// Example:
  /// ```dart
  /// await UnifiedNotificationService.showNotification(
  ///   title: 'New Message',
  ///   message: 'You have a new message from John',
  ///   onClick: () => print('Notification clicked'),
  /// );
  /// ```
  static Future<void> showNotification({
    required String title,
    required String message,
    String? subtitle,
    bool silent = false,
    VoidCallback? onClick,
    VoidCallback? onShow,
    Function(String)? onClose,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print(
          'UnifiedNotificationService: Not initialized. Call initialize() first.',
        );
      }
      return;
    }

    try {
      if (_isDesktopPlatform()) {
        // Use local_notifier for desktop
        await _showDesktopNotification(
          title: title,
          body: message,
          subtitle: subtitle,
          silent: silent,
          onClick: onClick,
          onShow: onShow,
          onClose: onClose,
        );
      } else {
        // Use notification_master for mobile/web
        await _notificationMaster.showNotification(
          title: title,
          message: message,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedNotificationService: Failed to show notification: $e');
      }
    }
  }

  /// Show notification with action buttons
  ///
  /// Parameters:
  /// - [title]: Notification title (required)
  /// - [message]: Notification message/body (required)
  /// - [actions]: List of action button labels (required)
  /// - [onActionClick]: Callback with action index when button is clicked
  /// - [onClick]: Callback when notification body is clicked
  ///
  /// Example:
  /// ```dart
  /// await UnifiedNotificationService.showNotificationWithActions(
  ///   title: 'Confirm Action',
  ///   message: 'Do you want to continue?',
  ///   actions: ['Yes', 'No', 'Later'],
  ///   onActionClick: (index) {
  ///     if (index == 0) print('User clicked Yes');
  ///     else if (index == 1) print('User clicked No');
  ///     else print('User clicked Later');
  ///   },
  /// );
  /// ```
  static Future<void> showNotificationWithActions({
    required String title,
    required String message,
    required List<String> actions,
    Function(int)? onActionClick,
    VoidCallback? onClick,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print(
          'UnifiedNotificationService: Not initialized. Call initialize() first.',
        );
      }
      return;
    }

    try {
      if (_isDesktopPlatform()) {
        // Use local_notifier for desktop
        // Uncomment when local_notifier is added
        // LocalNotification notification = LocalNotification(
        //   title: title,
        //   body: message,
        //   actions: actions.map((action) =>
        //     LocalNotificationAction(text: action)
        //   ).toList(),
        // );
        //
        // if (onClick != null) {
        //   notification.onClick = onClick;
        // }
        //
        // if (onActionClick != null) {
        //   notification.onClickAction = onActionClick;
        // }
        //
        // await notification.show();

        if (kDebugMode) {
          print(
            'UnifiedNotificationService: Desktop notification with actions - $title',
          );
        }
      } else {
        // Use notification_master for mobile/web
        await _notificationMaster.showNotificationWithActions(
          title: title,
          message: message,
          actions: actions
              .asMap()
              .entries
              .map(
                (entry) => {
                  'title': entry.value,
                  'route': '/action_${entry.key}',
                },
              )
              .toList(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedNotificationService: Failed to show notification: $e');
      }
    }
  }

  /// Show notification with image (mobile/web only)
  ///
  /// Note: Desktop platforms don't support images in notifications.
  /// On desktop, this will show a simple notification without the image.
  ///
  /// Parameters:
  /// - [title]: Notification title (required)
  /// - [message]: Notification message (required)
  /// - [imageUrl]: URL of the image to display (required)
  ///
  /// Example:
  /// ```dart
  /// await UnifiedNotificationService.showImageNotification(
  ///   title: 'New Photo',
  ///   message: 'John shared a photo with you',
  ///   imageUrl: 'https://example.com/photo.jpg',
  /// );
  /// ```
  static Future<void> showImageNotification({
    required String title,
    required String message,
    required String imageUrl,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print(
          'UnifiedNotificationService: Not initialized. Call initialize() first.',
        );
      }
      return;
    }

    try {
      if (_isDesktopPlatform()) {
        // Desktop doesn't support images, show simple notification
        if (kDebugMode) {
          print(
            'UnifiedNotificationService: Image notifications not supported on desktop, showing simple notification',
          );
        }
        await showNotification(title: title, message: message);
      } else {
        // Use notification_master for mobile/web
        await _notificationMaster.showImageNotification(
          title: title,
          message: message,
          imageUrl: imageUrl,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          'UnifiedNotificationService: Failed to show image notification: $e',
        );
      }
    }
  }

  /// Show big text notification (mobile only)
  ///
  /// Note: Desktop platforms don't support big text notifications.
  /// On desktop, this will show a simple notification with the bigText as the message.
  ///
  /// Parameters:
  /// - [title]: Notification title (required)
  /// - [message]: Short notification message (required)
  /// - [bigText]: Expanded text content (required)
  ///
  /// Example:
  /// ```dart
  /// await UnifiedNotificationService.showBigTextNotification(
  ///   title: 'Article Update',
  ///   message: 'New article published',
  ///   bigText: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit...',
  /// );
  /// ```
  static Future<void> showBigTextNotification({
    required String title,
    required String message,
    required String bigText,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print(
          'UnifiedNotificationService: Not initialized. Call initialize() first.',
        );
      }
      return;
    }

    try {
      if (_isDesktopPlatform()) {
        // Desktop doesn't support big text, show simple notification with bigText
        if (kDebugMode) {
          print(
            'UnifiedNotificationService: Big text notifications not supported on desktop, showing simple notification',
          );
        }
        await showNotification(
          title: title,
          message: bigText, // Use bigText as message on desktop
        );
      } else {
        // Use notification_master for mobile
        await _notificationMaster.showBigTextNotification(
          title: title,
          message: message,
          bigText: bigText,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          'UnifiedNotificationService: Failed to show big text notification: $e',
        );
      }
    }
  }

  // Private helper methods

  static Future<void> _showDesktopNotification({
    required String title,
    required String body,
    String? subtitle,
    bool silent = false,
    VoidCallback? onClick,
    VoidCallback? onShow,
    Function(String)? onClose,
  }) async {
    // Uncomment when local_notifier is added
    // LocalNotification notification = LocalNotification(
    //   title: title,
    //   subtitle: subtitle,
    //   body: body,
    //   silent: silent,
    // );
    //
    // if (onShow != null) {
    //   notification.onShow = onShow;
    // }
    //
    // if (onClick != null) {
    //   notification.onClick = onClick;
    // }
    //
    // if (onClose != null) {
    //   notification.onClose = (closeReason) {
    //     onClose(closeReason.name);
    //   };
    // }
    //
    // await notification.show();

    if (kDebugMode) {
      print('UnifiedNotificationService: Desktop notification - $title: $body');
    }
  }

  static bool _isDesktopPlatform() {
    return !kIsWeb &&
        (Platform.isLinux || Platform.isMacOS || Platform.isWindows);
  }

  static bool _isMobilePlatform() {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  /// Get the current platform name
  ///
  /// Returns: 'Android', 'iOS', 'Web', 'Linux', 'macOS', 'Windows', or 'Unknown'
  static String getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    return 'Unknown';
  }

  /// Check if the service is initialized
  static bool get isInitialized => _isInitialized;

  /// Get the app name
  static String? get appName => _appName;

  /// Check if current platform is desktop
  static bool get isDesktop => _isDesktopPlatform();

  /// Check if current platform is mobile
  static bool get isMobile => _isMobilePlatform();

  /// Check if current platform is web
  static bool get isWeb => kIsWeb;
}
