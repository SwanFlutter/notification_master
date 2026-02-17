library;

import 'notification_master_platform_interface.dart';

export 'notification_master_desktop.dart';
export 'notification_master_platform_interface.dart'
    show NotificationImportance;
export 'unified_notification_service.dart';

/// The main plugin class for NotificationMaster.
///
/// This plugin provides easy-to-use notification functionality for Android 7+ (API level 24+).
/// It handles all the necessary permissions, manifest entries, and notification channel setup.
class NotificationMaster {
  /// Get the platform version.
  Future<String?> getPlatformVersion() {
    return NotificationMasterPlatform.instance.getPlatformVersion();
  }

  /// Request notification permission.
  ///
  /// This is required for Android 13+ (API level 33+).
  /// Returns true if permission is granted or not needed.
  Future<bool> requestNotificationPermission() {
    return NotificationMasterPlatform.instance.requestNotificationPermission();
  }

  /// Check if notification permission is granted.
  ///
  /// Returns true if permission is granted or not needed.
  Future<bool> checkNotificationPermission() {
    return NotificationMasterPlatform.instance.checkNotificationPermission();
  }

  /// Show a simple notification.
  ///
  /// Parameters:
  /// - [id]: Optional notification ID (if not provided, one will be generated)
  /// - [title]: The notification title
  /// - [message]: The notification message
  /// - [channelId]: Optional custom channel ID (defaults to the default channel)
  /// - [importance]: Optional notification importance level (defaults to NotificationImportance.defaultImportance)
  /// - [autoCancel]: Whether the notification should be auto-canceled when tapped
  /// - [targetScreen]: Optional screen name to open when notification is tapped
  /// - [extraData]: Optional map of extra data to pass to the target screen
  ///
  /// Returns the notification ID.
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

  /// Show a notification with big text style.
  ///
  /// Parameters:
  /// - [title]: The notification title
  /// - [message]: The notification message (shown in the collapsed state)
  /// - [bigText]: The expanded text content
  /// - [channelId]: Optional custom channel ID (defaults to the default channel)
  /// - [importance]: Optional notification importance level (defaults to NotificationImportance.defaultImportance)
  /// - [autoCancel]: Whether the notification should be auto-canceled when tapped
  /// - [targetScreen]: Optional screen name to open when notification is tapped
  /// - [extraData]: Optional map of extra data to pass to the target screen
  ///
  /// Returns the notification ID.
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

  /// Show a notification with an image.
  ///
  /// Parameters:
  /// - [title]: The notification title
  /// - [message]: The notification message
  /// - [imageUrl]: The URL of the image to display
  /// - [channelId]: Optional custom channel ID (defaults to the default channel)
  /// - [importance]: Optional notification importance level (defaults to NotificationImportance.defaultImportance)
  /// - [autoCancel]: Whether the notification should be auto-canceled when tapped
  /// - [targetScreen]: Optional screen name to open when notification is tapped
  /// - [extraData]: Optional map of extra data to pass to the target screen
  ///
  /// Returns the notification ID.
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

  /// Show a notification with custom actions.
  ///
  /// Parameters:
  /// - [title]: The notification title
  /// - [message]: The notification message
  /// - [actions]: List of action maps, each with 'title' and 'route' keys
  /// - [channelId]: Optional custom channel ID (defaults to the default channel)
  /// - [importance]: Optional notification importance level (defaults to NotificationImportance.defaultImportance)
  /// - [autoCancel]: Whether the notification should be auto-canceled when tapped
  /// - [targetScreen]: Optional screen name to open when notification is tapped
  /// - [extraData]: Optional map of extra data to pass to the target screen
  ///
  /// Returns the notification ID.
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

  /// Create a custom notification channel.
  ///
  /// This is only needed for Android 8.0+ (API level 26+).
  ///
  /// Parameters:
  /// - [channelId]: The channel ID
  /// - [channelName]: The channel name (display name shown to users in settings)
  /// - [channelDescription]: Optional channel description
  /// - [importance]: Optional importance level using [NotificationImportance] enum
  /// - [enableLights]: Whether to enable lights
  /// - [lightColor]: The light color
  /// - [enableVibration]: Whether to enable vibration
  /// - [enableSound]: Whether to enable sound
  ///
  /// Returns true if the channel was created successfully.
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

  /// Start polling for notifications from a remote server.
  ///
  /// This uses WorkManager for battery-efficient background tasks.
  /// The server should return JSON in the format:
  /// ```json
  /// {
  ///   "notifications": [
  ///     {
  ///       "title": "Notification Title",
  ///       "message": "Notification Message",
  ///       "bigText": "Optional expanded text",
  ///       "channelId": "Optional custom channel ID"
  ///     }
  ///   ]
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [pollingUrl]: The URL to poll for notifications
  /// - [intervalMinutes]: Optional polling interval in minutes (defaults to 15)
  ///
  /// Returns true if polling was started successfully.
  Future<bool> startNotificationPolling({
    required String pollingUrl,
    int? intervalMinutes,
  }) {
    return NotificationMasterPlatform.instance.startNotificationPolling(
      pollingUrl: pollingUrl,
      intervalMinutes: intervalMinutes,
    );
  }

  /// Stop polling for notifications.
  ///
  /// Returns true if polling was stopped successfully.
  Future<bool> stopNotificationPolling() {
    return NotificationMasterPlatform.instance.stopNotificationPolling();
  }

  /// Start a foreground service for continuous notification polling.
  ///
  /// This creates a persistent notification and runs a service that is less likely
  /// to be killed by the system. Use this for more reliable notification delivery.
  ///
  /// Parameters:
  /// - [pollingUrl]: The URL to poll for notifications
  /// - [intervalMinutes]: Optional polling interval in minutes (defaults to 15)
  /// - [channelId]: Optional channel ID for the foreground service notification
  /// - [channelName]: Optional channel name for the foreground service notification
  /// - [channelDescription]: Optional channel description
  /// - [importance]: Optional importance level for the notification channel using [NotificationImportance] enum
  /// - [enableLights]: Whether to enable lights for the notification channel
  /// - [lightColor]: The light color for the notification channel
  /// - [enableVibration]: Whether to enable vibration for the notification channel
  /// - [enableSound]: Whether to enable sound for the notification channel
  ///
  /// Returns true if the service was started successfully.
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
  }) {
    // Create custom channel if channel parameters are provided
    if (channelId != null && channelName != null) {
      createCustomChannel(
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

  /// Stop the foreground service for notification polling.
  ///
  /// Returns true if the service was stopped successfully.
  Future<bool> stopForegroundService() {
    return NotificationMasterPlatform.instance.stopForegroundService();
  }

  /// Set Firebase Cloud Messaging as the active notification service.
  ///
  /// This will disable any other active notification services (polling or foreground).
  /// Use this when you want to use Firebase for notifications instead of the built-in services.
  ///
  /// Returns true if the operation was successful.
  Future<bool> setFirebaseAsActiveService() {
    return NotificationMasterPlatform.instance.setFirebaseAsActiveService();
  }

  /// Get the currently active notification service.
  ///
  /// Returns a string representing the active service:
  /// - "none": No notification service is active
  /// - "polling": The WorkManager polling service is active
  /// - "foreground": The foreground service is active
  /// - "firebase": Firebase Cloud Messaging is set as the active service
  Future<String> getActiveNotificationService() {
    return NotificationMasterPlatform.instance.getActiveNotificationService();
  }
}
