import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../notification_master.dart';

Future<void> fetchAndShowNotifications(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    if (data is Map<String, dynamic>) {
      // Check if it's a wrapper like { "notifications": [...] }
      if (data.containsKey('notifications') && data['notifications'] is List) {
        for (var item in data['notifications']) {
          if (item is Map<String, dynamic>) {
            await processNotification(item);
          }
        }
      } else {
        await processNotification(data);
      }
    } else if (data is List) {
      for (var item in data) {
        if (item is Map<String, dynamic>) {
          await processNotification(item);
        }
      }
    }
  }
}

Future<void> processNotification(Map<String, dynamic> data) async {
  final master = NotificationMaster();

  // Basic validation
  if (!data.containsKey('title') || !data.containsKey('message')) {
    return;
  }

  final String title = data['title'];
  final String message = data['message'];
  final int? id = data['id'] is int ? data['id'] : null;
  final String? channelId = data['channelId'];
  final String? imageUrl = data['imageUrl'];
  final String? bigText = data['bigText'];

  // Determine importance
  NotificationImportance importance = NotificationImportance.defaultImportance;
  if (data['importance'] != null) {
    // Map string or int to enum
    final imp = data['importance'];
    if (imp == 'high' || imp == 1) {
      importance = NotificationImportance.high;
    } else if (imp == 'low' || imp == 2) {
      importance = NotificationImportance.low;
    } else if (imp == 'min' || imp == 3) {
      importance = NotificationImportance.min;
    }
  }

  if (imageUrl != null && imageUrl.isNotEmpty) {
    await master.showImageNotification(
      title: title,
      message: message,
      imageUrl: imageUrl,
      channelId: channelId,
      importance: importance,
    );
  } else if (bigText != null && bigText.isNotEmpty) {
    await master.showBigTextNotification(
      title: title,
      message: message,
      bigText: bigText,
      channelId: channelId,
      importance: importance,
    );
  } else {
    await master.showNotification(
      id: id,
      title: title,
      message: message,
      channelId: channelId,
      importance: importance,
    );
  }
}
