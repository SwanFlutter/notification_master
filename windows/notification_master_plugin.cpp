#define _SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS

#include "notification_master_plugin.h"
#include "wintoastlib.h"
#include "nm_registry_config.h"

// This must be included before many other Windows headers.
#define NOMINMAX
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <codecvt>
#include <locale>
#include <functional>
#include <thread>
#include <chrono>
#include <atomic>
#include <mutex>
#include <set>
#include <vector>
#include <filesystem>
#include <winhttp.h>
#include <windows.data.json.h>
#include <tlhelp32.h>
#include <windows.data.json.h>

// WinRT ABI headers for OS-level scheduled toasts (ScheduledToastNotification /
// IToastNotifier::AddToSchedule). These let the OS deliver the toast at the
// scheduled time even when the app is fully closed â€” the Windows equivalent of
// Android's AlarmManager.
#include <windows.foundation.h>
#include <windows.ui.notifications.h>
#include <windows.data.xml.dom.h>
#include <wrl/client.h>
#include <wrl/wrappers/corewrappers.h>
#include <roapi.h>
#include <winstring.h>

#pragma comment(lib, "winhttp.lib")
#pragma comment(lib, "windowsapp.lib")
#pragma comment(lib, "runtimeobject.lib")

using namespace WinToastLib;

namespace notification_master {

// Forward declarations for registry helpers defined later in this file (used
// by the background poller control methods above their definition).
static std::wstring ReadRegistryString(const std::wstring& name);
static void WriteRegistryString(const std::wstring& name, const std::wstring& value);

// WinToast Handler class
class WinToastHandler : public IWinToastHandler {
public:
    WinToastHandler(int notificationId, std::function<void(int)> onActivated, 
                    std::function<void()> onDismissed, std::function<void()> onFailed)
        : notification_id_(notificationId), on_activated_(onActivated),
          on_dismissed_(onDismissed), on_failed_(onFailed) {}

    void toastActivated() const override {
        if (on_activated_) {
            on_activated_(notification_id_);
        }
    }

    void toastActivated(int actionIndex) const override {
        if (on_activated_) {
            on_activated_(notification_id_);
        }
    }

    void toastActivated(std::wstring response) const override {
        if (on_activated_) {
            on_activated_(notification_id_);
        }
    }

    void toastDismissed(WinToastDismissalReason state) const override {
        if (on_dismissed_) {
            on_dismissed_();
        }
    }

    void toastFailed() const override {
        if (on_failed_) {
            on_failed_();
        }
    }

private:
    int notification_id_;
    std::function<void(int)> on_activated_;
    std::function<void()> on_dismissed_;
    std::function<void()> on_failed_;
};

// â”€â”€ Simple file logger for debug builds â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
static void NMLog(const std::wstring& msg) {
  OutputDebugStringW((msg + L"\n").c_str());
  // Also write to a temp file so logs survive after the process exits.
  static std::wstring logPath = []() -> std::wstring {
    wchar_t tmp[MAX_PATH];
    GetTempPathW(MAX_PATH, tmp);
    return std::wstring(tmp) + L"notification_master_debug.log";
  }();
  FILE* f = nullptr;
  if (_wfopen_s(&f, logPath.c_str(), L"a, ccs=UTF-8") == 0 && f) {
    // Write timestamp + message
    SYSTEMTIME st;
    GetLocalTime(&st);
    fwprintf(f, L"[%02d:%02d:%02d.%03d] %s\n",
             st.wHour, st.wMinute, st.wSecond, st.wMilliseconds,
             msg.c_str());
    fclose(f);
  }
}

// static
void NotificationMasterPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "notification_master",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<NotificationMasterPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

NotificationMasterPlugin::NotificationMasterPlugin() 
    : notification_id_counter_(1), wintoast_initialized_(false), polling_active_(false) {
  ReArmScheduledWin();
}

NotificationMasterPlugin::~NotificationMasterPlugin() {
    StopPolling();
    if (wintoast_initialized_) {
        WinToast::instance()->clear();
    }
}

bool NotificationMasterPlugin::InitializeWinToast() {
    if (wintoast_initialized_) {
        return true;
    }

    if (!WinToast::isCompatible()) {
        NMLog(L"[NM] InitializeWinToast: WinToast not compatible with this OS");
        return false;
    }

    // Enable WinToast debug output so we see shell link messages in the log.
    WinToastLib::setDebugOutputEnabled(true);

    // Configure WinToast
    WinToast::instance()->setAppName(L"Notification Master");
    const auto aumi = WinToast::configureAUMI(L"NotificationMaster", L"NotificationMaster", L"NotificationMaster", L"1.0.0");
    WinToast::instance()->setAppUserModelId(aumi);
    NMLog(L"[NM] InitializeWinToast: AUMI = " + aumi + L"\n");

    // Try the default policy first (creates a Start Menu shortcut automatically).
    WinToast::WinToastError error;
    if (WinToast::instance()->initialize(&error)) {
        NMLog(L"[NM] InitializeWinToast: SUCCESS (default shortcut policy)");
        wintoast_initialized_ = true;
        return true;
    }

    OutputDebugStringW((L"[NM] InitializeWinToast: first attempt failed, error=" +
        std::to_wstring(static_cast<int>(error)) + L"\n").c_str());

    // Second attempt: suppress shortcut creation (useful during development /
    // flutter run where no installer has run yet).
    WinToast::instance()->setShortcutPolicy(WinToast::SHORTCUT_POLICY_IGNORE);
    if (WinToast::instance()->initialize(&error)) {
        NMLog(L"[NM] InitializeWinToast: SUCCESS (SHORTCUT_POLICY_IGNORE)");
        wintoast_initialized_ = true;
        return true;
    }

    OutputDebugStringW((L"[NM] InitializeWinToast: FAILED both attempts, error=" +
        std::to_wstring(static_cast<int>(error)) + L"\n").c_str());
    return false;
}

std::wstring NotificationMasterPlugin::StringToWString(const std::string& str) {
    if (str.empty()) {
        return std::wstring();
    }
    int size_needed = MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), NULL, 0);
    std::wstring wstrTo(size_needed, 0);
    MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), &wstrTo[0], size_needed);
    return wstrTo;
}

std::string NotificationMasterPlugin::GetStringValue(const flutter::EncodableValue& value, const std::string& key, const std::string& defaultValue) {
    if (std::holds_alternative<flutter::EncodableMap>(value)) {
        const auto& map = std::get<flutter::EncodableMap>(value);
        auto it = map.find(flutter::EncodableValue(key));
        if (it != map.end() && std::holds_alternative<std::string>(it->second)) {
            return std::get<std::string>(it->second);
        }
    }
    return defaultValue;
}

int NotificationMasterPlugin::GetIntValue(const flutter::EncodableValue& value, const std::string& key, int defaultValue) {
    if (std::holds_alternative<flutter::EncodableMap>(value)) {
        const auto& map = std::get<flutter::EncodableMap>(value);
        auto it = map.find(flutter::EncodableValue(key));
        if (it != map.end()) {
            if (std::holds_alternative<int32_t>(it->second)) {
                return std::get<int32_t>(it->second);
            } else if (std::holds_alternative<int64_t>(it->second)) {
                return static_cast<int>(std::get<int64_t>(it->second));
            }
        }
    }
    return defaultValue;
}

int64_t NotificationMasterPlugin::GetInt64Value(const flutter::EncodableValue& value, const std::string& key, int64_t defaultValue) {
    if (std::holds_alternative<flutter::EncodableMap>(value)) {
        const auto& map = std::get<flutter::EncodableMap>(value);
        auto it = map.find(flutter::EncodableValue(key));
        if (it != map.end()) {
            if (std::holds_alternative<int32_t>(it->second)) {
                return static_cast<int64_t>(std::get<int32_t>(it->second));
            } else if (std::holds_alternative<int64_t>(it->second)) {
                return std::get<int64_t>(it->second);
            }
        }
    }
    return defaultValue;
}

bool NotificationMasterPlugin::GetBoolValue(const flutter::EncodableValue& value, const std::string& key, bool defaultValue) {
    if (std::holds_alternative<flutter::EncodableMap>(value)) {
        const auto& map = std::get<flutter::EncodableMap>(value);
        auto it = map.find(flutter::EncodableValue(key));
        if (it != map.end() && std::holds_alternative<bool>(it->second)) {
            return std::get<bool>(it->second);
        }
    }
    return defaultValue;
}

void NotificationMasterPlugin::ShowNotification(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    
    if (!InitializeWinToast()) {
        result->Error("INIT_ERROR", "Failed to initialize WinToast");
        return;
    }

    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
        result->Error("INVALID_ARGUMENT", "Invalid arguments");
        return;
    }

    int notificationId = GetIntValue(flutter::EncodableValue(*arguments), "id", notification_id_counter_++);
    std::string title = GetStringValue(flutter::EncodableValue(*arguments), "title", "");
    std::string message = GetStringValue(flutter::EncodableValue(*arguments), "message", "");

    // At least title must be provided
    if (title.empty() && message.empty()) {
        result->Error("INVALID_ARGUMENT", "Title and message are required");
        return;
    }
    
    // If title is empty but message exists, use message as title
    if (title.empty() && !message.empty()) {
        title = message;
        message = "";
    }
    
    // If message is empty but title exists, use title as message
    if (message.empty() && !title.empty()) {
        message = title;
    }

    // Create WinToast template (Text02: bold title, regular message)
    WinToastTemplate templ(WinToastTemplate::Text02);
    templ.setTextField(StringToWString(title), WinToastTemplate::FirstLine);
    templ.setTextField(StringToWString(message), WinToastTemplate::SecondLine);

    // Create handler
    auto handler = new WinToastHandler(
        notificationId,
        [](int id) { /* Activated */ },
        []() { /* Dismissed */ },
        []() { /* Failed */ }
    );

    // Show toast
    WinToast::WinToastError error;
    INT64 toastId = WinToast::instance()->showToast(templ, handler, &error);
    
    if (toastId < 0) {
        result->Error("SHOW_ERROR", "Failed to show notification: " + std::to_string(error));
        delete handler;
        return;
    }

    result->Success(flutter::EncodableValue(notificationId));
}

void NotificationMasterPlugin::ShowBigTextNotification(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    
    if (!InitializeWinToast()) {
        result->Error("INIT_ERROR", "Failed to initialize WinToast");
        return;
    }

    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
        result->Error("INVALID_ARGUMENT", "Invalid arguments");
        return;
    }

    int notificationId = GetIntValue(flutter::EncodableValue(*arguments), "id", notification_id_counter_++);
    std::string title = GetStringValue(flutter::EncodableValue(*arguments), "title", "");
    std::string message = GetStringValue(flutter::EncodableValue(*arguments), "message", "");
    std::string bigText = GetStringValue(flutter::EncodableValue(*arguments), "bigText", message);

    // At least title must be provided
    if (title.empty() && message.empty()) {
        result->Error("INVALID_ARGUMENT", "Title and message are required");
        return;
    }
    
    // If title is empty but message exists, use message as title
    if (title.empty() && !message.empty()) {
        title = message;
        message = "";
    }
    
    // For big text notifications, message is required (bigText uses message as fallback)
    if (message.empty()) {
        message = title; // Use title as message if message is empty
    }

    // Use Text03 template for big text (title wraps two lines, big text on third)
    WinToastTemplate templ(WinToastTemplate::Text03);
    templ.setTextField(StringToWString(title), WinToastTemplate::FirstLine);
    templ.setTextField(StringToWString(bigText), WinToastTemplate::SecondLine);

    auto handler = new WinToastHandler(
        notificationId,
        [](int id) { /* Activated */ },
        []() { /* Dismissed */ },
        []() { /* Failed */ }
    );

    WinToast::WinToastError error;
    INT64 toastId = WinToast::instance()->showToast(templ, handler, &error);
    
    if (toastId < 0) {
        result->Error("SHOW_ERROR", "Failed to show notification: " + std::to_string(error));
        delete handler;
        return;
    }

    result->Success(flutter::EncodableValue(notificationId));
}

