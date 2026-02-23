#ifndef FLUTTER_PLUGIN_NOTIFICATION_MASTER_WINDOWS_PLUGIN_H_
#define FLUTTER_PLUGIN_NOTIFICATION_MASTER_WINDOWS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include <map>
#include <string>
#include <thread>
#include <atomic>
#include <mutex>

namespace notification_master_windows {

class NotificationMasterWindowsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  NotificationMasterWindowsPlugin();

  virtual ~NotificationMasterWindowsPlugin();

  // Disallow copy and assign.
  NotificationMasterWindowsPlugin(const NotificationMasterWindowsPlugin&) = delete;
  NotificationMasterWindowsPlugin& operator=(const NotificationMasterWindowsPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:
  // Initialize WinToast if not already initialized
  bool InitializeWinToast();

  // Helper methods for notifications
  void ShowNotification(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void ShowBigTextNotification(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void ShowImageNotification(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void ShowNotificationWithActions(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Helper to convert std::string to std::wstring
  std::wstring StringToWString(const std::string& str);

  // Helper to get string from EncodableValue
  std::string GetStringValue(const flutter::EncodableValue& value, const std::string& key, const std::string& defaultValue = "");

  // Helper to get int from EncodableValue
  int GetIntValue(const flutter::EncodableValue& value, const std::string& key, int defaultValue = 0);

  // Helper to get bool from EncodableValue
  bool GetBoolValue(const flutter::EncodableValue& value, const std::string& key, bool defaultValue = false);

  // Notification ID counter
  int notification_id_counter_ = 1;
  bool wintoast_initialized_ = false;

  // Polling thread management
  void PollingThread();
  void StopPolling();
  std::wstring HttpGetRequest(const std::wstring& url);
  void ParseAndShowNotifications(const std::string& jsonResponse);
  void ShowNotificationFromJson(const std::map<std::string, std::string>& notificationData);
  std::map<std::string, std::string> ParseNotificationObject(const std::string& objStr);
  
  // Image download helper
  std::wstring DownloadImageToTempFile(const std::wstring& imageUrl);

  std::thread polling_thread_;
  std::atomic<bool> polling_active_{false};
  std::mutex polling_mutex_;
  std::wstring polling_url_;
  int polling_interval_minutes_ = 15;
};

}  // namespace notification_master_windows

#endif  // FLUTTER_PLUGIN_NOTIFICATION_MASTER_WINDOWS_PLUGIN_H_
