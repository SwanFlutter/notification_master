import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:notification_master/notification_master.dart';

/// Unified Notification Service for all platforms (Android, iOS, Web, Desktop).
class UnifiedNotificationService {
  static final NotificationMaster _notificationMaster = NotificationMaster();
  static bool _isInitialized = false;
  static String? _appName;

  /// Initialize notification service. Call before showing notifications.
  static Future<void> initialize({required String appName}) async {
    if (_isInitialized) return;
    _appName = appName;

    try {
      if (_isDesktopPlatform()) {
        if (kDebugMode) {
          print(
            'UnifiedNotificationService: Desktop notifications initialized',
          );
        }
      }

      if (_isMobilePlatform() || kIsWeb) {
        final hasPermission =
            await _notificationMaster.checkNotificationPermission();
        if (!hasPermission) {
          await _notificationMaster.requestNotificationPermission();
        }
      }

      _isInitialized = true;
      if (kDebugMode) {
        print(
          'UnifiedNotificationService: Initialized on ${getPlatformName()}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedNotificationService: Initialization failed: $e');
      }
    }
  }

  static Future<void> showNotification({
    required String title,
    required String message,
    String? subtitle,
    bool silent = false,
    VoidCallback? onClick,
    VoidCallback? onShow,
    Function(String)? onClose,
  }) async {
    if (!_isInitialized) return;

    try {
      if (_isDesktopPlatform()) {
        if (kDebugMode) {
          print('UnifiedNotificationService: Desktop - $title: $message');
        }
      } else {
        await _notificationMaster.showNotification(
          title: title,
          message: message,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedNotificationService: Failed: $e');
      }
    }
  }

  static Future<void> showNotificationWithActions({
    required String title,
    required String message,
    required List<String> actions,
    Function(int)? onActionClick,
    VoidCallback? onClick,
  }) async {
    if (!_isInitialized) return;

    try {
      if (_isDesktopPlatform()) {
        if (kDebugMode) {
          print(
            'UnifiedNotificationService: Desktop with actions - $title',
          );
        }
      } else {
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
        print('UnifiedNotificationService: Failed: $e');
      }
    }
  }

  static Future<void> showImageNotification({
    required String title,
    required String message,
    required String imageUrl,
  }) async {
    if (!_isInitialized) return;

    try {
      if (_isDesktopPlatform()) {
        await showNotification(title: title, message: message);
      } else {
        await _notificationMaster.showImageNotification(
          title: title,
          message: message,
          imageUrl: imageUrl,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedNotificationService: Failed: $e');
      }
    }
  }

  static Future<void> showBigTextNotification({
    required String title,
    required String message,
    required String bigText,
  }) async {
    if (!_isInitialized) return;

    try {
      if (_isDesktopPlatform()) {
        await showNotification(title: title, message: bigText);
      } else {
        await _notificationMaster.showBigTextNotification(
          title: title,
          message: message,
          bigText: bigText,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedNotificationService: Failed: $e');
      }
    }
  }

  static bool _isDesktopPlatform() {
    return !kIsWeb &&
        (Platform.isLinux || Platform.isMacOS || Platform.isWindows);
  }

  static bool _isMobilePlatform() {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  static String getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    return 'Unknown';
  }

  static bool get isInitialized => _isInitialized;
  static String? get appName => _appName;
  static bool get isDesktop => _isDesktopPlatform();
  static bool get isMobile => _isMobilePlatform();
  static bool get isWeb => kIsWeb;
}
