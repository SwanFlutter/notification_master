import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'notification_master_method_channel.dart';
import 'src/tools/notification_importance.dart';

abstract class NotificationMasterPlatform extends PlatformInterface {
  /// Constructs a NotificationMasterPlatform.
  NotificationMasterPlatform() : super(token: _token);

  static final Object _token = Object();

  static NotificationMasterPlatform _instance =
      MethodChannelNotificationMaster();

  /// The default instance of [NotificationMasterPlatform] to use.
  static NotificationMasterPlatform get instance => _instance;

  static set instance(NotificationMasterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool> requestNotificationPermission() {
    throw UnimplementedError(
      'requestNotificationPermission() has not been implemented.',
    );
  }

  Future<bool> checkNotificationPermission() {
    throw UnimplementedError(
      'checkNotificationPermission() has not been implemented.',
    );
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
    throw UnimplementedError('showNotification() has not been implemented.');
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
    throw UnimplementedError(
      'showBigTextNotification() has not been implemented.',
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
    throw UnimplementedError(
      'showImageNotification() has not been implemented.',
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
    throw UnimplementedError(
      'showNotificationWithActions() has not been implemented.',
    );
  }

  Future<bool> createCustomChannel({
    required String channelId,
    required String channelName,
    String? channelDescription,
    int? importance,
    bool? enableLights,
    int? lightColor,
    bool? enableVibration,
    bool? enableSound,
  }) {
    throw UnimplementedError('createCustomChannel() has not been implemented.');
  }

  Future<bool> startNotificationPolling({
    required String pollingUrl,
    int? intervalMinutes,
  }) {
    throw UnimplementedError(
      'startNotificationPolling() has not been implemented.',
    );
  }

  Future<bool> stopNotificationPolling() {
    throw UnimplementedError(
      'stopNotificationPolling() has not been implemented.',
    );
  }

  Future<bool> startForegroundService({
    required String pollingUrl,
    int? intervalMinutes,
    String? channelId,
  }) {
    throw UnimplementedError(
      'startForegroundService() has not been implemented.',
    );
  }

  Future<bool> stopForegroundService() {
    throw UnimplementedError(
      'stopForegroundService() has not been implemented.',
    );
  }

  Future<bool> setFirebaseAsActiveService() {
    throw UnimplementedError(
      'setFirebaseAsActiveService() has not been implemented.',
    );
  }

  Future<String> getActiveNotificationService() {
    throw UnimplementedError(
      'getActiveNotificationService() has not been implemented.',
    );
  }

  Future<int> showHeadsUpNotification({
    required String title,
    required String message,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) {
    throw UnimplementedError(
      'showHeadsUpNotification() has not been implemented.',
    );
  }

  Future<int> showFullScreenNotification({
    required String title,
    required String message,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) {
    throw UnimplementedError(
      'showFullScreenNotification() has not been implemented.',
    );
  }

  Future<int> showStyledNotification({
    required String title,
    required String message,
    String? channelId,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) {
    throw UnimplementedError(
      'showStyledNotification() has not been implemented.',
    );
  }

  Future<String?> getDeviceToken() {
    throw UnimplementedError('getDeviceToken() has not been implemented.');
  }

  Future<bool> subscribeToTopic(String topic) {
    throw UnimplementedError('subscribeToTopic() has not been implemented.');
  }

  Future<bool> unsubscribeFromTopic(String topic) {
    throw UnimplementedError(
      'unsubscribeFromTopic() has not been implemented.',
    );
  }

  /// Returns the list of topics the device is currently subscribed to.
  /// On Android/iOS with Firebase this reflects both FCM and local subscriptions.
  /// Without Firebase, it reflects locally stored subscriptions only.
  Future<List<String>> getSubscribedTopics() {
    throw UnimplementedError('getSubscribedTopics() has not been implemented.');
  }

  /// Schedule a notification to be delivered by the operating system at a
  /// specific point in time, even when the app is fully closed.
  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String message,
    required int scheduledEpochMillis,
    String? channelId,
    NotificationImportance? importance,
    bool alarmSound = false,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) {
    throw UnimplementedError('scheduleNotification() has not been implemented.');
  }

  /// Cancel a previously scheduled notification by its [id].
  Future<bool> cancelScheduledNotification(int id) {
    throw UnimplementedError(
      'cancelScheduledNotification() has not been implemented.',
    );
  }

  /// Cancel every notification that was scheduled through [scheduleNotification].
  Future<bool> cancelAllScheduledNotifications() {
    throw UnimplementedError(
      'cancelAllScheduledNotifications() has not been implemented.',
    );
  }

  /// Returns the ids of notifications that are scheduled but not yet delivered.
  Future<List<int>> getPendingScheduledNotifications() {
    throw UnimplementedError(
      'getPendingScheduledNotifications() has not been implemented.',
    );
  }

  /// Start a standalone background poller process that keeps polling [pollingUrl]
  /// and showing toasts even after the app is fully closed (Windows only).
  Future<bool> startBackgroundPollingService({
    required String pollingUrl,
    int? intervalMinutes,
  }) {
    throw UnimplementedError(
      'startBackgroundPollingService() has not been implemented.',
    );
  }

  /// Stop the background poller process started via [startBackgroundPollingService].
  Future<bool> stopBackgroundPollingService() {
    throw UnimplementedError(
      'stopBackgroundPollingService() has not been implemented.',
    );
  }

  /// Whether the background poller process is currently running.
  Future<bool> isBackgroundPollingRunning() {
    throw UnimplementedError(
      'isBackgroundPollingRunning() has not been implemented.',
    );
  }

  /// Android 12+: whether the app may schedule exact alarms.
  /// Other platforms return `true`.
  Future<bool> canScheduleExactAlarms() {
    return Future.value(true);
  }

  /// Opens system Settings for "Alarms & reminders" (Android).
  /// User must grant manually. No-op / `false` on other platforms.
  Future<bool> openExactAlarmSettings() {
    return Future.value(false);
  }

  /// Opens app notification settings (Android). User must grant manually.
  Future<bool> openAppNotificationSettings() {
    return Future.value(false);
  }
}