void NotificationMasterPlugin::ShowImageNotification(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    
    if (!InitializeWinToast()) {
        result->Error("INIT_ERROR", "Failed to initialize WinToast");
        return;
    }

    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
        result->Error("INVALID_ARGUMENT", "Invalid arguments");
        return;
    }

    int notificationId = GetIntValue(flutter::EncodableValue(*arguments), "id", notification_id_counter_++);
    std::string title = GetStringValue(flutter::EncodableValue(*arguments), "title", "");
    std::string message = GetStringValue(flutter::EncodableValue(*arguments), "message", "");
    std::string imageUrl = GetStringValue(flutter::EncodableValue(*arguments), "imageUrl", "");

    // At least title must be provided
    if (title.empty() && message.empty()) {
        result->Error("INVALID_ARGUMENT", "Title and message are required");
        return;
    }
    
    // If title is empty but message exists, use message as title
    if (title.empty() && !message.empty()) {
        title = message;
        message = "";
    }
    
    // If message is empty but title exists, use title as message
    if (message.empty() && !title.empty()) {
        message = title;
    }

    // Use ImageAndText02 template
    WinToastTemplate templ(WinToastTemplate::ImageAndText02);
    templ.setTextField(StringToWString(title), WinToastTemplate::FirstLine);
    templ.setTextField(StringToWString(message), WinToastTemplate::SecondLine);
    
    if (!imageUrl.empty()) {
        std::wstring imagePath = StringToWString(imageUrl);
        
        // Check if it's an HTTP/HTTPS URL - need to download it
        if (imageUrl.find("http://") == 0 || imageUrl.find("https://") == 0) {
            imagePath = DownloadImageToTempFile(imagePath);
            if (imagePath.empty()) {
                // If download fails, show notification without image (don't return error)
                // Just continue without image
            } else {
                templ.setImagePath(imagePath);
            }
        } else {
            // Local file path
            templ.setImagePath(imagePath);
        }
    }

    auto handler = new WinToastHandler(
        notificationId,
        [](int id) { /* Activated */ },
        []() { /* Dismissed */ },
        []() { /* Failed */ }
    );

    WinToast::WinToastError error;
    INT64 toastId = WinToast::instance()->showToast(templ, handler, &error);
    
    if (toastId < 0) {
        result->Error("SHOW_ERROR", "Failed to show notification: " + std::to_string(error));
        delete handler;
        return;
    }

    result->Success(flutter::EncodableValue(notificationId));
}

void NotificationMasterPlugin::ShowNotificationWithActions(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    
    if (!InitializeWinToast()) {
        result->Error("INIT_ERROR", "Failed to initialize WinToast");
        return;
    }

    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
        result->Error("INVALID_ARGUMENT", "Invalid arguments");
        return;
    }

    int notificationId = GetIntValue(flutter::EncodableValue(*arguments), "id", notification_id_counter_++);
    std::string title = GetStringValue(flutter::EncodableValue(*arguments), "title", "");
    std::string message = GetStringValue(flutter::EncodableValue(*arguments), "message", "");

    // At least title must be provided
    if (title.empty() && message.empty()) {
        result->Error("INVALID_ARGUMENT", "Title and message are required");
        return;
    }
    
    // If title is empty but message exists, use message as title
    if (title.empty() && !message.empty()) {
        title = message;
        message = "";
    }
    
    // If message is empty but title exists, use title as message
    if (message.empty() && !title.empty()) {
        message = title;
    }

    WinToastTemplate templ(WinToastTemplate::Text02);
    templ.setTextField(StringToWString(title), WinToastTemplate::FirstLine);
    templ.setTextField(StringToWString(message), WinToastTemplate::SecondLine);

    // Add actions
    auto actions_it = arguments->find(flutter::EncodableValue("actions"));
    if (actions_it != arguments->end() && std::holds_alternative<flutter::EncodableList>(actions_it->second)) {
        const auto& actions_list = std::get<flutter::EncodableList>(actions_it->second);
        for (const auto& action_value : actions_list) {
            if (std::holds_alternative<flutter::EncodableMap>(action_value)) {
                const auto& action_map = std::get<flutter::EncodableMap>(action_value);
                auto title_it = action_map.find(flutter::EncodableValue("title"));
                if (title_it != action_map.end() && std::holds_alternative<std::string>(title_it->second)) {
                    std::string action_title = std::get<std::string>(title_it->second);
                    templ.addAction(StringToWString(action_title));
                }
            }
        }
    }

    auto handler = new WinToastHandler(
        notificationId,
        [](int id) { /* Activated */ },
        []() { /* Dismissed */ },
        []() { /* Failed */ }
    );

    WinToast::WinToastError error;
    INT64 toastId = WinToast::instance()->showToast(templ, handler, &error);
    
    if (toastId < 0) {
        result->Error("SHOW_ERROR", "Failed to show notification: " + std::to_string(error));
        delete handler;
        return;
    }

    result->Success(flutter::EncodableValue(notificationId));
}

void NotificationMasterPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  const std::string& method_name = method_call.method_name();

  if (method_name == "getPlatformVersion") {
    std::ostringstream version_stream;
    version_stream << "Windows ";
    if (IsWindows10OrGreater()) {
      version_stream << "10+";
    } else if (IsWindows8OrGreater()) {
      version_stream << "8";
    } else if (IsWindows7OrGreater()) {
      version_stream << "7";
    }
    result->Success(flutter::EncodableValue(version_stream.str()));
  } else if (method_name == "requestNotificationPermission") {
    // Windows doesn't require explicit permission for toast notifications
    result->Success(flutter::EncodableValue(true));
  } else if (method_name == "checkNotificationPermission") {
    // Windows doesn't require explicit permission for toast notifications
    result->Success(flutter::EncodableValue(true));
  } else if (method_name == "showNotification") {
    ShowNotification(method_call, std::move(result));
  } else if (method_name == "showBigTextNotification") {
    ShowBigTextNotification(method_call, std::move(result));
  } else if (method_name == "showImageNotification") {
    ShowImageNotification(method_call, std::move(result));
  } else if (method_name == "showNotificationWithActions") {
    ShowNotificationWithActions(method_call, std::move(result));
  } else if (method_name == "createCustomChannel") {
    // Windows doesn't use channels like Android
    result->Success(flutter::EncodableValue(true));
  } else if (method_name == "startBackgroundPollingService") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGUMENT", "Invalid arguments");
      return;
    }
    std::string url = GetStringValue(flutter::EncodableValue(*arguments), "pollingUrl", "");
    int interval = GetIntValue(flutter::EncodableValue(*arguments), "intervalMinutes", 15);
    if (url.empty()) {
      result->Error("INVALID_ARGUMENT", "pollingUrl is required");
      return;
    }
    bool launched = StartBackgroundPollingService(url, interval);
    result->Success(flutter::EncodableValue(launched));
  } else if (method_name == "stopBackgroundPollingService") {
    StopBackgroundPollingService();
    result->Success(flutter::EncodableValue(true));
  } else if (method_name == "isBackgroundPollingRunning") {
    bool running = IsBackgroundPollingRunning();
    NMLog(L"[NM] isBackgroundPollingRunning=" + std::wstring(running ? L"true" : L"false"));
    result->Success(flutter::EncodableValue(running));
  } else if (method_name == "startNotificationPolling") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGUMENT", "Invalid arguments");
      return;
    }

    std::string url = GetStringValue(flutter::EncodableValue(*arguments), "pollingUrl", "");
    int interval = GetIntValue(flutter::EncodableValue(*arguments), "intervalMinutes", 15);

    if (url.empty()) {
      result->Error("INVALID_ARGUMENT", "pollingUrl is required");
      return;
    }

    // On Windows, an in-process thread dies when the app closes. To keep
    // receiving notifications AFTER the app is closed, delegate to the
    // standalone background poller daemon (its own process).
    StopPolling();
    bool launched = StartBackgroundPollingService(url, interval);
    result->Success(flutter::EncodableValue(launched));
  } else if (method_name == "stopNotificationPolling") {
    // Stop both the in-process thread (if any) and the background daemon.
    StopPolling();
    StopBackgroundPollingService();
    result->Success(flutter::EncodableValue(true));
  } else if (method_name == "startForegroundService") {
    // On Windows, foreground service == background poller daemon so that
    // notifications keep arriving even after the app is closed.
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGUMENT", "Invalid arguments");
      return;
    }

    std::string url = GetStringValue(flutter::EncodableValue(*arguments), "pollingUrl", "");
    int interval = GetIntValue(flutter::EncodableValue(*arguments), "intervalMinutes", 15);

    if (url.empty()) {
      result->Error("INVALID_ARGUMENT", "pollingUrl is required");
      return;
    }

    StopPolling();
    bool launched = StartBackgroundPollingService(url, interval);
    result->Success(flutter::EncodableValue(launched));
  } else if (method_name == "stopForegroundService") {
    StopPolling();
    StopBackgroundPollingService();
    result->Success(flutter::EncodableValue(true));
  } else if (method_name == "setFirebaseAsActiveService") {
    result->Success(flutter::EncodableValue(true));
  } else if (method_name == "getActiveNotificationService") {
    // Reflect the background daemon state so the UI stays in sync on Windows.
    std::string service = IsBackgroundPollingRunning() ? "polling" : (polling_active_ ? "polling" : "none");
    result->Success(flutter::EncodableValue(service));
  } else if (method_name == "showStyledNotification") {
    ShowStyledNotification(method_call, std::move(result));
  } else if (method_name == "showHeadsUpNotification") {
    ShowHeadsUpNotification(method_call, std::move(result));
  } else if (method_name == "showFullScreenNotification") {
    ShowFullScreenNotification(method_call, std::move(result));
  } else if (method_name == "getDeviceToken") {
    GetDeviceToken(std::move(result));
  } else if (method_name == "subscribeToTopic") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) { result->Error("INVALID_ARGUMENT", "Invalid arguments"); return; }
    std::string topic = GetStringValue(flutter::EncodableValue(*arguments), "topic", "");
    if (topic.empty()) { result->Error("INVALID_TOPIC", "topic is required"); return; }
    SubscribeToTopic(topic, std::move(result));
  } else if (method_name == "unsubscribeFromTopic") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) { result->Error("INVALID_ARGUMENT", "Invalid arguments"); return; }
    std::string topic = GetStringValue(flutter::EncodableValue(*arguments), "topic", "");
    if (topic.empty()) { result->Error("INVALID_TOPIC", "topic is required"); return; }
    UnsubscribeFromTopic(topic, std::move(result));
  } else if (method_name == "getSubscribedTopics") {
    GetSubscribedTopics(std::move(result));
  } else if (method_name == "scheduleNotification") {
    ScheduleNotification(method_call, std::move(result));
  } else if (method_name == "cancelScheduledNotification") {
    CancelScheduledNotification(method_call, std::move(result));
  } else if (method_name == "cancelAllScheduledNotifications") {
    CancelAllScheduledNotifications(std::move(result));
  } else if (method_name == "getPendingScheduledNotifications") {
    GetPendingScheduledNotifications(std::move(result));
  } else {
    result->NotImplemented();
  }
}

