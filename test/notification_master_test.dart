import 'package:flutter_test/flutter_test.dart';
import 'package:notification_master/notification_master.dart';
import 'package:notification_master/notification_master_method_channel.dart';
import 'package:notification_master/notification_master_platform_interface.dart'
    hide NotificationImportance;
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNotificationMasterPlatform
    with MockPlatformInterfaceMixin
    implements NotificationMasterPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool> requestNotificationPermission() => Future.value(true);

  @override
  Future<bool> checkNotificationPermission() => Future.value(true);

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
  }) => Future.value(id ?? 1);

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
  }) => Future.value(2);

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
  }) => Future.value(3);

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
  }) => Future.value(4);

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
  }) => Future.value(true);

  @override
  Future<bool> startNotificationPolling({
    required String pollingUrl,
    int? intervalMinutes,
  }) => Future.value(true);

  @override
  Future<bool> stopNotificationPolling() => Future.value(true);

  @override
  Future<bool> startForegroundService({
    required String pollingUrl,
    int? intervalMinutes,
    String? channelId,
  }) => Future.value(true);

  @override
  Future<bool> stopForegroundService() => Future.value(true);

  @override
  Future<bool> setFirebaseAsActiveService() => Future.value(true);

  @override
  Future<String> getActiveNotificationService() => Future.value('none');
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
