import 'package:flutter_test/flutter_test.dart';
import 'package:notification_master/notification_master.dart';
import 'package:notification_master/notification_master_method_channel.dart';
import 'package:notification_master/notification_master_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNotificationMasterPlatform
    with MockPlatformInterfaceMixin
    implements NotificationMasterPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool> checkNotificationPermission() {
    // TODO: implement checkNotificationPermission
    throw UnimplementedError();
  }

  @override
  Future<bool> createCustomChannel(
      {required String channelId,
      required String channelName,
      String? channelDescription,
      int? importance,
      bool? enableLights,
      int? lightColor,
      bool? enableVibration,
      bool? enableSound}) {
    // TODO: implement createCustomChannel
    throw UnimplementedError();
  }

  @override
  Future<String> getActiveNotificationService() {
    // TODO: implement getActiveNotificationService
    throw UnimplementedError();
  }

  @override
  Future<bool> requestNotificationPermission() {
    // TODO: implement requestNotificationPermission
    throw UnimplementedError();
  }

  @override
  Future<bool> setFirebaseAsActiveService() {
    // TODO: implement setFirebaseAsActiveService
    throw UnimplementedError();
  }

  @override
  Future<int> showBigTextNotification(
      {required String title,
      required String message,
      required String bigText,
      String? channelId,
      NotificationImportance? importance,
      bool? autoCancel,
      String? targetScreen,
      Map<String, dynamic>? extraData}) {
    // TODO: implement showBigTextNotification
    throw UnimplementedError();
  }

  @override
  Future<int> showImageNotification(
      {required String title,
      required String message,
      required String imageUrl,
      String? channelId,
      NotificationImportance? importance,
      bool? autoCancel,
      String? targetScreen,
      Map<String, dynamic>? extraData}) {
    // TODO: implement showImageNotification
    throw UnimplementedError();
  }

  @override
  Future<int> showNotification(
      {int? id,
      required String title,
      required String message,
      String? channelId,
      NotificationImportance? importance,
      bool? autoCancel,
      String? targetScreen,
      Map<String, dynamic>? extraData}) {
    // TODO: implement showNotification
    throw UnimplementedError();
  }

  @override
  Future<int> showNotificationWithActions(
      {required String title,
      required String message,
      required List<Map<String, String>> actions,
      String? channelId,
      NotificationImportance? importance,
      bool? autoCancel,
      String? targetScreen,
      Map<String, dynamic>? extraData}) {
    // TODO: implement showNotificationWithActions
    throw UnimplementedError();
  }

  @override
  Future<bool> startForegroundService(
      {required String pollingUrl, int? intervalMinutes, String? channelId}) {
    // TODO: implement startForegroundService
    throw UnimplementedError();
  }

  @override
  Future<bool> startNotificationPolling(
      {required String pollingUrl, int? intervalMinutes}) {
    // TODO: implement startNotificationPolling
    throw UnimplementedError();
  }

  @override
  Future<bool> stopForegroundService() {
    // TODO: implement stopForegroundService
    throw UnimplementedError();
  }

  @override
  Future<bool> stopNotificationPolling() {
    // TODO: implement stopNotificationPolling
    throw UnimplementedError();
  }

  @override
  Future<int> showFullScreenNotification(
      {required String title,
      required String message,
      String? targetScreen,
      Map<String, dynamic>? extraData}) {
    // TODO: implement showFullScreenNotification
    throw UnimplementedError();
  }

  @override
  Future<int> showHeadsUpNotification(
      {required String title,
      required String message,
      String? targetScreen,
      Map<String, dynamic>? extraData}) {
    // TODO: implement showHeadsUpNotification
    throw UnimplementedError();
  }

  @override
  Future<int> showStyledNotification(
      {required String title,
      required String message,
      String? channelId,
      String? targetScreen,
      Map<String, dynamic>? extraData}) {
    // TODO: implement showStyledNotification
    throw UnimplementedError();
  }
}

void main() {
  final NotificationMasterPlatform initialPlatform =
      NotificationMasterPlatform.instance;

  test('$MethodChannelNotificationMaster is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNotificationMaster>());
  });

  test('getPlatformVersion', () async {
    NotificationMaster notificationMasterPlugin = NotificationMaster();
    MockNotificationMasterPlatform fakePlatform =
        MockNotificationMasterPlatform();
    NotificationMasterPlatform.instance = fakePlatform;

    expect(await notificationMasterPlugin.getPlatformVersion(), '42');
  });
}