void NotificationMasterPlugin::StopPolling() {
    {
        std::lock_guard<std::mutex> lock(polling_mutex_);
        if (!polling_active_) {
            return;
        }
        polling_active_ = false;
    }
    
    if (polling_thread_.joinable()) {
        polling_thread_.join();
    }
}

// ── Background poller daemon control ───────────────────────────────────────
// The daemon executable is bundled next to this DLL's consumer (the app .exe).
// Because the plugin DLL is loaded by the app, the simplest robust way to find
// the daemon is to look next to the host process executable.

std::wstring NotificationMasterPlugin::GetHostExeDir() {
    wchar_t hostPath[MAX_PATH] = {0};
    // GetModuleFileNameW with NULL returns the host .exe that loaded us.
    if (GetModuleFileNameW(nullptr, hostPath, MAX_PATH) == 0) {
        return L"";
    }
    std::filesystem::path p(hostPath);
    return p.parent_path().wstring();
}

bool NotificationMasterPlugin::IsBackgroundPollingRunning() {
    std::wstring enabled = ReadRegistryString(L"bg_poll_enabled");
    if (enabled != L"1") return false;

    // Also verify the process is actually alive (it clears bg_poll_enabled on
    // clean exit, but a hard kill may leave a stale "1").
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snap == INVALID_HANDLE_VALUE) return true;  // assume running
    PROCESSENTRY32 pe = {sizeof(pe)};
    bool found = false;
    if (Process32First(snap, &pe)) {
        do {
            if (_wcsicmp(pe.szExeFile, L"notification_master_poller.exe") == 0) {
                found = true;
                break;
            }
        } while (Process32Next(snap, &pe));
    }
    CloseHandle(snap);
    if (!found) {
        WriteRegistryString(L"bg_poll_enabled", L"0");
        return false;
    }
    return true;
}

bool NotificationMasterPlugin::StartBackgroundPollingService(
    const std::string& url, int intervalMinutes) {
    NMLog(L"[NM] StartBackgroundPollingService: url=" + StringToWString(url) +
          L" interval=" + std::to_wstring(intervalMinutes));

    // Persist configuration so the daemon (and restarts) can read it.
    WriteRegistryString(L"bg_poll_url", StringToWString(url));
    WriteRegistryString(L"bg_poll_interval",
                          std::to_wstring(intervalMinutes > 0 ? intervalMinutes : 15));

    if (IsBackgroundPollingRunning()) {
        NMLog(L"[NM] StartBackgroundPollingService: already running");
        return true;
    }

    std::wstring dir = GetHostExeDir();
    if (dir.empty()) {
        NMLog(L"[NM] StartBackgroundPollingService: cannot resolve host dir");
        return false;
    }
    std::filesystem::path daemonPath =
        std::filesystem::path(dir) / L"notification_master_poller.exe";
    if (!std::filesystem::exists(daemonPath)) {
        NMLog(L"[NM] StartBackgroundPollingService: daemon NOT FOUND at " +
              daemonPath.wstring() +
              L"  >> build the daemon (notification_master_poller target) and ensure it is copied next to the .exe");
        return false;
    }
    NMLog(L"[NM] StartBackgroundPollingService: daemon found at " +
          daemonPath.wstring());

    // Launch detached, independent of the app's lifetime.
    STARTUPINFOW si = {sizeof(si)};
    PROCESS_INFORMATION pi = {0};
    std::wstring cmd = L"\"" + daemonPath.wstring() + L"\"";
    if (!CreateProcessW(daemonPath.c_str(), &cmd[0], nullptr, nullptr, FALSE,
                        CREATE_NEW_PROCESS_GROUP | DETACHED_PROCESS,
                        nullptr, dir.c_str(), &si, &pi)) {
        DWORD e = GetLastError();
        NMLog(L"[NM] StartBackgroundPollingService: CreateProcess failed err=" +
              std::to_wstring(e));
        return false;
    }
    if (pi.hProcess) CloseHandle(pi.hProcess);
    if (pi.hThread) CloseHandle(pi.hThread);
    NMLog(L"[NM] StartBackgroundPollingService: launched daemon from " +
          daemonPath.wstring());
    return true;
}

void NotificationMasterPlugin::StopBackgroundPollingService() {
    // Tell the daemon to shut down (it polls this key every couple of seconds).
    WriteRegistryString(L"bg_poll_enabled", L"0");

    // Best-effort: terminate any running instance by name.
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snap == INVALID_HANDLE_VALUE) return;
    PROCESSENTRY32 pe = {sizeof(pe)};
    if (Process32First(snap, &pe)) {
        do {
            if (_wcsicmp(pe.szExeFile, L"notification_master_poller.exe") == 0) {
                HANDLE h = OpenProcess(PROCESS_TERMINATE, FALSE, pe.th32ProcessID);
                if (h) {
                    TerminateProcess(h, 0);
                    CloseHandle(h);
                }
            }
        } while (Process32Next(snap, &pe));
    }
    CloseHandle(snap);
    NMLog(L"[NM] StopBackgroundPollingService: requested shutdown");
}

void NotificationMasterPlugin::PollingThread() {
    NMLog(L"[NM] PollingThread: started");
    // Poll immediately on first run, then wait for the interval.
    bool firstRun = true;
    int pollCount = 0;
    while (true) {
        {
            std::lock_guard<std::mutex> lock(polling_mutex_);
            if (!polling_active_) {
                NMLog(L"[NM] PollingThread: stopped (polling_active=false)");
                break;
            }
        }

        if (!firstRun) {
            // Wait for the configured interval (checking every second for stop).
            int interval;
            {
                std::lock_guard<std::mutex> lock(polling_mutex_);
                interval = polling_interval_minutes_;
            }
            NMLog(L"[NM] PollingThread: sleeping " + std::to_wstring(interval) + L" min");
            for (int i = 0; i < interval * 60; ++i) {
                {
                    std::lock_guard<std::mutex> lock(polling_mutex_);
                    if (!polling_active_) break;
                }
                std::this_thread::sleep_for(std::chrono::seconds(1));
            }
            // Re-check after sleep.
            {
                std::lock_guard<std::mutex> lock(polling_mutex_);
                if (!polling_active_) {
                    NMLog(L"[NM] PollingThread: stopped after sleep");
                    break;
                }
            }
        }
        firstRun = false;

        try {
            std::wstring url;
            {
                std::lock_guard<std::mutex> lock(polling_mutex_);
                url = polling_url_;
            }
            NMLog(L"[NM] PollingThread: polling " + url);
            std::wstring response = HttpGetRequest(url);
            if (response.empty()) {
                NMLog(L"[NM] PollingThread: empty response (network error or server down)");
            } else {
                ++pollCount;
                NMLog(L"[NM] PollingThread: poll #" + std::to_wstring(pollCount) +
                      L" got response len=" + std::to_wstring(response.size()));
                int size_needed = WideCharToMultiByte(CP_UTF8, 0, &response[0], (int)response.size(), NULL, 0, NULL, NULL);
                std::string jsonResponse(size_needed, 0);
                WideCharToMultiByte(CP_UTF8, 0, &response[0], (int)response.size(), &jsonResponse[0], size_needed, NULL, NULL);
                ParseAndShowNotifications(jsonResponse);
            }
        } catch (...) {
            NMLog(L"[NM] PollingThread: exception during poll");
        }
    }
    NMLog(L"[NM] PollingThread: exiting");
}

std::wstring NotificationMasterPlugin::HttpGetRequest(const std::wstring& url) {
    std::wstring result;
    
    // Parse URL
    URL_COMPONENTS urlComp;
    ZeroMemory(&urlComp, sizeof(urlComp));
    urlComp.dwStructSize = sizeof(urlComp);
    urlComp.dwSchemeLength = (DWORD)-1;
    urlComp.dwHostNameLength = (DWORD)-1;
    urlComp.dwUrlPathLength = (DWORD)-1;
    urlComp.dwExtraInfoLength = (DWORD)-1;
    
    wchar_t scheme[32] = {0};
    wchar_t hostName[256] = {0};
    wchar_t urlPath[1024] = {0};
    wchar_t extraInfo[256] = {0};
    
    urlComp.lpszScheme = scheme;
    urlComp.lpszHostName = hostName;
    urlComp.lpszUrlPath = urlPath;
    urlComp.lpszExtraInfo = extraInfo;
    
    if (!WinHttpCrackUrl(url.c_str(), (DWORD)url.length(), 0, &urlComp)) {
        return result;
    }
    
    // Connect to server
    HINTERNET hSession = WinHttpOpen(L"NotificationMaster/1.0", WINHTTP_ACCESS_TYPE_DEFAULT_PROXY, WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, 0);
    if (!hSession) {
        return result;
    }
    
    HINTERNET hConnect = WinHttpConnect(hSession, hostName, urlComp.nPort, 0);
    if (!hConnect) {
        WinHttpCloseHandle(hSession);
        return result;
    }
    
    // Create request
    std::wstring fullPath = std::wstring(urlPath) + std::wstring(extraInfo);
    HINTERNET hRequest = WinHttpOpenRequest(hConnect, L"GET", fullPath.c_str(), NULL, WINHTTP_NO_REFERER, WINHTTP_DEFAULT_ACCEPT_TYPES, 
                                            urlComp.nScheme == INTERNET_SCHEME_HTTPS ? WINHTTP_FLAG_SECURE : 0);
    if (!hRequest) {
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        return result;
    }
    
    // Send request
    if (!WinHttpSendRequest(hRequest, WINHTTP_NO_ADDITIONAL_HEADERS, 0, WINHTTP_NO_REQUEST_DATA, 0, 0, 0)) {
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        return result;
    }
    
    // Receive response
    if (!WinHttpReceiveResponse(hRequest, NULL)) {
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        return result;
    }
    
    // Read data
    DWORD bytesAvailable = 0;
    DWORD bytesRead = 0;
    std::vector<char> buffer;
    
    while (WinHttpQueryDataAvailable(hRequest, &bytesAvailable) && bytesAvailable > 0) {
        size_t currentSize = buffer.size();
        buffer.resize(currentSize + bytesAvailable);
        if (!WinHttpReadData(hRequest, &buffer[currentSize], bytesAvailable, &bytesRead)) {
            break;
        }
        if (bytesRead < bytesAvailable) {
            buffer.resize(currentSize + bytesRead);
        }
    }
    
    if (!buffer.empty()) {
        // Convert to wstring
        int size_needed = MultiByteToWideChar(CP_UTF8, 0, &buffer[0], (int)buffer.size(), NULL, 0);
        result.resize(size_needed);
        MultiByteToWideChar(CP_UTF8, 0, &buffer[0], (int)buffer.size(), &result[0], size_needed);
    }
    
    WinHttpCloseHandle(hRequest);
    WinHttpCloseHandle(hConnect);
    WinHttpCloseHandle(hSession);
    
    return result;
}

