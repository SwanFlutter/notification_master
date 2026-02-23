// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.

// ignore_for_file: unused_local_variable

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'notification_master_platform_interface.dart';
import 'src/tools/notification_importance.dart';

/// A web implementation of the NotificationMasterPlatform of the NotificationMaster plugin.
///
/// This implementation uses the `package:web` library to interact with the
/// browser's Notification API.
///
/// Usage example:
/// ```dart
/// // In your main.dart or where you initialize your app
/// void main() {
///   // The web implementation is automatically registered
///   runApp(MyApp());
/// }
///
/// // Later in your code
/// final notificationMaster = NotificationMaster();
/// await notificationMaster.requestNotificationPermission();
/// await notificationMaster.showNotification(
///   title: 'Hello Web',
///   message: 'This is a notification on the web!',
/// );
/// ```
class NotificationMasterWeb extends NotificationMasterPlatform {
  /// Constructs a NotificationMasterWeb
  NotificationMasterWeb();

  static void registerWith(Registrar registrar) {
    NotificationMasterPlatform.instance = NotificationMasterWeb();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = web.window.navigator.userAgent;
    return version;
  }

  /// Request notification permission.
  @override
  Future<bool> requestNotificationPermission() async {
    try {
      // Check if the browser supports notifications
      if (!_isNotificationSupported()) {
        return false;
      }
      final result = await web.Notification.requestPermission().toDart;
      return result.toString() == 'granted'; // Convert to Dart String
    } catch (e) {
      // Handle browsers that don't support notifications
      return false;
    }
  }

  /// Check if notification permission is granted.
  @override
  Future<bool> checkNotificationPermission() async {
    try {
      // Check if the browser supports notifications
      if (!_isNotificationSupported()) {
        return false;
      }

      return web.Notification.permission == 'granted';
    } catch (e) {
      // Handle browsers that don't support notifications
      return false;
    }
  }

  /// Show a simple notification.
  @override
  Future<int> showNotification({
    int? id,
    required String title,
    required String message,
    String? channelId,
    NotificationImportance? importance,
    bool? autoCancel,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      // Check if the browser supports notifications
      if (!_isNotificationSupported()) {
        return -1;
      }

      if (web.Notification.permission == 'granted') {
        final options = web.NotificationOptions(
          body: message,
          // Add more options as needed
        );
        final notification = web.Notification(title, options);
        return id ?? 1; // Return the provided ID or default to 1
      }
      return -1; // Failed to show notification
    } catch (e) {
      return -1; // Failed to show notification
    }
  }

  /// Show a notification with big text style.
  @override
  Future<int> showBigTextNotification({
    required String title,
    required String message,
    required String bigText,
    String? channelId,
    NotificationImportance? importance,
    bool? autoCancel,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      // Check if the browser supports notifications
      if (!_isNotificationSupported()) {
        return -1;
      }

      if (web.Notification.permission == 'granted') {
        // For web, we'll combine message and bigText
        final fullMessage = '$message\n\n$bigText';
        final options = web.NotificationOptions(
          body: fullMessage,
          // Add more options as needed
        );
        final notification = web.Notification(title, options);
        return 1; // Return a notification ID
      }
      return -1; // Failed to show notification
    } catch (e) {
      return -1; // Failed to show notification
    }
  }

  /// Show a notification with an image.
  @override
  Future<int> showImageNotification({
    required String title,
    required String message,
    required String imageUrl,
    String? channelId,
    NotificationImportance? importance,
    bool? autoCancel,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      // Check if the browser supports notifications
      if (!_isNotificationSupported()) {
        return -1;
      }

      if (web.Notification.permission == 'granted') {
        final options = web.NotificationOptions(
          body: message,
          icon: imageUrl,
          // Add more options as needed
        );
        final notification = web.Notification(title, options);
        return 1; // Return a notification ID
      }
      return -1; // Failed to show notification
    } catch (e) {
      return -1; // Failed to show notification
    }
  }

  /// Show a notification with custom actions.
  @override
  Future<int> showNotificationWithActions({
    required String title,
    required String message,
    required List<Map<String, String>> actions,
    String? channelId,
    NotificationImportance? importance,
    bool? autoCancel,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      // Check if the browser supports notifications
      if (!_isNotificationSupported()) {
        return -1;
      }

      if (web.Notification.permission == 'granted') {
        // Convert actions to NotificationAction objects if supported
        final options = web.NotificationOptions(
          body: message,
          // Note: actions are part of Service Worker notifications
          // For basic notifications, we'll just show the message
        );
        final notification = web.Notification(title, options);
        return 1; // Return a notification ID
      }
      return -1; // Failed to show notification
    } catch (e) {
      return -1; // Failed to show notification
    }
  }

  /// Create a custom notification channel.
  @override
  Future<bool> createCustomChannel({
    required String channelId,
    required String channelName,
    String? channelDescription,
    int? importance,
    bool? enableLights,
    int? lightColor,
    bool? enableVibration,
    bool? enableSound,
  }) async {
    // Web doesn't have notification channels like Android
    // We'll just return true to indicate success
    return true;
  }

  /// Start polling for notifications from a remote server.
  @override
  Future<bool> startNotificationPolling({
    required String pollingUrl,
    int? intervalMinutes,
  }) async {
    // Web doesn't have background services like Android
    // We could use Periodic Background Sync API, but it's not widely supported
    // For now, we'll just return false to indicate it's not supported
    return false;
  }

  /// Stop polling for notifications.
  @override
  Future<bool> stopNotificationPolling() async {
    // Not applicable on web
    return false;
  }

  /// Start a foreground service for continuous notification polling.
  @override
  Future<bool> startForegroundService({
    required String pollingUrl,
    int? intervalMinutes,
    String? channelId,
  }) async {
    // Web doesn't have foreground services like Android
    // We'll just return false to indicate it's not supported
    return false;
  }

  /// Stop the foreground service for notification polling.
  @override
  Future<bool> stopForegroundService() async {
    // Not applicable on web
    return false;
  }

  /// Set Firebase Cloud Messaging as the active notification service.
  @override
  Future<bool> setFirebaseAsActiveService() async {
    // This would require Firebase integration which is outside the scope of this plugin
    return false;
  }

  /// Get the currently active notification service.
  @override
  Future<String> getActiveNotificationService() async {
    // Web doesn't have active notification services in the same way as Android
    return 'none';
  }

  /// Helper method to check if notifications are supported
  bool _isNotificationSupported() {
    try {
      return web.window.has('Notification');
    } catch (e) {
      return false;
    }
  }
}
