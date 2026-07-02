import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:notification_master/notification_master.dart';

class NotificationPollingClient {
  NotificationPollingClient({
    required this.pollingUrl,
    this.intervalSeconds = 60,
    this.channelId = 'server_notifications',
    this.channelName = 'Server Notifications',
    this.channelDescription = 'Notifications from server',
    this.importance = NotificationImportance.defaultImportance,
    this.enableSound = true,
    this.enableVibration = true,
    this.defaultAutoCancel = true,
  });

  final String pollingUrl;
  final int intervalSeconds;
  final String channelId;
  final String channelName;
  final String channelDescription;
  final NotificationImportance importance;
  final bool enableSound;
  final bool enableVibration;
  final bool defaultAutoCancel;

  final NotificationMaster _notificationMaster = NotificationMaster();
  Timer? _timer;
  bool _initialized = false;

  Future<void> initialize() async {
    final hasPermission = await _notificationMaster
        .checkNotificationPermission();
    if (!hasPermission) {
      final granted = await _notificationMaster.requestNotificationPermission();
      if (!granted) {
        return;
      }
    }

    await _notificationMaster.createCustomChannel(
      channelId: channelId,
      channelName: channelName,
      channelDescription: channelDescription,
      importance: importance,
      enableSound: enableSound,
      enableVibration: enableVibration,
    );

    _initialized = true;
  }

  Future<void> startLocalPolling({bool runImmediately = true}) async {
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) {
      return;
    }
    _timer?.cancel();
    if (runImmediately) {
      await pollOnce();
    }
    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (_) async {
      await pollOnce();
    });
  }

  Future<void> stopLocalPolling() async {
    _timer?.cancel();
    _timer = null;
  }

  Future<bool> startForegroundServicePolling({
    int? intervalMinutes,
    String? serviceChannelId,
    String? serviceChannelName,
    String? serviceChannelDescription,
    NotificationImportance serviceImportance =
        NotificationImportance.defaultImportance,
    bool serviceEnableSound = true,
    bool serviceEnableVibration = false,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) {
      return false;
    }
    final minutes = intervalMinutes ?? (intervalSeconds / 60).ceil();
    return _notificationMaster.startForegroundService(
      pollingUrl: pollingUrl,
      intervalMinutes: minutes < 1 ? 1 : minutes,
      channelId: serviceChannelId ?? 'polling_service',
      channelName: serviceChannelName ?? 'Notification Service',
      channelDescription:
          serviceChannelDescription ?? 'Keeps checking for new notifications',
      importance: serviceImportance,
      enableSound: serviceEnableSound,
      enableVibration: serviceEnableVibration,
    );
  }

  Future<bool> startBackgroundPolling({int? intervalMinutes}) async {
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) {
      return false;
    }
    final minutes = intervalMinutes ?? (intervalSeconds / 60).ceil();
    return _notificationMaster.startNotificationPolling(
      pollingUrl: pollingUrl,
      intervalMinutes: minutes < 1 ? 1 : minutes,
    );
  }

  Future<void> stopAllPolling() async {
    await stopLocalPolling();
    await _notificationMaster.stopForegroundService();
    await _notificationMaster.stopNotificationPolling();
  }

  Future<void> pollOnce() async {
    final response = await _getJson(pollingUrl);
    if (response == null) {
      return;
    }
    final notifications = _extractNotifications(response);
    if (notifications.isEmpty) {
      return;
    }
    for (final item in notifications) {
      final title = item['title']?.toString() ?? '';
      final message = item['message']?.toString() ?? '';
      if (title.isEmpty && message.isEmpty) {
        continue;
      }
      final bigText = item['bigText']?.toString();
      final channel = item['channelId']?.toString() ?? channelId;
      if (bigText != null && bigText.isNotEmpty) {
        await _notificationMaster.showBigTextNotification(
          title: title,
          message: message,
          bigText: bigText,
          channelId: channel,
          autoCancel: defaultAutoCancel,
        );
      } else {
        await _notificationMaster.showNotification(
          title: title,
          message: message,
          channelId: channel,
          autoCancel: defaultAutoCancel,
        );
      }
    }
  }

  List<Map<String, dynamic>> _extractNotifications(Map<String, dynamic> json) {
    final notifications = <Map<String, dynamic>>[];

    // Check for "notifications" array format: {"notifications": [...]}
    final list = json['notifications'];
    if (list is List) {
      for (final item in list) {
        if (item is Map) {
          notifications.add(Map<String, dynamic>.from(item));
        }
      }
      return notifications;
    }

    // Check for PHP server format: {"success": true, "data": {...}}
    final data = json['data'];
    if (data is Map) {
      final title = data['title']?.toString() ?? '';
      final message = data['message']?.toString() ?? '';

      // Ensure at least title or message is not empty
      if (title.isNotEmpty || message.isNotEmpty) {
        final mapped = <String, dynamic>{
          'title': title.isNotEmpty ? title : 'Notification',
          'message': message.isNotEmpty ? message : '',
          'bigText':
              data['big_text']?.toString() ?? data['bigText']?.toString(),
          'channelId':
              data['channel_id']?.toString() ?? data['channelId']?.toString(),
        };
        notifications.add(mapped);
      }
      return notifications;
    }

    // Check if data is a list: {"data": [...]}
    if (data is List) {
      for (final item in data) {
        if (item is Map) {
          notifications.add(Map<String, dynamic>.from(item));
        }
      }
    }

    return notifications;
  }

  Future<Map<String, dynamic>?> _getJson(String url) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