void NotificationMasterPlugin::ParseAndShowNotifications(const std::string& jsonResponse) {
    // Simple JSON parsing for notifications
    // Supports two formats:
    // 1. {"notifications": [{"title": "...", "message": "...", ...}]}
    // 2. {"success": true, "data": {"title": "...", "message": "...", ...}} (PHP server format)

    int shownCount = 0;

    // Try format 1: notifications array
    size_t notificationsPos = jsonResponse.find("\"notifications\"");
    if (notificationsPos != std::string::npos) {
        size_t arrayStart = jsonResponse.find('[', notificationsPos);
        if (arrayStart != std::string::npos) {
            size_t pos = arrayStart + 1;
            while (pos < jsonResponse.length()) {
                size_t objStart = jsonResponse.find('{', pos);
                if (objStart == std::string::npos) {
                    break;
                }
                
                size_t objEnd = jsonResponse.find('}', objStart);
                if (objEnd == std::string::npos) {
                    break;
                }
                
                std::string objStr = jsonResponse.substr(objStart, objEnd - objStart + 1);
                std::map<std::string, std::string> notificationData = ParseNotificationObject(objStr);
                
                if (!notificationData.empty()) {
                    ShowNotificationFromJson(notificationData);
                    ++shownCount;
                }
                
                pos = objEnd + 1;
            }
            NMLog(L"[NM] ParseAndShowNotifications: format=notifications, shown=" +
                  std::to_wstring(shownCount));
            return;
        }
    }
    
    // Try format 2: PHP server format with "data" object
    size_t dataPos = jsonResponse.find("\"data\"");
    if (dataPos != std::string::npos) {
        size_t objStart = jsonResponse.find('{', dataPos);
        if (objStart != std::string::npos) {
            // Find the matching closing brace (simple approach)
            int braceCount = 0;
            size_t objEnd = objStart;
            for (size_t i = objStart; i < jsonResponse.length(); ++i) {
                if (jsonResponse[i] == '{') {
                    braceCount++;
                } else if (jsonResponse[i] == '}') {
                    braceCount--;
                    if (braceCount == 0) {
                        objEnd = i;
                        break;
                    }
                }
            }
            
            if (objEnd > objStart) {
                std::string objStr = jsonResponse.substr(objStart, objEnd - objStart + 1);
                std::map<std::string, std::string> notificationData = ParseNotificationObject(objStr);
                
                // Also check for "big_text" (snake_case) in addition to "bigText" (camelCase)
                if (notificationData.find("bigText") == notificationData.end()) {
                    size_t bigTextPos = objStr.find("\"big_text\"");
                    if (bigTextPos != std::string::npos) {
                        size_t colonPos = objStr.find(':', bigTextPos);
                        size_t quoteStart = objStr.find('"', colonPos);
                        if (quoteStart != std::string::npos) {
                            size_t quoteEnd = objStr.find('"', quoteStart + 1);
                            if (quoteEnd != std::string::npos) {
                                notificationData["bigText"] = objStr.substr(quoteStart + 1, quoteEnd - quoteStart - 1);
                            }
                        }
                    }
                }
                
                if (!notificationData.empty()) {
                    ShowNotificationFromJson(notificationData);
                    ++shownCount;
                }
            }
        }
        NMLog(L"[NM] ParseAndShowNotifications: format=data, shown=" +
              std::to_wstring(shownCount));
    }
}

std::map<std::string, std::string> NotificationMasterPlugin::ParseNotificationObject(const std::string& objStr) {
    std::map<std::string, std::string> notificationData;
    
    // Extract title
    size_t titlePos = objStr.find("\"title\"");
    if (titlePos != std::string::npos) {
        size_t colonPos = objStr.find(':', titlePos);
        size_t quoteStart = objStr.find('"', colonPos);
        if (quoteStart != std::string::npos) {
            size_t quoteEnd = objStr.find('"', quoteStart + 1);
            if (quoteEnd != std::string::npos) {
                notificationData["title"] = objStr.substr(quoteStart + 1, quoteEnd - quoteStart - 1);
            }
        }
    }
    
    // Extract message
    size_t messagePos = objStr.find("\"message\"");
    if (messagePos != std::string::npos) {
        size_t colonPos = objStr.find(':', messagePos);
        size_t quoteStart = objStr.find('"', colonPos);
        if (quoteStart != std::string::npos) {
            size_t quoteEnd = objStr.find('"', quoteStart + 1);
            if (quoteEnd != std::string::npos) {
                notificationData["message"] = objStr.substr(quoteStart + 1, quoteEnd - quoteStart - 1);
            }
        }
    }
    
    // Extract bigText
    size_t bigTextPos = objStr.find("\"bigText\"");
    if (bigTextPos != std::string::npos) {
        size_t colonPos = objStr.find(':', bigTextPos);
        size_t quoteStart = objStr.find('"', colonPos);
        if (quoteStart != std::string::npos) {
            size_t quoteEnd = objStr.find('"', quoteStart + 1);
            if (quoteEnd != std::string::npos) {
                notificationData["bigText"] = objStr.substr(quoteStart + 1, quoteEnd - quoteStart - 1);
            }
        }
    }
    
    // Extract imageUrl
    size_t imageUrlPos = objStr.find("\"imageUrl\"");
    if (imageUrlPos != std::string::npos) {
        size_t colonPos = objStr.find(':', imageUrlPos);
        size_t quoteStart = objStr.find('"', colonPos);
        if (quoteStart != std::string::npos) {
            size_t quoteEnd = objStr.find('"', quoteStart + 1);
            if (quoteEnd != std::string::npos) {
                notificationData["imageUrl"] = objStr.substr(quoteStart + 1, quoteEnd - quoteStart - 1);
            }
        }
    }
    
    return notificationData;
}

void NotificationMasterPlugin::ShowNotificationFromJson(const std::map<std::string, std::string>& notificationData) {
    NMLog(L"[NM] ShowNotificationFromJson: entry");

    // WinToast must be initialized — the polling thread runs separate from the
    // Flutter UI thread so we always call InitializeWinToast() here.
    if (!InitializeWinToast()) {
        NMLog(L"[NM] ShowNotificationFromJson: WinToast init FAILED — toast dropped");
        return;
    }
    
    std::string title   = notificationData.count("title")   ? notificationData.at("title")   : "";
    std::string message = notificationData.count("message") ? notificationData.at("message") : "";
    std::string bigText = notificationData.count("bigText") ? notificationData.at("bigText") : "";

    NMLog(L"[NM] ShowNotificationFromJson: title='" + StringToWString(title) +
          L"' message='" + StringToWString(message) + L"' bigText='" +
          StringToWString(bigText) + L"'");

    if (title.empty() && message.empty()) {
        NMLog(L"[NM] ShowNotificationFromJson: both title and message empty — skipping");
        return;
    }

    // Ensure neither field is empty (WinToast may refuse an empty first line).
    if (title.empty())   title   = message;
    if (message.empty()) message = title;

    // Pick display body: prefer bigText if present.
    const std::string& displayBody = (!bigText.empty()) ? bigText : message;

    // Build template — always use Text02 (title + body) for reliability.
    WinToastTemplate templ(WinToastTemplate::Text02);
    templ.setTextField(StringToWString(title),       WinToastTemplate::FirstLine);
    templ.setTextField(StringToWString(displayBody), WinToastTemplate::SecondLine);

    // Add image if available.
    if (notificationData.count("imageUrl") && !notificationData.at("imageUrl").empty()) {
        std::string imageUrl = notificationData.at("imageUrl");
        std::wstring imagePath;
        if (imageUrl.find("http://") == 0 || imageUrl.find("https://") == 0) {
            imagePath = DownloadImageToTempFile(StringToWString(imageUrl));
        } else {
            imagePath = StringToWString(imageUrl);
        }
        if (!imagePath.empty()) {
            templ = WinToastTemplate(WinToastTemplate::ImageAndText02);
            templ.setTextField(StringToWString(title),       WinToastTemplate::FirstLine);
            templ.setTextField(StringToWString(displayBody), WinToastTemplate::SecondLine);
            templ.setImagePath(imagePath);
        }
    }

    auto handler = new WinToastHandler(
        notification_id_counter_++,
        [](int /*id*/) {},
        []() {},
        []() {}
    );

    WinToast::WinToastError error;
    INT64 toastId = WinToast::instance()->showToast(templ, handler, &error);
    if (toastId < 0) {
        NMLog(L"[NM] ShowNotificationFromJson: showToast FAILED error=" +
              std::to_wstring(static_cast<int>(error)));
        delete handler;
    } else {
        NMLog(L"[NM] ShowNotificationFromJson: showToast SUCCESS toastId=" +
              std::to_wstring(toastId));
    }
}

std::wstring NotificationMasterPlugin::DownloadImageToTempFile(const std::wstring& imageUrl) {
    std::wstring tempFilePath;
    
    // Get temp directory
    wchar_t tempPath[MAX_PATH];
    if (GetTempPathW(MAX_PATH, tempPath) == 0) {
        return tempFilePath;
    }
    
    // Create unique filename
    wchar_t tempFileName[MAX_PATH];
    if (GetTempFileNameW(tempPath, L"NM", 0, tempFileName) == 0) {
        return tempFilePath;
    }
    
    // Delete the file created by GetTempFileName (we'll create our own)
    DeleteFileW(tempFileName);
    
    // Add .jpg extension (we'll download as binary)
    std::wstring finalPath = std::wstring(tempFileName) + L".jpg";
    
    // Download image using WinHTTP
    HINTERNET hSession = WinHttpOpen(L"NotificationMaster/1.0", WINHTTP_ACCESS_TYPE_DEFAULT_PROXY, WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, 0);
    if (!hSession) {
        return tempFilePath;
    }
    
    // Parse URL
    URL_COMPONENTS urlComp;
    ZeroMemory(&urlComp, sizeof(urlComp));
    urlComp.dwStructSize = sizeof(urlComp);
    urlComp.dwSchemeLength = (DWORD)-1;
    urlComp.dwHostNameLength = (DWORD)-1;
    urlComp.dwUrlPathLength = (DWORD)-1;
    urlComp.dwExtraInfoLength = (DWORD)-1;
    
    wchar_t scheme[32] = {0};
    wchar_t hostName[256] = {0};
    wchar_t urlPath[1024] = {0};
    wchar_t extraInfo[256] = {0};
    
    urlComp.lpszScheme = scheme;
    urlComp.lpszHostName = hostName;
    urlComp.lpszUrlPath = urlPath;
    urlComp.lpszExtraInfo = extraInfo;
    
    if (!WinHttpCrackUrl(imageUrl.c_str(), (DWORD)imageUrl.length(), 0, &urlComp)) {
        WinHttpCloseHandle(hSession);
        return tempFilePath;
    }
    
    HINTERNET hConnect = WinHttpConnect(hSession, hostName, urlComp.nPort, 0);
    if (!hConnect) {
        WinHttpCloseHandle(hSession);
        return tempFilePath;
    }
    
    std::wstring fullPath = std::wstring(urlPath) + std::wstring(extraInfo);
    HINTERNET hRequest = WinHttpOpenRequest(hConnect, L"GET", fullPath.c_str(), NULL, WINHTTP_NO_REFERER, WINHTTP_DEFAULT_ACCEPT_TYPES,
                                            urlComp.nScheme == INTERNET_SCHEME_HTTPS ? WINHTTP_FLAG_SECURE : 0);
    if (!hRequest) {
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        return tempFilePath;
    }
    
    // Send request
    if (!WinHttpSendRequest(hRequest, WINHTTP_NO_ADDITIONAL_HEADERS, 0, WINHTTP_NO_REQUEST_DATA, 0, 0, 0)) {
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        return tempFilePath;
    }
    
    // Receive response
    if (!WinHttpReceiveResponse(hRequest, NULL)) {
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        return tempFilePath;
    }
    
    // Create file
    HANDLE hFile = CreateFileW(finalPath.c_str(), GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE) {
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        return tempFilePath;
    }
    
    // Read and write data
    DWORD bytesAvailable = 0;
    DWORD bytesRead = 0;
    char buffer[8192];
    
    while (WinHttpQueryDataAvailable(hRequest, &bytesAvailable) && bytesAvailable > 0) {
        if (bytesAvailable > sizeof(buffer)) {
            bytesAvailable = sizeof(buffer);
        }
        
        if (WinHttpReadData(hRequest, buffer, bytesAvailable, &bytesRead)) {
            DWORD bytesWritten = 0;
            WriteFile(hFile, buffer, bytesRead, &bytesWritten, NULL);
        } else {
            break;
        }
    }
    
    CloseHandle(hFile);
    WinHttpCloseHandle(hRequest);
    WinHttpCloseHandle(hConnect);
    WinHttpCloseHandle(hSession);
    
    // Check if file was created successfully
    if (GetFileAttributesW(finalPath.c_str()) != INVALID_FILE_ATTRIBUTES) {
        tempFilePath = finalPath;
    }
    
    return tempFilePath;
}

