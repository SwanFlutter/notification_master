import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'notification_master_platform_interface.dart';
import 'src/notification_polling.dart';
import 'src/tools/notification_importance.dart';

export 'package:notification_master/src/notification_master_desktop.dart';

export 'src/tools/notification_importance.dart';
export 'src/unified_notification_service.dart';

/// The main plugin class for NotificationMaster.
class NotificationMaster {
  static final NotificationMaster _instance = NotificationMaster._internal();
  factory NotificationMaster() => _instance;
  NotificationMaster._internal() {
    _setupMethodChannel();
  }

  final StreamController<Map<String, dynamic>> _notificationTapController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of notification tap events.
  /// Each event is a map containing 'targetScreen' and 'extraData' if available.
  Stream<Map<String, dynamic>> get onNotificationTap =>
      _notificationTapController.stream;

  final StreamController<Map<String, dynamic>> _actionTapController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of notification action tap events.
  /// Each event is a map containing 'route', 'targetScreen', and 'extraData' if available.
  Stream<Map<String, dynamic>> get onActionTap => _actionTapController.stream;

  void _setupMethodChannel() {
    const channel = MethodChannel('notification_master');
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onNotificationTap':
          _notificationTapController.add(
            Map<String, dynamic>.from(call.arguments),
          );
          break;
        case 'onActionTap':
          _actionTapController.add(Map<String, dynamic>.from(call.arguments));
          break;
      }
    });
  }

  Future<String?> getPlatformVersion() {
    return NotificationMasterPlatform.instance.getPlatformVersion();
  }

  Future<bool> requestNotificationPermission() {
    return NotificationMasterPlatform.instance.requestNotificationPermission();
  }

  Future<bool> checkNotificationPermission() {
    return NotificationMasterPlatform.instance.checkNotificationPermission();
  }

  Future<int> showNotification({
    int? id,
    required String title,
    required String message,
    String? channelId,
    NotificationImportance? importance,
    bool? autoCancel,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) {
    return NotificationMasterPlatform.instance.showNotification(
      id: id,
      title: title,
      message: message,
      channelId: channelId,
      importance: importance,
      autoCancel: autoCancel,
      targetScreen: targetScreen,
      extraData: extraData,
    );
  }

  Future<int> showBigTextNotification({
    required String title,
    required String message,
    required String bigText,
    String? channelId,
    NotificationImportance? importance,
    bool? autoCancel,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) {
    return NotificationMasterPlatform.instance.showBigTextNotification(
      title: title,
      message: message,
      bigText: bigText,
      channelId: channelId,
      importance: importance,
      autoCancel: autoCancel,
      targetScreen: targetScreen,
      extraData: extraData,
    );
  }

  Future<int> showImageNotification({
    required String title,
    required String message,
    required String imageUrl,
    String? channelId,
    NotificationImportance? importance,
    bool? autoCancel,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) {
    return NotificationMasterPlatform.instance.showImageNotification(
      title: title,
      message: message,
      imageUrl: imageUrl,
      channelId: channelId,
      importance: importance,
      autoCancel: autoCancel,
      targetScreen: targetScreen,
      extraData: extraData,
    );
  }

  Future<int> showNotificationWithActions({
    required String title,
    required String message,
    required List<Map<String, String>> actions,
    String? channelId,
    NotificationImportance? importance,
    bool? autoCancel,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) {
    return NotificationMasterPlatform.instance.showNotificationWithActions(
      title: title,
      message: message,
      actions: actions,
      channelId: channelId,
      importance: importance,
      autoCancel: autoCancel,
      targetScreen: targetScreen,
      extraData: extraData,
    );
  }

  Future<bool> createCustomChannel({
    required String channelId,
    required String channelName,
    String? channelDescription,
    NotificationImportance? importance,
    bool? enableLights,
    int? lightColor,
    bool? enableVibration,
    bool? enableSound,
  }) {
    return NotificationMasterPlatform.instance.createCustomChannel(
      channelId: channelId,
      channelName: channelName,
      channelDescription: channelDescription,
      importance: importance?.value,
      enableLights: enableLights,
      lightColor: lightColor,
      enableVibration: enableVibration,
      enableSound: enableSound,
    );
  }

  Future<bool> startNotificationPolling({
    required String pollingUrl,
    int? intervalMinutes,
  }) async {
    try {
      await NotificationPolling.initialize();
      await NotificationPolling.startPolling(
        url: pollingUrl,
        frequencyInMinutes: intervalMinutes ?? 15,
      );
      return true;
    } catch (e) {
      debugPrint("Error starting polling: $e");
      return false;
    }
  }

  Future<bool> stopNotificationPolling() async {
    try {
      NotificationPolling.stopPolling();
      return true;
    } catch (e) {
      debugPrint("Error stopping polling: $e");
      return false;
    }
  }

  Future<bool> startForegroundService({
    required String pollingUrl,
    int? intervalMinutes,
    String? channelId,
    String? channelName,
    String? channelDescription,
    NotificationImportance? importance,
    bool? enableLights,
    int? lightColor,
    bool? enableVibration,
    bool? enableSound,
  }) async {
    if (channelId != null && channelName != null) {
      await createCustomChannel(
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDescription,
        importance: importance,
        enableLights: enableLights,
        lightColor: lightColor,
        enableVibration: enableVibration,
        enableSound: enableSound,
      );
    }
    return NotificationMasterPlatform.instance.startForegroundService(
      pollingUrl: pollingUrl,
      intervalMinutes: intervalMinutes,
      channelId: channelId,
    );
  }

  Future<bool> stopForegroundService() {
    return NotificationMasterPlatform.instance.stopForegroundService();
  }

  Future<bool> setFirebaseAsActiveService() {
    return NotificationMasterPlatform.instance.setFirebaseAsActiveService();
  }

  Future<String> getActiveNotificationService() {
    return NotificationMasterPlatform.instance.getActiveNotificationService();
  }

  /// Show a heads-up notification (appears from top with padding)
  /// This is the most visible notification type on Android
  Future<int> showHeadsUpNotification({
    required String title,
    required String message,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) {
    return NotificationMasterPlatform.instance.showHeadsUpNotification(
      title: title,
      message: message,
      targetScreen: targetScreen,
      extraData: extraData,
    );
  }

  /// Show a full screen notification (most intrusive)
  /// Used for high priority alerts like incoming calls
  Future<int> showFullScreenNotification({
    required String title,
    required String message,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) {
    return NotificationMasterPlatform.instance.showFullScreenNotification(
      title: title,
      message: message,
      targetScreen: targetScreen,
      extraData: extraData,
    );
  }

  /// Show a styled notification (like in the image with app icon and full text)
  /// This displays the notification with the app icon on the left and full message
  Future<int> showStyledNotification({
    required String title,
    required String message,
    String? channelId,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) {
    return NotificationMasterPlatform.instance.showStyledNotification(
      title: title,
      message: message,
      channelId: channelId,
      targetScreen: targetScreen,
      extraData: extraData,
    );
  }

  /// Get the device token for push notifications.
  /// Returns the FCM token on Android, APNS token on iOS, or null if unavailable.
  Future<String?> getDeviceToken() {
    return NotificationMasterPlatform.instance.getDeviceToken();
  }

  /// Subscribe to a notification topic.
  /// On Android/iOS with Firebase, this subscribes to an FCM topic.
  Future<bool> subscribeToTopic(String topic) {
    return NotificationMasterPlatform.instance.subscribeToTopic(topic);
  }

  /// Unsubscribe from a notification topic.
  Future<bool> unsubscribeFromTopic(String topic) {
    return NotificationMasterPlatform.instance.unsubscribeFromTopic(topic);
  }

  /// Returns the list of topics this device is currently subscribed to.
  ///
  /// With Firebase: reflects actual FCM topic subscriptions (also cached locally).
  /// Without Firebase: reflects locally stored subscriptions only — use the
  /// returned list alongside [getDeviceToken] to manage topic targeting server-side.
  ///
  /// ```dart
  /// final token = await notificationMaster.getDeviceToken();
  /// final topics = await notificationMaster.getSubscribedTopics();
  /// // Send token + topics to your server so it can send targeted push notifications.
  /// ```
  Future<List<String>> getSubscribedTopics() {
    return NotificationMasterPlatform.instance.getSubscribedTopics();
  }

  /// Schedule a notification to be shown by the operating system at a fixed
  /// time, even when the app is fully closed (a real background service).
  ///
  /// This uses the platform's native scheduling APIs (Android AlarmManager,
  /// iOS/macOS `UNUserNotificationCenter` calendar triggers, Windows
  /// scheduled toasts, Linux detached timer) so **no external plugin is
  /// required**.
  ///
  /// - [id] must be unique; use it later to cancel the notification.
  /// - [scheduledEpochMillis] is the delivery time as milliseconds since epoch.
  /// - [alarmSound] plays a louder, alarm-like sound (high importance channel).
  ///
  /// Returns `true` when the notification was scheduled.
  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String message,
    required DateTime scheduledTime,
    String? channelId,
    NotificationImportance? importance,
    bool alarmSound = false,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) {
    return NotificationMasterPlatform.instance.scheduleNotification(
      id: id,
      title: title,
      message: message,
      scheduledEpochMillis: scheduledTime.millisecondsSinceEpoch,
      channelId: channelId,
      importance: importance,
      alarmSound: alarmSound,
      targetScreen: targetScreen,
      extraData: extraData,
    );
  }

  /// Cancel a single notification previously scheduled with [scheduleNotification].
  Future<bool> cancelScheduledNotification(int id) {
    return NotificationMasterPlatform.instance.cancelScheduledNotification(id);
  }

  /// Cancel every notification scheduled with [scheduleNotification].
  Future<bool> cancelAllScheduledNotifications() {
    return NotificationMasterPlatform.instance.cancelAllScheduledNotifications();
  }

  /// Returns the ids of notifications that are scheduled but not yet delivered.
  Future<List<int>> getPendingScheduledNotifications() {
    return NotificationMasterPlatform.instance.getPendingScheduledNotifications();
  }

  /// Start a standalone background poller (Windows). It keeps polling
  /// [pollingUrl] and showing toasts even after the app is fully closed,
  /// because it runs in its own process. A log file is written next to the
  /// executable for diagnostics.
  Future<bool> startBackgroundPollingService({
    required String pollingUrl,
    int? intervalMinutes,
  }) {
    return NotificationMasterPlatform.instance.startBackgroundPollingService(
      pollingUrl: pollingUrl,
      intervalMinutes: intervalMinutes,
    );
  }

  /// Stop the background poller started via [startBackgroundPollingService].
  Future<bool> stopBackgroundPollingService() {
    return NotificationMasterPlatform.instance.stopBackgroundPollingService();
  }

  /// Whether the background poller process is currently running.
  Future<bool> isBackgroundPollingRunning() {
    return NotificationMasterPlatform.instance.isBackgroundPollingRunning();
  }
}
