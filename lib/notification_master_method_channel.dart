import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'notification_master_platform_interface.dart';
import 'src/tools/notification_importance.dart';

/// An implementation of [NotificationMasterPlatform] that uses method channels.
class MethodChannelNotificationMaster extends NotificationMasterPlatform {
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
    int? id,
    required String title,
    required String message,
    String? channelId,
    NotificationImportance? importance,
    bool? autoCancel,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) async {
    final args = <String, dynamic>{
      'id': id,
      'title': title,
      'message': message,
      'channelId': channelId,
      'autoCancel': autoCancel,
      'targetScreen': targetScreen,
      'extraData': extraData,
    };
    if (importance != null) args['priority'] = importance.value;
    final result =
        await methodChannel.invokeMethod<int>('showNotification', args);
    return result ?? -1;
  }

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
    final result =
        await methodChannel.invokeMethod<int>('showBigTextNotification', {
      'title': title,
      'message': message,
      'bigText': bigText,
      'channelId': channelId,
      'priority': importance?.value,
      'autoCancel': autoCancel,
      'targetScreen': targetScreen,
      'extraData': extraData,
    });
    return result ?? -1;
  }

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
    final args = <String, dynamic>{
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'channelId': channelId,
      'autoCancel': autoCancel,
      'targetScreen': targetScreen,
      'extraData': extraData,
    };
    if (importance != null) args['priority'] = importance.value;
    final result =
        await methodChannel.invokeMethod<int>('showImageNotification', args);
    return result ?? -1;
  }

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
    final args = <String, dynamic>{
      'title': title,
      'message': message,
      'actions': actions,
      'channelId': channelId,
      'autoCancel': autoCancel,
      'targetScreen': targetScreen,
      'extraData': extraData,
    };
    if (importance != null) args['priority'] = importance.value;
    final result = await methodChannel.invokeMethod<int>(
        'showNotificationWithActions', args);
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
    final result =
        await methodChannel.invokeMethod<bool>('createCustomChannel', {
      'channelId': channelId,
      'channelName': channelName,
      'channelDescription': channelDescription,
      'importance': importance,
      'enableLights': enableLights,
      'lightColor': lightColor,
      'enableVibration': enableVibration,
      'enableSound': enableSound,
    });
    return result ?? false;
  }

  @override
  Future<bool> startNotificationPolling({
    required String pollingUrl,
    int? intervalMinutes,
  }) async {
    final result = await methodChannel.invokeMethod<bool>(
      'startNotificationPolling',
      {'pollingUrl': pollingUrl, 'intervalMinutes': intervalMinutes},
    );
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
    String? channelId,
  }) async {
    final result =
        await methodChannel.invokeMethod<bool>('startForegroundService', {
      'pollingUrl': pollingUrl,
      'intervalMinutes': intervalMinutes,
      'channelId': channelId,
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

  @override
  Future<int> showHeadsUpNotification({
    required String title,
    required String message,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) async {
    final result = await methodChannel.invokeMethod<int>(
      'showHeadsUpNotification',
      {
        'title': title,
        'message': message,
        'targetScreen': targetScreen,
        'extraData': extraData,
      },
    );
    return result ?? -1;
  }

  @override
  Future<int> showFullScreenNotification({
    required String title,
    required String message,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) async {
    final result = await methodChannel.invokeMethod<int>(
      'showFullScreenNotification',
      {
        'title': title,
        'message': message,
        'targetScreen': targetScreen,
        'extraData': extraData,
      },
    );
    return result ?? -1;
  }

  @override
  Future<int> showStyledNotification({
    required String title,
    required String message,
    String? channelId,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) async {
    final result = await methodChannel.invokeMethod<int>(
      'showStyledNotification',
      {
        'title': title,
        'message': message,
        'channelId': channelId,
        'targetScreen': targetScreen,
        'extraData': extraData,
      },
    );
    return result ?? -1;
  }
}