void NotificationMasterPlugin::ShowStyledNotification(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    
    if (!InitializeWinToast()) {
        result->Error("INIT_ERROR", "Failed to initialize WinToast");
        return;
    }

    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
        result->Error("INVALID_ARGUMENT", "Invalid arguments");
        return;
    }

    int notificationId = GetIntValue(flutter::EncodableValue(*arguments), "id", notification_id_counter_++);
    std::string title = GetStringValue(flutter::EncodableValue(*arguments), "title", "");
    std::string message = GetStringValue(flutter::EncodableValue(*arguments), "message", "");

    if (title.empty() && message.empty()) {
        result->Error("INVALID_ARGUMENT", "Title and message are required");
        return;
    }
    
    if (title.empty()) title = message;
    if (message.empty()) message = title;

    // Use Text04 for styled look (4 lines of text)
    WinToastTemplate templ(WinToastTemplate::Text04);
    templ.setTextField(StringToWString(title), WinToastTemplate::FirstLine);
    templ.setTextField(StringToWString(message), WinToastTemplate::SecondLine);
    templ.setAttributionText(L"Notification Master");
    
    // Add app icon or hero image if available
    templ.setDuration(WinToastTemplate::Long);
    templ.setAudioOption(WinToastTemplate::Default);

    auto handler = new WinToastHandler(
        notificationId,
        [](int id) { /* Activated */ },
        []() { /* Dismissed */ },
        []() { /* Failed */ }
    );

    WinToast::WinToastError error;
    INT64 toastId = WinToast::instance()->showToast(templ, handler, &error);
    
    if (toastId < 0) {
        result->Error("SHOW_ERROR", "Failed to show notification: " + std::to_string(error));
        delete handler;
        return;
    }

    result->Success(flutter::EncodableValue(notificationId));
}

void NotificationMasterPlugin::ShowHeadsUpNotification(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    
    if (!InitializeWinToast()) {
        result->Error("INIT_ERROR", "Failed to initialize WinToast");
        return;
    }

    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
        result->Error("INVALID_ARGUMENT", "Invalid arguments");
        return;
    }

    int notificationId = GetIntValue(flutter::EncodableValue(*arguments), "id", notification_id_counter_++);
    std::string title = GetStringValue(flutter::EncodableValue(*arguments), "title", "");
    std::string message = GetStringValue(flutter::EncodableValue(*arguments), "message", "");

    if (title.empty() && message.empty()) {
        result->Error("INVALID_ARGUMENT", "Title and message are required");
        return;
    }
    
    if (title.empty()) title = message;
    if (message.empty()) message = title;

    // Use Alarm scenario for heads-up effect
    WinToastTemplate templ(WinToastTemplate::Text02);
    templ.setTextField(StringToWString(title), WinToastTemplate::FirstLine);
    templ.setTextField(StringToWString(message), WinToastTemplate::SecondLine);
    templ.setScenario(WinToastTemplate::Scenario::Alarm);
    templ.setDuration(WinToastTemplate::Long);
    templ.setAudioPath(WinToastTemplate::AudioSystemFile::Alarm);
    templ.setAudioOption(WinToastTemplate::Loop);

    auto handler = new WinToastHandler(
        notificationId,
        [](int id) { /* Activated */ },
        []() { /* Dismissed */ },
        []() { /* Failed */ }
    );

    WinToast::WinToastError error;
    INT64 toastId = WinToast::instance()->showToast(templ, handler, &error);
    
    if (toastId < 0) {
        result->Error("SHOW_ERROR", "Failed to show notification: " + std::to_string(error));
        delete handler;
        return;
    }

    result->Success(flutter::EncodableValue(notificationId));
}

void NotificationMasterPlugin::ShowFullScreenNotification(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    
    if (!InitializeWinToast()) {
        result->Error("INIT_ERROR", "Failed to initialize WinToast");
        return;
    }

    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
        result->Error("INVALID_ARGUMENT", "Invalid arguments");
        return;
    }

    int notificationId = GetIntValue(flutter::EncodableValue(*arguments), "id", notification_id_counter_++);
    std::string title = GetStringValue(flutter::EncodableValue(*arguments), "title", "");
    std::string message = GetStringValue(flutter::EncodableValue(*arguments), "message", "");

    if (title.empty() && message.empty()) {
        result->Error("INVALID_ARGUMENT", "Title and message are required");
        return;
    }
    
    if (title.empty()) title = message;
    if (message.empty()) message = title;

    // Use IncomingCall scenario for full-screen effect
    WinToastTemplate templ(WinToastTemplate::Text02);
    templ.setTextField(StringToWString(title), WinToastTemplate::FirstLine);
    templ.setTextField(StringToWString(message), WinToastTemplate::SecondLine);
    templ.setScenario(WinToastTemplate::Scenario::IncomingCall);
    templ.setDuration(WinToastTemplate::Long);
    templ.setAudioPath(WinToastTemplate::AudioSystemFile::Call);
    templ.setAudioOption(WinToastTemplate::Loop);

    auto handler = new WinToastHandler(
        notificationId,
        [](int id) { /* Activated */ },
        []() { /* Dismissed */ },
        []() { /* Failed */ }
    );

    WinToast::WinToastError error;
    INT64 toastId = WinToast::instance()->showToast(templ, handler, &error);
    
    if (toastId < 0) {
        result->Error("SHOW_ERROR", "Failed to show notification: " + std::to_string(error));
        delete handler;
        return;
    }

    result->Success(flutter::EncodableValue(notificationId));
}

// â”€â”€ Registry key used for all plugin preferences â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
static const wchar_t* kRegistryPath =
    L"SOFTWARE\\NotificationMaster\\notification_master";

static std::wstring ReadRegistryString(const std::wstring& name) {
  HKEY hKey = nullptr;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, kRegistryPath, 0, KEY_READ, &hKey) != ERROR_SUCCESS)
    return L"";
  DWORD type = REG_SZ, size = 0;
  if (RegQueryValueExW(hKey, name.c_str(), nullptr, &type, nullptr, &size) != ERROR_SUCCESS ||
      type != REG_SZ || size == 0) {
    RegCloseKey(hKey);
    return L"";
  }
  std::wstring value(size / sizeof(wchar_t), L'\0');
  RegQueryValueExW(hKey, name.c_str(), nullptr, &type,
                   reinterpret_cast<LPBYTE>(&value[0]), &size);
  RegCloseKey(hKey);
  // Remove possible null terminator stored by RegSetValueEx
  if (!value.empty() && value.back() == L'\0') value.pop_back();
  return value;
}

static void WriteRegistryString(const std::wstring& name, const std::wstring& value) {
  HKEY hKey = nullptr;
  RegCreateKeyExW(HKEY_CURRENT_USER, kRegistryPath, 0, nullptr,
                  REG_OPTION_NON_VOLATILE, KEY_WRITE, nullptr, &hKey, nullptr);
  if (!hKey) return;
  RegSetValueExW(hKey, name.c_str(), 0, REG_SZ,
                 reinterpret_cast<const BYTE*>(value.c_str()),
                 static_cast<DWORD>((value.size() + 1) * sizeof(wchar_t)));
  RegCloseKey(hKey);
}

// Topics are stored as a semicolon-separated wstring: "news;offers;alerts"
static std::vector<std::wstring> ReadTopics() {
  std::wstring raw = ReadRegistryString(L"subscribed_topics");
  std::vector<std::wstring> topics;
  if (raw.empty()) return topics;
  std::wstringstream ss(raw);
  std::wstring token;
  while (std::getline(ss, token, L';')) {
    if (!token.empty()) topics.push_back(token);
  }
  return topics;
}

static void WriteTopics(const std::vector<std::wstring>& topics) {
  std::wstring joined;
  for (size_t i = 0; i < topics.size(); ++i) {
    if (i > 0) joined += L';';
    joined += topics[i];
  }
  WriteRegistryString(L"subscribed_topics", joined);
}

void NotificationMasterPlugin::GetDeviceToken(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

  auto showTokenConfirmation = [this](const std::string& token, const std::string& source) {
    if (InitializeWinToast()) {
      WinToastTemplate tmpl(WinToastTemplate::Text02);
      std::string preview = token.size() > 24 ? token.substr(0, 24) + "..." : token;
      std::string body = source + ": " + preview;
      tmpl.setTextField(L"Device Token (Windows)", WinToastTemplate::FirstLine);
      tmpl.setTextField(StringToWString(body), WinToastTemplate::SecondLine);
      WinToast::WinToastError err;
      WinToast::instance()->showToast(
        tmpl,
        new WinToastHandler(0, [](int){}, []{}, []{}),
        &err
      );
    }
  };

  // Check for a previously stored token
  std::wstring stored = ReadRegistryString(L"device_token");
  if (!stored.empty()) {
    int sz = WideCharToMultiByte(CP_UTF8, 0, stored.c_str(), -1, nullptr, 0, nullptr, nullptr);
    std::string token(sz - 1, '\0');
    WideCharToMultiByte(CP_UTF8, 0, stored.c_str(), -1, &token[0], sz, nullptr, nullptr);
    showTokenConfirmation(token, "Cached token");
    result->Success(flutter::EncodableValue(token));
    return;
  }

  // Generate a stable ID from the machine GUID stored in the Windows registry
  HKEY hKey = nullptr;
  std::wstring guid;
  if (RegOpenKeyExW(HKEY_LOCAL_MACHINE,
                    L"SOFTWARE\\Microsoft\\Cryptography",
                    0, KEY_READ | KEY_WOW64_64KEY, &hKey) == ERROR_SUCCESS) {
    DWORD type = REG_SZ, size = 0;
    RegQueryValueExW(hKey, L"MachineGuid", nullptr, &type, nullptr, &size);
    if (size > 0) {
      guid.resize(size / sizeof(wchar_t), L'\0');
      RegQueryValueExW(hKey, L"MachineGuid", nullptr, &type,
                       reinterpret_cast<LPBYTE>(&guid[0]), &size);
      if (!guid.empty() && guid.back() == L'\0') guid.pop_back();
    }
    RegCloseKey(hKey);
  }

  if (guid.empty()) {
    wchar_t name[MAX_COMPUTERNAME_LENGTH + 1] = {};
    DWORD len = MAX_COMPUTERNAME_LENGTH + 1;
    GetComputerNameW(name, &len);
    guid = name;
  }

  WriteRegistryString(L"device_token", guid);

  int sz = WideCharToMultiByte(CP_UTF8, 0, guid.c_str(), -1, nullptr, 0, nullptr, nullptr);
  std::string token(sz - 1, '\0');
  WideCharToMultiByte(CP_UTF8, 0, guid.c_str(), -1, &token[0], sz, nullptr, nullptr);
  showTokenConfirmation(token, "MachineGuid");
  result->Success(flutter::EncodableValue(token));
}

