import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class NotificationPolling {
  static const _channel = MethodChannel('notification_master');

  static Future<void> initialize() async {
    // No initialization needed — native side handles everything
  }

  static Future<void> startPolling({
    required String url,
    int frequencyInMinutes = 15,
  }) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await _channel.invokeMethod('startNotificationPolling', {
        'pollingUrl': url,
        'intervalMinutes': frequencyInMinutes,
      });
    } else {
      // Desktop platforms not supported for background polling
    }
  }

  static void stopPolling() {
    if (Platform.isAndroid || Platform.isIOS) {
      _channel.invokeMethod('stopNotificationPolling');
    }
  }
}
