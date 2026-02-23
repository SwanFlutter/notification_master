import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'notification_polling_logic.dart';

const String pollingTask = "notification_polling_task";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == pollingTask) {
      final pollingUrl = inputData?['pollingUrl'] as String?;
      if (pollingUrl == null) return Future.value(false);

      try {
        await fetchAndShowNotifications(pollingUrl);
      } catch (e) {
        debugPrint("Polling error: $e");
        return Future.value(false);
      }
    }
    return Future.value(true);
  });
}

class NotificationPolling {
  static Timer? _desktopTimer;

  static Future<void> initialize() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
    }
  }

  static Future<void> startPolling({
    required String url,
    int frequencyInMinutes = 15,
  }) async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Register periodic task
      await Workmanager().registerPeriodicTask(
        "polling_task_unique_id",
        pollingTask,
        frequency: Duration(minutes: frequencyInMinutes),
        inputData: {'pollingUrl': url},
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        initialDelay: Duration(seconds: 10), // Start relatively soon
      );
    } else {
      // Desktop polling (while app is running)
      _startDesktopTimer(url, frequencyInMinutes);
    }
  }

  static void stopPolling() {
    if (Platform.isAndroid || Platform.isIOS) {
      Workmanager().cancelAll();
    }
    _desktopTimer?.cancel();
    _desktopTimer = null;
  }

  static void _startDesktopTimer(String url, int frequencyInMinutes) {
    _desktopTimer?.cancel();
    // Run immediately first
    fetchAndShowNotifications(url)
        .catchError((e) => debugPrint("Desktop polling error: $e"));

    // Then periodically
    _desktopTimer =
        Timer.periodic(Duration(minutes: frequencyInMinutes), (_) async {
      try {
        await fetchAndShowNotifications(url);
      } catch (e) {
        debugPrint("Desktop polling error: $e");
      }
    });
  }
}