void NotificationMasterPlugin::SubscribeToTopic(
    const std::string& topic,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  std::wstring wTopic = StringToWString(topic);
  auto topics = ReadTopics();
  if (std::find(topics.begin(), topics.end(), wTopic) == topics.end()) {
    topics.push_back(wTopic);
    WriteTopics(topics);
  }
  // Local confirmation notification
  if (InitializeWinToast()) {
    WinToastTemplate tmpl(WinToastTemplate::Text02);
    tmpl.setTextField(L"Subscribed", WinToastTemplate::FirstLine);
    tmpl.setTextField(StringToWString("You are now subscribed to topic: " + topic),
                      WinToastTemplate::SecondLine);
    WinToast::WinToastError err;
    WinToast::instance()->showToast(
      tmpl,
      new WinToastHandler(0, [](int){}, []{}, []{}),
      &err
    );
  }
  result->Success(flutter::EncodableValue(true));
}

void NotificationMasterPlugin::UnsubscribeFromTopic(
    const std::string& topic,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  std::wstring wTopic = StringToWString(topic);
  auto topics = ReadTopics();
  topics.erase(std::remove(topics.begin(), topics.end(), wTopic), topics.end());
  WriteTopics(topics);
  // Local confirmation notification
  if (InitializeWinToast()) {
    WinToastTemplate tmpl(WinToastTemplate::Text02);
    tmpl.setTextField(L"Unsubscribed", WinToastTemplate::FirstLine);
    tmpl.setTextField(StringToWString("You have unsubscribed from topic: " + topic),
                      WinToastTemplate::SecondLine);
    WinToast::WinToastError err;
    WinToast::instance()->showToast(
      tmpl,
      new WinToastHandler(0, [](int){}, []{}, []{}),
      &err
    );
  }
  result->Success(flutter::EncodableValue(true));
}

void NotificationMasterPlugin::GetSubscribedTopics(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  auto wTopics = ReadTopics();
  flutter::EncodableList list;
  for (const auto& wt : wTopics) {
    int size = WideCharToMultiByte(CP_UTF8, 0, wt.c_str(), -1, nullptr, 0, nullptr, nullptr);
    std::string t(size - 1, '\0');
    WideCharToMultiByte(CP_UTF8, 0, wt.c_str(), -1, &t[0], size, nullptr, nullptr);
    list.push_back(flutter::EncodableValue(t));
  }
  result->Success(flutter::EncodableValue(list));
}

// â”€â”€ Scheduled (background) notifications â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

namespace {

// A single persisted scheduled notification.
struct ScheduledWinItem {
  int id = 0;
  int64_t fire_at_millis = 0;
  bool alarm_sound = false;
  std::string title;
  std::string message;
};

// â”€â”€ WinRT OS-level scheduling (ScheduledToastNotification) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//
// Unlike a thread that sleeps in-process, a ScheduledToastNotification is handed
// to the Windows notification platform, which delivers it at the scheduled time
// even if the app is fully closed (and survives reboots). This is the correct
// Windows counterpart to Android's AlarmManager.
//
// We use the same low-level WRL/ABI style as the bundled WinToast library so
// there are no header-macro conflicts. The toast is scheduled under the same
// AppUserModelId (AUMI) that WinToast registers, so the Start-menu shortcut
// WinToast creates is what makes the toast displayable.

namespace WRL = Microsoft::WRL;
namespace ABI_XML = ABI::Windows::Data::Xml::Dom;
namespace ABI_NOT = ABI::Windows::UI::Notifications;
namespace ABI_FND = ABI::Windows::Foundation;

// Tag prefix embedded in each scheduled toast so we can find/cancel them later
// via the notifier's schedule list (which persists across app restarts).
const wchar_t* kSchedTagPrefix = L"nm_sched_";

std::wstring EscapeXml(const std::wstring& in) {
  std::wstring out;
  out.reserve(in.size());
  for (wchar_t c : in) {
    switch (c) {
      case L'&':  out += L"&amp;"; break;
      case L'<':  out += L"&lt;"; break;
      case L'>':  out += L"&gt;"; break;
      case L'"':  out += L"&quot;"; break;
      case L'\'': out += L"&apos;"; break;
      default:    out += c; break;
    }
  }
  return out;
}

// Build the toast XML for a scheduled alarm. Kept deliberately simple (a
// ToastGeneric binding with two text lines plus optional looping alarm audio +
// alarm scenario) to avoid depending on WinToast's private XML builders.
std::wstring BuildScheduledToastXml(const std::wstring& title,
                                    const std::wstring& message,
                                    bool alarmSound,
                                    const std::wstring& tag) {
  std::wstring xml = L"<toast";
  if (alarmSound) {
    xml += L" scenario=\"alarm\"";
  }
  xml += L" launch=\"" + EscapeXml(tag) + L"\" duration=\"long\">";
  xml += L"<visual><binding template=\"ToastGeneric\">";
  xml += L"<text>" + EscapeXml(title) + L"</text>";
  xml += L"<text>" + EscapeXml(message) + L"</text>";
  xml += L"</binding></visual>";
  if (alarmSound) {
    xml += L"<audio src=\"ms-winsoundevent:Notification.Looping.Alarm\" loop=\"true\"/>";
  }
  xml += L"</toast>";
  return xml;
}

// Obtain the IToastNotifier for the given AUMI via the notification manager.
HRESULT GetToastNotifier(const std::wstring& aumi,
                         WRL::ComPtr<ABI_NOT::IToastNotifier>* outNotifier) {
  WRL::ComPtr<ABI_NOT::IToastNotificationManagerStatics> manager;
  HRESULT hr = RoGetActivationFactory(
      WRL::Wrappers::HStringReference(
          RuntimeClass_Windows_UI_Notifications_ToastNotificationManager)
          .Get(),
      IID_PPV_ARGS(&manager));
  if (FAILED(hr)) return hr;
  return manager->CreateToastNotifierWithId(
      WRL::Wrappers::HStringReference(aumi.c_str(),
                                      static_cast<UINT32>(aumi.length()))
          .Get(),
      outNotifier->GetAddressOf());
}

// Schedule a toast with the OS. Returns true on success. `fireAtMillis` is a
// Unix-epoch millisecond timestamp; it is converted to a Windows FILETIME-based
// DateTime (100ns ticks since 1601-01-01).
bool ScheduleOsToast(const std::wstring& aumi,
                     int id,
                     const std::wstring& title,
                     const std::wstring& message,
                     bool alarmSound,
                     int64_t fireAtMillis) {
  const std::wstring tag = kSchedTagPrefix + std::to_wstring(id);
  OutputDebugStringW((L"[NM] ScheduleOsToast: id=" + std::to_wstring(id) +
      L" tag=" + tag + L" fireAtMillis=" + std::to_wstring(fireAtMillis) + L"\n").c_str());

  // Build the XML document.
  WRL::ComPtr<IInspectable> xmlInspectable;
  HRESULT hr = RoActivateInstance(
      WRL::Wrappers::HStringReference(
          RuntimeClass_Windows_Data_Xml_Dom_XmlDocument)
          .Get(),
      &xmlInspectable);
  if (FAILED(hr)) {
    OutputDebugStringW((L"[NM] ScheduleOsToast: RoActivateInstance(XmlDocument) FAILED hr=0x" +
        [hr]() { wchar_t buf[20]; swprintf_s(buf, L"%08X", (unsigned)hr); return std::wstring(buf); }() + L"\n").c_str());
    return false;
  }

  WRL::ComPtr<ABI_XML::IXmlDocument> xmlDoc;
  hr = xmlInspectable.As(&xmlDoc);
  if (FAILED(hr)) {
    NMLog(L"[NM] ScheduleOsToast: .As(IXmlDocument) FAILED");
    return false;
  }

  WRL::ComPtr<ABI_XML::IXmlDocumentIO> xmlDocIO;
  hr = xmlDoc.As(&xmlDocIO);
  if (FAILED(hr)) {
    NMLog(L"[NM] ScheduleOsToast: .As(IXmlDocumentIO) FAILED");
    return false;
  }

  const std::wstring xml =
      BuildScheduledToastXml(title, message, alarmSound, tag);
  NMLog(L"[NM] ScheduleOsToast: XML=" + xml + L"\n");

  hr = xmlDocIO->LoadXml(
      WRL::Wrappers::HStringReference(xml.c_str(),
                                      static_cast<UINT32>(xml.length()))
          .Get());
  if (FAILED(hr)) {
    OutputDebugStringW((L"[NM] ScheduleOsToast: LoadXml FAILED hr=0x" +
        [hr]() { wchar_t buf[20]; swprintf_s(buf, L"%08X", (unsigned)hr); return std::wstring(buf); }() + L"\n").c_str());
    return false;
  }

  // Convert epoch millis â†’ Windows DateTime (100ns ticks since 1601-01-01).
  // Delta between 1601-01-01 and 1970-01-01 is 11644473600 seconds.
  ABI_FND::DateTime dt;
  dt.UniversalTime =
      (fireAtMillis + 11644473600000LL) * 10000LL;
  OutputDebugStringW((L"[NM] ScheduleOsToast: UniversalTime=" + std::to_wstring(dt.UniversalTime) + L"\n").c_str());

  // Create the ScheduledToastNotification via its factory.
  WRL::ComPtr<ABI_NOT::IScheduledToastNotificationFactory> factory;
  hr = RoGetActivationFactory(
      WRL::Wrappers::HStringReference(
          RuntimeClass_Windows_UI_Notifications_ScheduledToastNotification)
          .Get(),
      IID_PPV_ARGS(&factory));
  if (FAILED(hr)) {
    OutputDebugStringW((L"[NM] ScheduleOsToast: RoGetActivationFactory(ScheduledToastNotification) FAILED hr=0x" +
        [hr]() { wchar_t buf[20]; swprintf_s(buf, L"%08X", (unsigned)hr); return std::wstring(buf); }() + L"\n").c_str());
    return false;
  }

  WRL::ComPtr<ABI_NOT::IScheduledToastNotification> scheduled;
  hr = factory->CreateScheduledToastNotification(xmlDoc.Get(), dt, &scheduled);
  if (FAILED(hr)) {
    OutputDebugStringW((L"[NM] ScheduleOsToast: CreateScheduledToastNotification FAILED hr=0x" +
        [hr]() { wchar_t buf[20]; swprintf_s(buf, L"%08X", (unsigned)hr); return std::wstring(buf); }() + L"\n").c_str());
    return false;
  }

    // Tag it so we can cancel it later (put_Id is on IScheduledToastNotification).
  // Log the result but do NOT return on failure â€” AddToSchedule can still work.
  hr = scheduled->put_Id(
      WRL::Wrappers::HStringReference(tag.c_str(),
                                      static_cast<UINT32>(tag.length())).Get());
  if (FAILED(hr)) {
    NMLog(L"[NM] ScheduleOsToast: put_Id FAILED hr=" + std::to_wstring(hr) + L" (continuing without tag)");
  } else {
    NMLog(L"[NM] ScheduleOsToast: put_Id SUCCESS tag=" + tag);
  }
  WRL::ComPtr<ABI_NOT::IToastNotifier> notifier;
  hr = GetToastNotifier(aumi, &notifier);
  if (FAILED(hr)) {
    OutputDebugStringW((L"[NM] ScheduleOsToast: GetToastNotifier FAILED hr=0x" +
        [hr]() { wchar_t buf[20]; swprintf_s(buf, L"%08X", (unsigned)hr); return std::wstring(buf); }() + L"\n").c_str());
    return false;
  }

  hr = notifier->AddToSchedule(scheduled.Get());
  if (SUCCEEDED(hr)) {
    NMLog(L"[NM] ScheduleOsToast: AddToSchedule SUCCESS, tag=" + tag + L"\n");
  } else {
    OutputDebugStringW((L"[NM] ScheduleOsToast: AddToSchedule FAILED hr=0x" +
        [hr]() { wchar_t buf[20]; swprintf_s(buf, L"%08X", (unsigned)hr); return std::wstring(buf); }() + L"\n").c_str());
  }
  return SUCCEEDED(hr);
}

// Remove a previously scheduled OS toast by id (matches the tag we stored).
// If id < 0, removes every toast this plugin scheduled.
void CancelOsToast(const std::wstring& aumi, int id) {
  WRL::ComPtr<ABI_NOT::IToastNotifier> notifier;
  if (FAILED(GetToastNotifier(aumi, &notifier))) return;

  // AddToSchedule / RemoveFromSchedule / GetScheduledToastNotifications all
  // live on the base IToastNotifier interface.
  WRL::ComPtr<
      ABI_FND::Collections::IVectorView<ABI_NOT::ScheduledToastNotification*>>
      scheduledList;
  if (FAILED(notifier->GetScheduledToastNotifications(&scheduledList))) return;

  UINT32 count = 0;
  if (FAILED(scheduledList->get_Size(&count))) return;

  const std::wstring target = kSchedTagPrefix + std::to_wstring(id);
  for (UINT32 i = 0; i < count; ++i) {
    WRL::ComPtr<ABI_NOT::IScheduledToastNotification> item;
    if (FAILED(scheduledList->GetAt(i, &item))) continue;
    HSTRING hId = nullptr;
    if (FAILED(item->get_Id(&hId))) continue;
    UINT32 len = 0;
    const wchar_t* raw = WindowsGetStringRawBuffer(hId, &len);
    std::wstring itemId(raw ? raw : L"", len);
    WindowsDeleteString(hId);

    const bool matches =
        (id < 0) ? (itemId.rfind(kSchedTagPrefix, 0) == 0)
                 : (itemId == target);
    if (matches) {
      notifier->RemoveFromSchedule(item.Get());
    }
  }
}

// Return the ids of every toast this plugin currently has in the OS schedule.
// The ids are parsed back out of the "nm_sched_<id>" tags.
std::vector<int> GetOsScheduledIds(const std::wstring& aumi) {
  std::vector<int> out;
  WRL::ComPtr<ABI_NOT::IToastNotifier> notifier;
  if (FAILED(GetToastNotifier(aumi, &notifier))) return out;

  WRL::ComPtr<
      ABI_FND::Collections::IVectorView<ABI_NOT::ScheduledToastNotification*>>
      scheduledList;
  if (FAILED(notifier->GetScheduledToastNotifications(&scheduledList))) return out;

  UINT32 count = 0;
  if (FAILED(scheduledList->get_Size(&count))) return out;

  const std::wstring prefix = kSchedTagPrefix;
  for (UINT32 i = 0; i < count; ++i) {
    WRL::ComPtr<ABI_NOT::IScheduledToastNotification> item;
    if (FAILED(scheduledList->GetAt(i, &item))) continue;
    HSTRING hId = nullptr;
    if (FAILED(item->get_Id(&hId))) continue;
    UINT32 len = 0;
    const wchar_t* raw = WindowsGetStringRawBuffer(hId, &len);
    std::wstring itemId(raw ? raw : L"", len);
    WindowsDeleteString(hId);

    if (itemId.rfind(prefix, 0) == 0) {
      try {
        out.push_back(std::stoi(itemId.substr(prefix.length())));
      } catch (...) {
        // Ignore malformed tags.
      }
    }
  }
  return out;
}

std::wstring ScheduledRegName(int id) {
  return L"sched_" + std::to_wstring(id);
}

std::string WStringToString(const std::wstring& w) {
  if (w.empty()) return std::string();
  int size = WideCharToMultiByte(CP_UTF8, 0, w.c_str(), -1, nullptr, 0, nullptr, nullptr);
  std::string out(size - 1, '\0');
  WideCharToMultiByte(CP_UTF8, 0, w.c_str(), -1, &out[0], size, nullptr, nullptr);
  return out;
}

// Persist a single scheduled item under the plugin registry key.
void SaveScheduledWinItem(const ScheduledWinItem& item) {
  std::wstring value = std::to_wstring(item.fire_at_millis) + L"\t" +
      (item.alarm_sound ? L"1" : L"0") + L"\t" +
      NotificationMasterPlugin::StringToWString(item.title) + L"\t" + NotificationMasterPlugin::StringToWString(item.message);
  WriteRegistryString(ScheduledRegName(item.id), value);
}

void RemoveScheduledWinItem(int id) {
  HKEY hKey = nullptr;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, kRegistryPath, 0, KEY_SET_VALUE, &hKey) == ERROR_SUCCESS) {
    RegDeleteValueW(hKey, ScheduledRegName(id).c_str());
    RegCloseKey(hKey);
  }
}

