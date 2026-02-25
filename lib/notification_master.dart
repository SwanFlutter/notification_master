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
          _notificationTapController
              .add(Map<String, dynamic>.from(call.arguments));
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
}
