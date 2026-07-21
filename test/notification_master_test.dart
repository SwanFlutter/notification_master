import 'package:flutter_test/flutter_test.dart';
import 'package:notification_master/notification_master_method_channel.dart';
import 'package:notification_master/notification_master_platform_interface.dart';
import 'package:notification_master/src/tools/notification_importance.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// ── In-memory mock ─────────────────────────────────────────────────────────

class MockNotificationMasterPlatform
    with MockPlatformInterfaceMixin
    implements NotificationMasterPlatform {
  String? _deviceToken = 'mock-device-token-abc123';
  final List<String> _topics = [];

  // ── Stubs ──────────────────────────────────────────────────────────────
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
  @override
  Future<bool> checkNotificationPermission() => Future.value(true);
  @override
  Future<bool> requestNotificationPermission() => Future.value(true);
  @override
  Future<bool> setFirebaseAsActiveService() => Future.value(true);
  @override
  Future<String> getActiveNotificationService() => Future.value('none');
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
  Future<int> showHeadsUpNotification({
    required String title,
    required String message,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) => Future.value(5);
  @override
  Future<int> showFullScreenNotification({
    required String title,
    required String message,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) => Future.value(6);
  @override
  Future<int> showStyledNotification({
    required String title,
    required String message,
    String? channelId,
    String? targetScreen,
    Map<String, dynamic>? extraData,
  }) => Future.value(7);

  // ── Under test ─────────────────────────────────────────────────────────
  @override
  Future<String?> getDeviceToken() => Future.value(_deviceToken);

  @override
  Future<bool> subscribeToTopic(String topic) {
    if (!_topics.contains(topic)) _topics.add(topic);
    return Future.value(true);
  }

  @override
  Future<bool> unsubscribeFromTopic(String topic) {
    _topics.remove(topic);
    return Future.value(true);
  }

  @override
  Future<List<String>> getSubscribedTopics() =>
      Future.value(List.unmodifiable(_topics));

  @override
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
  }) => Future.value(true);

  @override
  Future<bool> cancelScheduledNotification(int id) => Future.value(true);

  @override
  Future<bool> cancelAllScheduledNotifications() => Future.value(true);

  @override
  Future<List<int>> getPendingScheduledNotifications() =>
      Future.value(const []);

  // ── Helpers ────────────────────────────────────────────────────────────
  void setDeviceToken(String? token) => _deviceToken = token;
  void clearTopics() => _topics.clear();

  @override
  Future<bool> isBackgroundPollingRunning() {
    throw UnimplementedError();
  }

  @override
  Future<bool> startBackgroundPollingService({
    required String pollingUrl,
    int? intervalMinutes,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> stopBackgroundPollingService() {
    throw UnimplementedError();
  }

  @override
  Future<bool> canScheduleExactAlarms() {
    throw UnimplementedError();
  }

  @override
  Future<bool> openAppNotificationSettings() {
    throw UnimplementedError();
  }

  @override
  Future<bool> openExactAlarmSettings() {
    throw UnimplementedError();
  }
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  // Tests call platform interface directly — no WidgetsBinding needed
  late MockNotificationMasterPlatform mock;

  setUp(() {
    mock = MockNotificationMasterPlatform();
    NotificationMasterPlatform.instance = mock;
  });

  // ── Sanity ─────────────────────────────────────────────────────────────
  test('MethodChannelNotificationMaster is default concrete type', () {
    // Verify the real channel class exists and is the original default
    expect(
      MethodChannelNotificationMaster(),
      isInstanceOf<NotificationMasterPlatform>(),
    );
  });

  test('mock is registered as the active instance', () {
    expect(NotificationMasterPlatform.instance, same(mock));
  });

  // ── getDeviceToken ──────────────────────────────────────────────────────
  group('getDeviceToken', () {
    test('returns the token string when available', () async {
      final token = await NotificationMasterPlatform.instance.getDeviceToken();
      expect(token, equals('mock-device-token-abc123'));
    });

    test('token is non-null and non-empty', () async {
      final token = await NotificationMasterPlatform.instance.getDeviceToken();
      expect(token, isNotNull);
      expect(token, isNotEmpty);
    });

    test('returns null when platform reports no token', () async {
      mock.setDeviceToken(null);
      final token = await NotificationMasterPlatform.instance.getDeviceToken();
      expect(token, isNull);
    });

    test('returns updated token after setDeviceToken', () async {
      mock.setDeviceToken('new-token-xyz');
      final token = await NotificationMasterPlatform.instance.getDeviceToken();
      expect(token, equals('new-token-xyz'));
    });
  });

  // ── subscribeToTopic ────────────────────────────────────────────────────
  group('subscribeToTopic', () {
    setUp(() => mock.clearTopics());

    test('returns true on success', () async {
      final result = await NotificationMasterPlatform.instance.subscribeToTopic(
        'news',
      );
      expect(result, isTrue);
    });

    test('subscribed topic appears in getSubscribedTopics', () async {
      await NotificationMasterPlatform.instance.subscribeToTopic('news');
      final topics = await NotificationMasterPlatform.instance
          .getSubscribedTopics();
      expect(topics, contains('news'));
    });

    test('subscribing multiple different topics works', () async {
      await NotificationMasterPlatform.instance.subscribeToTopic('news');
      await NotificationMasterPlatform.instance.subscribeToTopic('offers');
      await NotificationMasterPlatform.instance.subscribeToTopic('alerts');
      final topics = await NotificationMasterPlatform.instance
          .getSubscribedTopics();
      expect(topics, containsAll(['news', 'offers', 'alerts']));
    });

    test('duplicate subscribe does not add topic twice', () async {
      await NotificationMasterPlatform.instance.subscribeToTopic('news');
      await NotificationMasterPlatform.instance.subscribeToTopic('news');
      final topics = await NotificationMasterPlatform.instance
          .getSubscribedTopics();
      expect(topics.where((t) => t == 'news').length, equals(1));
    });
  });

  // ── unsubscribeFromTopic ────────────────────────────────────────────────
  group('unsubscribeFromTopic', () {
    setUp(() => mock.clearTopics());

    test('returns true on success', () async {
      await NotificationMasterPlatform.instance.subscribeToTopic('news');
      final result = await NotificationMasterPlatform.instance
          .unsubscribeFromTopic('news');
      expect(result, isTrue);
    });

    test('topic is absent after unsubscribe', () async {
      await NotificationMasterPlatform.instance.subscribeToTopic('news');
      await NotificationMasterPlatform.instance.unsubscribeFromTopic('news');
      final topics = await NotificationMasterPlatform.instance
          .getSubscribedTopics();
      expect(topics, isNot(contains('news')));
    });

    test('unsubscribing a non-subscribed topic still returns true', () async {
      final result = await NotificationMasterPlatform.instance
          .unsubscribeFromTopic('ghost');
      expect(result, isTrue);
    });

    test('only the targeted topic is removed', () async {
      await NotificationMasterPlatform.instance.subscribeToTopic('news');
      await NotificationMasterPlatform.instance.subscribeToTopic('offers');
      await NotificationMasterPlatform.instance.unsubscribeFromTopic('news');
      final topics = await NotificationMasterPlatform.instance
          .getSubscribedTopics();
      expect(topics, isNot(contains('news')));
      expect(topics, contains('offers'));
    });
  });

  // ── getSubscribedTopics ─────────────────────────────────────────────────
  group('getSubscribedTopics', () {
    setUp(() => mock.clearTopics());

    test('returns empty list when nothing subscribed', () async {
      final topics = await NotificationMasterPlatform.instance
          .getSubscribedTopics();
      expect(topics, isEmpty);
    });

    test('returns all subscribed topics', () async {
      await NotificationMasterPlatform.instance.subscribeToTopic('news');
      await NotificationMasterPlatform.instance.subscribeToTopic('offers');
      final topics = await NotificationMasterPlatform.instance
          .getSubscribedTopics();
      expect(topics.length, equals(2));
      expect(topics, containsAll(['news', 'offers']));
    });

    test('count decreases after unsubscribe', () async {
      await NotificationMasterPlatform.instance.subscribeToTopic('news');
      await NotificationMasterPlatform.instance.subscribeToTopic('offers');
      await NotificationMasterPlatform.instance.unsubscribeFromTopic('offers');
      final topics = await NotificationMasterPlatform.instance
          .getSubscribedTopics();
      expect(topics.length, equals(1));
      expect(topics, contains('news'));
    });

    test('empty list after all topics unsubscribed', () async {
      await NotificationMasterPlatform.instance.subscribeToTopic('news');
      await NotificationMasterPlatform.instance.unsubscribeFromTopic('news');
      final topics = await NotificationMasterPlatform.instance
          .getSubscribedTopics();
      expect(topics, isEmpty);
    });
  });

  // ── Full server-side workflow ───────────────────────────────────────────
  group('token + topic server-side workflow', () {
    setUp(() => mock.clearTopics());

    test('token exists and topics can be bundled for server sync', () async {
      final token = await NotificationMasterPlatform.instance.getDeviceToken();
      expect(token, isNotNull);
      expect(token, isNotEmpty);

      await NotificationMasterPlatform.instance.subscribeToTopic('news');
      await NotificationMasterPlatform.instance.subscribeToTopic('offers');

      final topics = await NotificationMasterPlatform.instance
          .getSubscribedTopics();
      expect(topics, containsAll(['news', 'offers']));

      // Simulate building the server payload
      final payload = {'token': token, 'topics': topics};
      expect(payload['token'], isNotNull);
      expect((payload['topics'] as List).length, equals(2));
    });

    test('topics list is empty after unsubscribing all', () async {
      await NotificationMasterPlatform.instance.subscribeToTopic('news');
      await NotificationMasterPlatform.instance.subscribeToTopic('offers');
      await NotificationMasterPlatform.instance.unsubscribeFromTopic('news');
      await NotificationMasterPlatform.instance.unsubscribeFromTopic('offers');

      final topics = await NotificationMasterPlatform.instance
          .getSubscribedTopics();
      expect(topics, isEmpty);
    });

    test('subscribe → unsubscribe → re-subscribe preserves topic', () async {
      await NotificationMasterPlatform.instance.subscribeToTopic('news');
      await NotificationMasterPlatform.instance.unsubscribeFromTopic('news');
      await NotificationMasterPlatform.instance.subscribeToTopic('news');

      final topics = await NotificationMasterPlatform.instance
          .getSubscribedTopics();
      expect(topics, contains('news'));
      expect(topics.where((t) => t == 'news').length, equals(1));
    });
  });
}