// Load every persisted scheduled item from the registry.
std::vector<ScheduledWinItem> LoadAllScheduledWin() {
  std::vector<ScheduledWinItem> items;
  HKEY hKey = nullptr;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, kRegistryPath, 0, KEY_READ, &hKey) != ERROR_SUCCESS) {
    return items;
  }
  DWORD index = 0;
  wchar_t name[256];
  DWORD nameSize = 256;
  while (RegEnumValueW(hKey, index, name, &nameSize, nullptr, nullptr, nullptr, nullptr) == ERROR_SUCCESS) {
    std::wstring wname(name);
    if (wname.rfind(L"sched_", 0) == 0) {
      DWORD type = REG_SZ, size = 0;
      if (RegQueryValueExW(hKey, name, nullptr, &type, nullptr, &size) == ERROR_SUCCESS &&
          type == REG_SZ && size > 0) {
        std::wstring value(size / sizeof(wchar_t), L'\0');
        RegQueryValueExW(hKey, name, nullptr, &type,
                         reinterpret_cast<LPBYTE>(&value[0]), &size);
        if (!value.empty() && value.back() == L'\0') value.pop_back();
        // Format: epochMillis \t alarm(0|1) \t title \t message
        std::vector<std::wstring> parts;
        std::wstring cur;
        for (wchar_t c : value) {
          if (c == L'\t') { parts.push_back(cur); cur.clear(); }
          else cur += c;
        }
        parts.push_back(cur);
        if (parts.size() >= 4) {
          ScheduledWinItem it;
          it.id = std::stoi(wname.substr(6));
          it.fire_at_millis = std::stoll(std::wstring(parts[0].begin(), parts[0].end()));
          it.alarm_sound = (parts[1] == L"1");
          it.title = WStringToString(parts[2]);
          it.message = WStringToString(parts[3]);
          items.push_back(it);
        }
      }
    }
    nameSize = 256;
    ++index;
  }
  RegCloseKey(hKey);
  return items;
}
}  // namespace

void NotificationMasterPlugin::ScheduleNotification(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
  if (!arguments) {
    result->Error("INVALID_ARGUMENT", "Invalid arguments");
    return;
  }

  int id = GetIntValue(flutter::EncodableValue(*arguments), "id", 0);
  std::string title = GetStringValue(flutter::EncodableValue(*arguments), "title", "");
  std::string message = GetStringValue(flutter::EncodableValue(*arguments), "message", "");
  int64_t scheduledEpochMillis =
      GetInt64Value(flutter::EncodableValue(*arguments), "scheduledEpochMillis", 0);
  bool alarmSound = GetBoolValue(flutter::EncodableValue(*arguments), "alarmSound", false);

  if (title.empty() && message.empty()) {
    result->Error("INVALID_ARGUMENT", "Title and message are required");
    return;
  }
  if (title.empty()) title = message;
  if (message.empty()) message = title;
  if (scheduledEpochMillis <= 0) {
    result->Error("INVALID_ARGUMENT", "scheduledEpochMillis must be a positive epoch value");
    return;
  }

  // Ensure WinToast's Start Menu shortcut (and thus the AppUserModelId) is
  // registered, otherwise the scheduled toast will not be displayed.
  bool winToastReady = InitializeWinToast();
  OutputDebugStringW((L"[NM] ScheduleNotification: id=" + std::to_wstring(id) +
      L" epochMillis=" + std::to_wstring(scheduledEpochMillis) +
      L" winToastReady=" + (winToastReady ? L"true" : L"false") + L"\n").c_str());

  // Preferred path: hand the toast to the OS via ScheduledToastNotification.
  // The Windows notification platform then delivers it at the scheduled time
  // even if the app is fully closed, and persists it across reboots.
  bool osScheduled = false;
  if (winToastReady) {
    const std::wstring aumi = WinToast::instance()->appUserModelId();
    NMLog(L"[NM] ScheduleNotification: aumi='" + aumi + L"'");
    if (!aumi.empty()) {
      NMLog(L"[NM] ScheduleNotification: calling ScheduleOsToast (OS-level, works when app closed)");
      osScheduled = ScheduleOsToast(
          aumi, id, StringToWString(title), StringToWString(message),
          alarmSound, scheduledEpochMillis);
      NMLog(L"[NM] ScheduleNotification: ScheduleOsToast returned " +
            std::wstring(osScheduled ? L"true" : L"false"));
    } else {
      NMLog(L"[NM] ScheduleNotification: aumi is EMPTY -> OS schedule skipped. "
            L"WinToast shortcut likely missing; toast will not fire when app closed.");
    }
  } else {
    NMLog(L"[NM] ScheduleNotification: winToastReady=false -> cannot use OS schedule; "
          L"falling back to in-process timer (only fires while app runs).");
  }

  if (osScheduled) {
    NMLog(L"[NM] ScheduleNotification: OS-level scheduling SUCCESS");
    // Track the id in-memory so getPendingScheduledNotifications works this
    // session.
    std::lock_guard<std::mutex> lock(scheduled_win_mutex_);
    scheduled_cancel_[id] = std::make_shared<std::atomic<bool>>(false);
    result->Success(flutter::EncodableValue(true));
    return;
  }

  // Fallback: in-process timer thread that fires while the app is running,
  // persisted to the registry so overdue items fire on the next launch.
  NMLog(L"[NM] ScheduleNotification: using fallback thread timer");
  auto cancel = std::make_shared<std::atomic<bool>>(false);
  {
    std::lock_guard<std::mutex> lock(scheduled_win_mutex_);
    // Cancel any existing alarm with the same id before replacing it.
    auto existing = scheduled_cancel_.find(id);
    if (existing != scheduled_cancel_.end()) {
      existing->second->store(true);
    }
    scheduled_cancel_[id] = cancel;
  }

  ScheduledWinItem item;
  item.id = id;
  item.fire_at_millis = scheduledEpochMillis;
  item.alarm_sound = alarmSound;
  item.title = title;
  item.message = message;
  SaveScheduledWinItem(item);

  StartScheduledWinThread(id, title, message, alarmSound, scheduledEpochMillis, cancel);
  result->Success(flutter::EncodableValue(true));
}

