/// Stub for web/WASM — dart:io not available.
class NotificationMasterDesktop {
  static Future<void> initialize({required String appName}) async {}

  static Future<void> showNotification({
    required String title,
    required String body,
    String? subtitle,
    bool silent = false,
    void Function()? onShow,
    void Function()? onClick,
    void Function(String)? onClose,
  }) async {}

  static Future<void> showNotificationWithActions({
    required String title,
    required String body,
    String? subtitle,
    required List<String> actions,
    bool silent = false,
    void Function(int)? onActionClick,
    void Function()? onClick,
  }) async {}

  static bool isSupported() => false;
  static bool isInitialized() => false;
}
