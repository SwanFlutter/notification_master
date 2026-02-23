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
}