void NotificationMasterPlugin::CancelScheduledNotification(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
  if (!arguments) {
    result->Error("INVALID_ARGUMENT", "Invalid arguments");
    return;
  }
  int id = GetIntValue(flutter::EncodableValue(*arguments), "id", 0);

  // Remove the OS-scheduled toast (if any).
  InitializeWinToast();
  CancelOsToast(WinToast::instance()->appUserModelId(), id);

  {
    std::lock_guard<std::mutex> lock(scheduled_win_mutex_);
    auto it = scheduled_cancel_.find(id);
    if (it != scheduled_cancel_.end()) {
      it->second->store(true);  // stop the fallback timer thread, if used
      scheduled_cancel_.erase(it);
    }
  }
  RemoveScheduledWinItem(id);
  result->Success(flutter::EncodableValue(true));
}

void NotificationMasterPlugin::CancelAllScheduledNotifications(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  // Remove every OS-scheduled toast this plugin created (id < 0 = match all).
  InitializeWinToast();
  CancelOsToast(WinToast::instance()->appUserModelId(), -1);

  std::vector<int> ids;
  {
    std::lock_guard<std::mutex> lock(scheduled_win_mutex_);
    for (auto& kv : scheduled_cancel_) {
      kv.second->store(true);  // stop any fallback timer threads
      ids.push_back(kv.first);
    }
    scheduled_cancel_.clear();
  }
  for (int id : ids) {
    RemoveScheduledWinItem(id);
  }
  result->Success(flutter::EncodableValue(true));
}

void NotificationMasterPlugin::GetPendingScheduledNotifications(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  // Report ids the OS still holds in its schedule. This is authoritative even
  // after the app has been restarted (the in-memory map would be empty then).
  std::set<int> uniqueIds;
  InitializeWinToast();
  for (int id : GetOsScheduledIds(WinToast::instance()->appUserModelId())) {
    uniqueIds.insert(id);
  }
  {
    std::lock_guard<std::mutex> lock(scheduled_win_mutex_);
    for (auto& kv : scheduled_cancel_) {
      uniqueIds.insert(kv.first);
    }
  }

  flutter::EncodableList ids;
  for (int id : uniqueIds) {
    ids.push_back(flutter::EncodableValue(id));
  }
  result->Success(flutter::EncodableValue(ids));
}

void NotificationMasterPlugin::ShowAlarmToast(
    const std::string& title,
    const std::string& message,
    bool alarmSound) {
  // COM must be initialized on each background thread.
  HRESULT hrCo = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  NMLog(L"[NM] ShowAlarmToast: FIRED title='" + StringToWString(title) + L"'");

  const std::string t = title.empty() ? message : title;
  const std::string m = message.empty() ? title : message;

  // Use the same AUMI that WinToast configures - hardcoded so this thread
  // does not need WinToast to be initialized.
  const std::wstring aumi = WinToast::configureAUMI(
      L"NotificationMaster", L"NotificationMaster",
      L"NotificationMaster", L"1.0.0");
  NMLog(L"[NM] ShowAlarmToast: AUMI=" + aumi);

  namespace WRL = Microsoft::WRL;
  namespace ABI_XML = ABI::Windows::Data::Xml::Dom;
  namespace ABI_NOT = ABI::Windows::UI::Notifications;

  // Build XML.
  const std::wstring wTitle   = StringToWString(t);
  const std::wstring wMessage = StringToWString(m);
  std::wstring xml = L"<toast";
  if (alarmSound) xml += L" scenario=\"alarm\"";
  xml += L" duration=\"long\"><visual><binding template=\"ToastGeneric\">";
  xml += L"<text>" + EscapeXml(wTitle)   + L"</text>";
  xml += L"<text>" + EscapeXml(wMessage) + L"</text>";
  xml += L"</binding></visual>";
  if (alarmSound) {
    xml += L"<audio src=\"ms-winsoundevent:Notification.Looping.Alarm\" loop=\"true\"/>";
  }
  xml += L"</toast>";

  bool shown = false;

  // Load XML document.
  WRL::ComPtr<IInspectable> xmlInsp;
  HRESULT hr = RoActivateInstance(
      WRL::Wrappers::HStringReference(
          RuntimeClass_Windows_Data_Xml_Dom_XmlDocument).Get(), &xmlInsp);
  if (FAILED(hr)) {
    NMLog(L"[NM] ShowAlarmToast: RoActivateInstance(XmlDocument) FAILED hr=" + std::to_wstring(hr));
    goto done;
  }
  {
    WRL::ComPtr<ABI_XML::IXmlDocument>   xmlDoc;
    WRL::ComPtr<ABI_XML::IXmlDocumentIO> xmlDocIO;
    if (FAILED(xmlInsp.As(&xmlDoc)) || FAILED(xmlInsp.As(&xmlDocIO))) {
      NMLog(L"[NM] ShowAlarmToast: QI IXmlDocument/IO FAILED");
      goto done;
    }
    hr = xmlDocIO->LoadXml(
        WRL::Wrappers::HStringReference(xml.c_str(),
            static_cast<UINT32>(xml.length())).Get());
    if (FAILED(hr)) {
      NMLog(L"[NM] ShowAlarmToast: LoadXml FAILED hr=" + std::to_wstring(hr));
      goto done;
    }

    // Create toast notification.
    WRL::ComPtr<ABI_NOT::IToastNotificationFactory> toastFactory;
    hr = RoGetActivationFactory(
        WRL::Wrappers::HStringReference(
            RuntimeClass_Windows_UI_Notifications_ToastNotification).Get(),
        IID_PPV_ARGS(&toastFactory));
    if (FAILED(hr)) {
      NMLog(L"[NM] ShowAlarmToast: RoGetActivationFactory(ToastNotification) FAILED hr=" + std::to_wstring(hr));
      goto done;
    }
    WRL::ComPtr<ABI_NOT::IToastNotification> toast;
    hr = toastFactory->CreateToastNotification(xmlDoc.Get(), &toast);
    if (FAILED(hr)) {
      NMLog(L"[NM] ShowAlarmToast: CreateToastNotification FAILED hr=" + std::to_wstring(hr));
      goto done;
    }

    // Get IToastNotifier.
    WRL::ComPtr<ABI_NOT::IToastNotificationManagerStatics> manager;
    hr = RoGetActivationFactory(
        WRL::Wrappers::HStringReference(
            RuntimeClass_Windows_UI_Notifications_ToastNotificationManager).Get(),
        IID_PPV_ARGS(&manager));
    if (FAILED(hr)) {
      NMLog(L"[NM] ShowAlarmToast: RoGetActivationFactory(Manager) FAILED hr=" + std::to_wstring(hr));
      goto done;
    }

    // Try with explicit AUMI first (requires Start Menu shortcut).
    WRL::ComPtr<ABI_NOT::IToastNotifier> notifier;
    hr = manager->CreateToastNotifierWithId(
        WRL::Wrappers::HStringReference(
            aumi.c_str(), static_cast<UINT32>(aumi.length())).Get(),
        notifier.GetAddressOf());
    if (FAILED(hr)) {
      NMLog(L"[NM] ShowAlarmToast: CreateToastNotifierWithId FAILED hr=" +
            std::to_wstring(hr) + L" retrying with default notifier");
      hr = manager->CreateToastNotifier(notifier.GetAddressOf());
    }
    if (FAILED(hr) || !notifier) {
      NMLog(L"[NM] ShowAlarmToast: both notifier attempts FAILED hr=" + std::to_wstring(hr));
      goto done;
    }

    hr = notifier->Show(toast.Get());
    shown = SUCCEEDED(hr);
    NMLog(std::wstring(L"[NM] ShowAlarmToast: Show ") +
          (shown ? L"SUCCESS" : (L"FAILED hr=" + std::to_wstring(hr))));
  }

done:
  if (!shown) {
    NMLog(L"[NM] ShowAlarmToast: WinRT path failed - trying WinToast on this thread");
    // Reset flag so InitializeWinToast retries on this thread.
    wintoast_initialized_ = false;
    if (InitializeWinToast()) {
      WinToastTemplate templ(WinToastTemplate::Text02);
      templ.setTextField(StringToWString(t), WinToastTemplate::FirstLine);
      templ.setTextField(StringToWString(m), WinToastTemplate::SecondLine);
      templ.setScenario(WinToastTemplate::Scenario::Alarm);
      templ.setDuration(WinToastTemplate::Long);
      if (alarmSound) {
        templ.setAudioPath(WinToastTemplate::AudioSystemFile::Alarm);
        templ.setAudioOption(WinToastTemplate::Loop);
      }
      auto handler = new WinToastHandler(0, [](int){}, [](){}, [](){});
      WinToast::WinToastError err;
      INT64 tid = WinToast::instance()->showToast(templ, handler, &err);
      NMLog(L"[NM] ShowAlarmToast: WinToast id=" + std::to_wstring(tid) +
            L" err=" + std::to_wstring(static_cast<int>(err)));
    } else {
      NMLog(L"[NM] ShowAlarmToast: WinToast fallback also FAILED");
    }
  }

  if (SUCCEEDED(hrCo)) CoUninitialize();
}

void NotificationMasterPlugin::StartScheduledWinThread(
    int id,
    const std::string& title,
    const std::string& message,
    bool alarmSound,
    int64_t fireAtMillis,
    std::shared_ptr<std::atomic<bool>> cancel) {
  std::thread(
      [this, id, title, message, alarmSound, fireAtMillis, cancel]() {
        auto fire = std::chrono::system_clock::time_point(
            std::chrono::milliseconds(fireAtMillis));
        while (!cancel->load()) {
          auto now = std::chrono::system_clock::now();
          if (now >= fire) break;
          auto remaining =
              std::chrono::duration_cast<std::chrono::milliseconds>(fire - now);
          auto chunk = (std::min)(remaining, std::chrono::milliseconds(500));
          std::this_thread::sleep_for(chunk);
        }
        if (!cancel->load()) {
          ShowAlarmToast(title, message, alarmSound);
        }
        {
          std::lock_guard<std::mutex> lock(scheduled_win_mutex_);
          scheduled_cancel_.erase(id);
        }
        RemoveScheduledWinItem(id);
      })
      .detach();
}

void NotificationMasterPlugin::ReArmScheduledWin() {
  auto items = LoadAllScheduledWin();
  for (const auto& item : items) {
    auto cancel = std::make_shared<std::atomic<bool>>(false);
    {
      std::lock_guard<std::mutex> lock(scheduled_win_mutex_);
      scheduled_cancel_[item.id] = cancel;
    }
    StartScheduledWinThread(item.id, item.title, item.message,
                            item.alarm_sound, item.fire_at_millis, cancel);
  }
}

}  // namespace notification_master

