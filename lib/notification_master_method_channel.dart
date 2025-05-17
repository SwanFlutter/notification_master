import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'notification_master_platform_interface.dart';

/// An implementation of [NotificationMasterPlatform] that uses method channels.
class MethodChannelNotificationMaster extends NotificationMasterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('notification_master');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<bool> requestNotificationPermission() async {
    final result = await methodChannel.invokeMethod<bool>(
      'requestNotificationPermission',
    );
    return result ?? false;
  }

  @override
  Future<bool> checkNotificationPermission() async {
    final result = await methodChannel.invokeMethod<bool>(
      'checkNotificationPermission',
    );
    return result ?? false;
  }

  @override
  Future<int> showNotification({
    required String title,
    required String message,
    String? channelId,
    int? priority,
    bool? autoCancel,
  }) async {
    final result = await methodChannel.invokeMethod<int>('showNotification', {
      'title': title,
      'message': message,
      if (channelId != null) 'channelId': channelId,
      if (priority != null) 'priority': priority,
      if (autoCancel != null) 'autoCancel': autoCancel,
    });
    return result ?? -1;
  }

  @override
  Future<int> showBigTextNotification({
    required String title,
    required String message,
    required String bigText,
    String? channelId,
    int? priority,
    bool? autoCancel,
  }) async {
    final result = await methodChannel
        .invokeMethod<int>('showBigTextNotification', {
          'title': title,
          'message': message,
          'bigText': bigText,
          if (channelId != null) 'channelId': channelId,
          if (priority != null) 'priority': priority,
          if (autoCancel != null) 'autoCancel': autoCancel,
        });
    return result ?? -1;
  }

  @override
  Future<int> showImageNotification({
    required String title,
    required String message,
    required String imageUrl,
    String? channelId,
    int? priority,
    bool? autoCancel,
  }) async {
    final result = await methodChannel
        .invokeMethod<int>('showImageNotification', {
          'title': title,
          'message': message,
          'imageUrl': imageUrl,
          if (channelId != null) 'channelId': channelId,
          if (priority != null) 'priority': priority,
          if (autoCancel != null) 'autoCancel': autoCancel,
        });
    return result ?? -1;
  }

  @override
  Future<int> showNotificationWithActions({
    required String title,
    required String message,
    required List<Map<String, String>> actions,
    String? channelId,
    int? priority,
    bool? autoCancel,
  }) async {
    final result = await methodChannel
        .invokeMethod<int>('showNotificationWithActions', {
          'title': title,
          'message': message,
          'actions': actions,
          if (channelId != null) 'channelId': channelId,
          if (priority != null) 'priority': priority,
          if (autoCancel != null) 'autoCancel': autoCancel,
        });
    return result ?? -1;
  }

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
    final result = await methodChannel
        .invokeMethod<bool>('createCustomChannel', {
          'channelId': channelId,
          'channelName': channelName,
          if (channelDescription != null)
            'channelDescription': channelDescription,
          if (importance != null) 'importance': importance,
          if (enableLights != null) 'enableLights': enableLights,
          if (lightColor != null) 'lightColor': lightColor,
          if (enableVibration != null) 'enableVibration': enableVibration,
          if (enableSound != null) 'enableSound': enableSound,
        });
    return result ?? false;
  }

  @override
  Future<bool> startNotificationPolling({
    required String pollingUrl,
    int? intervalMinutes,
  }) async {
    final result = await methodChannel
        .invokeMethod<bool>('startNotificationPolling', {
          'pollingUrl': pollingUrl,
          if (intervalMinutes != null) 'intervalMinutes': intervalMinutes,
        });
    return result ?? false;
  }

  @override
  Future<bool> stopNotificationPolling() async {
    final result = await methodChannel.invokeMethod<bool>(
      'stopNotificationPolling',
    );
    return result ?? false;
  }

  @override
  Future<bool> startForegroundService({
    required String pollingUrl,
    int? intervalMinutes,
  }) async {
    final result = await methodChannel
        .invokeMethod<bool>('startForegroundService', {
          'pollingUrl': pollingUrl,
          if (intervalMinutes != null) 'intervalMinutes': intervalMinutes,
        });
    return result ?? false;
  }

  @override
  Future<bool> stopForegroundService() async {
    final result = await methodChannel.invokeMethod<bool>(
      'stopForegroundService',
    );
    return result ?? false;
  }

  @override
  Future<bool> setFirebaseAsActiveService() async {
    final result = await methodChannel.invokeMethod<bool>(
      'setFirebaseAsActiveService',
    );
    return result ?? false;
  }

  @override
  Future<String> getActiveNotificationService() async {
    final result = await methodChannel.invokeMethod<String>(
      'getActiveNotificationService',
    );
    return result ?? 'none';
  }
}
