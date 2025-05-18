import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'notification_master_method_channel.dart';

abstract class NotificationMasterPlatform extends PlatformInterface {
  /// Constructs a NotificationMasterPlatform.
  NotificationMasterPlatform() : super(token: _token);

  static final Object _token = Object();

  static NotificationMasterPlatform _instance =
      MethodChannelNotificationMaster();

  /// The default instance of [NotificationMasterPlatform] to use.
  ///
  /// Defaults to [MethodChannelNotificationMaster].
  static NotificationMasterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NotificationMasterPlatform] when
  /// they register themselves.
  static set instance(NotificationMasterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Get the platform version.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Request notification permission.
  ///
  /// This is required for Android 13+ (API level 33+).
  /// Returns true if permission is granted or not needed.
  Future<bool> requestNotificationPermission() {
    throw UnimplementedError(
      'requestNotificationPermission() has not been implemented.',
    );
  }

  /// Check if notification permission is granted.
  ///
  /// Returns true if permission is granted or not needed.
  Future<bool> checkNotificationPermission() {
    throw UnimplementedError(
      'checkNotificationPermission() has not been implemented.',
    );
  }

  /// Show a simple notification.
  ///
  /// Returns the notification ID.
  Future<int> showNotification({
    required String title,
    required String message,
    String? channelId,
    int? priority,
    bool? autoCancel,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) {
    throw UnimplementedError('showNotification() has not been implemented.');
  }

  /// Show a notification with big text style.
  ///
  /// Returns the notification ID.
  Future<int> showBigTextNotification({
    required String title,
    required String message,
    required String bigText,
    String? channelId,
    int? priority,
    bool? autoCancel,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) {
    throw UnimplementedError(
      'showBigTextNotification() has not been implemented.',
    );
  }

  /// Show a notification with an image.
  ///
  /// Returns the notification ID.
  Future<int> showImageNotification({
    required String title,
    required String message,
    required String imageUrl,
    String? channelId,
    int? priority,
    bool? autoCancel,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) {
    throw UnimplementedError(
      'showImageNotification() has not been implemented.',
    );
  }

  /// Show a notification with custom actions.
  ///
  /// Each action is a map with 'title' and 'route' keys.
  /// Returns the notification ID.
  Future<int> showNotificationWithActions({
    required String title,
    required String message,
    required List<Map<String, String>> actions,
    String? channelId,
    int? priority,
    bool? autoCancel,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) {
    throw UnimplementedError(
      'showNotificationWithActions() has not been implemented.',
    );
  }

  /// Create a custom notification channel.
  ///
  /// This is only needed for Android 8.0+ (API level 26+).
  /// Returns true if the channel was created successfully.
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

  /// Start polling for notifications from a remote server.
  ///
  /// This uses WorkManager for battery-efficient background tasks.
  /// Returns true if polling was started successfully.
  Future<bool> startNotificationPolling({
    required String pollingUrl,
    int? intervalMinutes,
  }) {
    throw UnimplementedError(
      'startNotificationPolling() has not been implemented.',
    );
  }

  /// Stop polling for notifications.
  ///
  /// Returns true if polling was stopped successfully.
  Future<bool> stopNotificationPolling() {
    throw UnimplementedError(
      'stopNotificationPolling() has not been implemented.',
    );
  }

  /// Start a foreground service for continuous notification polling.
  ///
  /// This creates a persistent notification and runs a service that is less likely
  /// to be killed by the system. Use this for more reliable notification delivery.
  /// Returns true if the service was started successfully.
  Future<bool> startForegroundService({
    required String pollingUrl,
    int? intervalMinutes,
    String? channelId,
  }) {
    throw UnimplementedError(
      'startForegroundService() has not been implemented.',
    );
  }

  /// Stop the foreground service for notification polling.
  ///
  /// Returns true if the service was stopped successfully.
  Future<bool> stopForegroundService() {
    throw UnimplementedError(
      'stopForegroundService() has not been implemented.',
    );
  }

  /// Set Firebase Cloud Messaging as the active notification service.
  ///
  /// This will disable any other active notification services (polling or foreground).
  /// Use this when you want to use Firebase for notifications instead of the built-in services.
  /// Returns true if the operation was successful.
  Future<bool> setFirebaseAsActiveService() {
    throw UnimplementedError(
      'setFirebaseAsActiveService() has not been implemented.',
    );
  }

  /// Get the currently active notification service.
  ///
  /// Returns a string representing the active service:
  /// - "none": No notification service is active
  /// - "polling": The WorkManager polling service is active
  /// - "foreground": The foreground service is active
  /// - "firebase": Firebase Cloud Messaging is set as the active service
  Future<String> getActiveNotificationService() {
    throw UnimplementedError(
      'getActiveNotificationService() has not been implemented.',
    );
  }
}
