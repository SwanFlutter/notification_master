#ifndef FLUTTER_PLUGIN_NOTIFICATION_MASTER_WINDOWS_PLUGIN_H_
#define FLUTTER_PLUGIN_NOTIFICATION_MASTER_WINDOWS_PLUGIN_H_

#ifndef NOMINMAX
#define NOMINMAX
#endif

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include <map>
#include <string>
#include <thread>
#include <atomic>
#include <mutex>
#include <algorithm>
#include <sstream>
#include <vector>

namespace notification_master {

class NotificationMasterPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  NotificationMasterPlugin();

  virtual ~NotificationMasterPlugin();

  // Disallow copy and assign.
  NotificationMasterPlugin(const NotificationMasterPlugin&) = delete;
  NotificationMasterPlugin& operator=(const NotificationMasterPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  static std::wstring StringToWString(const std::string& str);

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

  void ShowStyledNotification(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void ShowHeadsUpNotification(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void ShowFullScreenNotification(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Scheduled (background) notifications, delivered by the OS even when the
  // app is fully closed (uses WinRT ScheduledToastNotification with WinToast's
  // AppUserModelId — no external plugin required).
  void ScheduleNotification(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void CancelScheduledNotification(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void CancelAllScheduledNotifications(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void GetPendingScheduledNotifications(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Show a scheduled alarm-style toast via WinToast (used by the scheduler thread).
  void ShowAlarmToast(
      const std::string& title,
      const std::string& message,
      bool alarmSound);

  // Spawn a detached thread that waits until fireAtMillis and shows the alarm toast.
  void StartScheduledWinThread(
      int id,
      const std::string& title,
      const std::string& message,
      bool alarmSound,
      int64_t fireAtMillis,
      std::shared_ptr<std::atomic<bool>> cancel);

  // Re-arm persisted scheduled notifications after the app restarts.
  void ReArmScheduledWin();

  // Polling thread management
  void PollingThread();
  void StopPolling();
  std::wstring HttpGetRequest(const std::wstring& url);

  // Background poller daemon control (standalone exe that keeps polling even
  // after the app is closed). Configuration is persisted to the registry so the
  // daemon reads it independently of the Flutter app.
  bool StartBackgroundPollingService(const std::string& url, int intervalMinutes);
  void StopBackgroundPollingService();
  bool IsBackgroundPollingRunning();
  std::wstring GetHostExeDir();
  void ParseAndShowNotifications(const std::string& jsonResponse);
  void ShowNotificationFromJson(const std::map<std::string, std::string>& notificationData);
  std::map<std::string, std::string> ParseNotificationObject(const std::string& objStr);
  
  // Image download helper
  std::wstring DownloadImageToTempFile(const std::wstring& imageUrl);

  // Device token & topic management
  void GetDeviceToken(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void SubscribeToTopic(
      const std::string& topic,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void UnsubscribeFromTopic(
      const std::string& topic,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void GetSubscribedTopics(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Small helpers used across the native method handlers.
  std::string GetStringValue(const flutter::EncodableValue& value, const std::string& key, const std::string& defaultValue = "");
  int GetIntValue(const flutter::EncodableValue& value, const std::string& key, int defaultValue = 0);
  int64_t GetInt64Value(const flutter::EncodableValue& value, const std::string& key, int64_t defaultValue = 0);
  bool GetBoolValue(const flutter::EncodableValue& value, const std::string& key, bool defaultValue = false);

  std::thread polling_thread_;
  std::atomic<bool> polling_active_{false};
  std::mutex polling_mutex_;
  std::wstring polling_url_;
  int polling_interval_minutes_ = 15;

  // Internal WinToast state.
  int notification_id_counter_ = 1;
  bool wintoast_initialized_ = false;

  // Scheduled (background) notification tracking.
  //
  // Primary path: each schedule is handed to the OS as a WinRT
  // ScheduledToastNotification (IToastNotifier::AddToSchedule), so the Windows
  // notification platform delivers it at the scheduled time even when the app
  // is fully closed, and persists it across reboots — no in-process timer or
  // registry copy is kept for these.
  //
  // Fallback path (older Windows / OS scheduling unavailable): a detached
  // thread per item waits until the scheduled time and shows an alarm-style
  // toast; those items are persisted in the registry and re-armed on restart.
  //
  // scheduled_cancel_ maps id -> cancel flag for fallback timer threads and is
  // also used to report pending ids scheduled in the current session.
  std::mutex scheduled_win_mutex_;
  std::map<int, std::shared_ptr<std::atomic<bool>>> scheduled_cancel_;
};

}  // namespace notification_master

#endif  // FLUTTER_PLUGIN_NOTIFICATION_MASTER_WINDOWS_PLUGIN_H_
