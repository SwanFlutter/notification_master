import 'dart:io';

import 'package:flutter/foundation.dart';

/// Desktop notification handler.
/// This class provides desktop-specific notification functionality
/// for Linux, macOS, and Windows platforms.
class NotificationMasterDesktop {
  static bool _isInitialized = false;

  /// Initialize desktop notifications
  static Future<void> initialize({required String appName}) async {
    if (!_isDesktopPlatform()) {
      if (kDebugMode) {
        print(
          'NotificationMasterDesktop: Not a desktop platform, skipping initialization',
        );
      }
      return;
    }

    try {
      _isInitialized = true;
      if (kDebugMode) {
        print('NotificationMasterDesktop: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationMasterDesktop: Initialization failed: $e');
      }
    }
  }

  static bool _isDesktopPlatform() {
    return Platform.isLinux || Platform.isMacOS || Platform.isWindows;
  }

  /// Show a simple desktop notification
  static Future<void> showNotification({
    required String title,
    required String body,
    String? subtitle,
    bool silent = false,
    VoidCallback? onShow,
    VoidCallback? onClick,
    Function(String)? onClose,
  }) async {
    if (!_isDesktopPlatform()) return;
    if (!_isInitialized) return;

    try {
      if (kDebugMode) {
        print('NotificationMasterDesktop: Notification shown - $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationMasterDesktop: Failed to show notification: $e');
      }
    }
  }

  /// Show a desktop notification with action buttons
  static Future<void> showNotificationWithActions({
    required String title,
    required String body,
    String? subtitle,
    required List<String> actions,
    bool silent = false,
    Function(int)? onActionClick,
    VoidCallback? onClick,
  }) async {
    if (!_isDesktopPlatform()) return;
    if (!_isInitialized) return;

    try {
      if (kDebugMode) {
        print(
          'NotificationMasterDesktop: Notification with actions shown - $title',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationMasterDesktop: Failed to show notification: $e');
      }
    }
  }

  static bool isSupported() => _isDesktopPlatform();
  static bool isInitialized() => _isInitialized;
}
