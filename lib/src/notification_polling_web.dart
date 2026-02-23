import 'dart:async';

import 'package:flutter/foundation.dart';

import 'notification_polling_logic.dart';

class NotificationPolling {
  static Timer? _webTimer;

  static Future<void> initialize() async {
    // No initialization needed for web
  }

  static Future<void> startPolling({
    required String url,
    int frequencyInMinutes = 15,
  }) async {
    _startWebTimer(url, frequencyInMinutes);
  }

  static void stopPolling() {
    _webTimer?.cancel();
    _webTimer = null;
  }

  static void _startWebTimer(String url, int frequencyInMinutes) {
    _webTimer?.cancel();
    // Run immediately first
    fetchAndShowNotifications(url)
        .catchError((e) => debugPrint("Web polling error: $e"));

    // Then periodically
    _webTimer =
        Timer.periodic(Duration(minutes: frequencyInMinutes), (_) async {
      try {
        await fetchAndShowNotifications(url);
      } catch (e) {
        debugPrint("Web polling error: $e");
      }
    });
  }
}
