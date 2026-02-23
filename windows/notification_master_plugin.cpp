#include "notification_master_plugin.h"
#include "wintoastlib.h"

// This must be included before many other Windows headers.
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
#include <winhttp.h>
#include <windows.data.json.h>
#pragma comment(lib, "winhttp.lib")
#pragma comment(lib, "windowsapp.lib")

using namespace WinToastLib;

namespace notification_master_windows {

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

// static
void NotificationMasterWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "notification_master",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<NotificationMasterWindowsPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

NotificationMasterWindowsPlugin::NotificationMasterWindowsPlugin() 
    : notification_id_counter_(1), wintoast_initialized_(false), polling_active_(false) {}

NotificationMasterWindowsPlugin::~NotificationMasterWindowsPlugin() {
    StopPolling();
    if (wintoast_initialized_) {
        WinToast::instance()->clear();
    }
}

bool NotificationMasterWindowsPlugin::InitializeWinToast() {
    if (wintoast_initialized_) {
        return true;
    }

    if (!WinToast::isCompatible()) {
        return false;
    }

    // Configure WinToast
    WinToast::instance()->setAppName(L"Notification Master");
    const auto aumi = WinToast::configureAUMI(L"NotificationMaster", L"NotificationMaster", L"NotificationMaster", L"1.0.0");
    WinToast::instance()->setAppUserModelId(aumi);

    // Initialize WinToast
    WinToast::WinToastError error;
    if (!WinToast::instance()->initialize(&error)) {
        return false;
    }

    wintoast_initialized_ = true;
    return true;
}

std::wstring NotificationMasterWindowsPlugin::StringToWString(const std::string& str) {
    if (str.empty()) {
        return std::wstring();
    }
    int size_needed = MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), NULL, 0);
    std::wstring wstrTo(size_needed, 0);
    MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), &wstrTo[0], size_needed);
    return wstrTo;
}

std::string NotificationMasterWindowsPlugin::GetStringValue(const flutter::EncodableValue& value, const std::string& key, const std::string& defaultValue) {
    if (std::holds_alternative<flutter::EncodableMap>(value)) {
        const auto& map = std::get<flutter::EncodableMap>(value);
        auto it = map.find(flutter::EncodableValue(key));
        if (it != map.end() && std::holds_alternative<std::string>(it->second)) {
            return std::get<std::string>(it->second);
        }
    }
    return defaultValue;
}

int NotificationMasterWindowsPlugin::GetIntValue(const flutter::EncodableValue& value, const std::string& key, int defaultValue) {
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

bool NotificationMasterWindowsPlugin::GetBoolValue(const flutter::EncodableValue& value, const std::string& key, bool defaultValue) {
    if (std::holds_alternative<flutter::EncodableMap>(value)) {
        const auto& map = std::get<flutter::EncodableMap>(value);
        auto it = map.find(flutter::EncodableValue(key));
        if (it != map.end() && std::holds_alternative<bool>(it->second)) {
            return std::get<bool>(it->second);
        }
    }
    return defaultValue;
}

void NotificationMasterWindowsPlugin::ShowNotification(
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

void NotificationMasterWindowsPlugin::ShowBigTextNotification(
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

void NotificationMasterWindowsPlugin::ShowImageNotification(
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

void NotificationMasterWindowsPlugin::ShowNotificationWithActions(
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

void NotificationMasterWindowsPlugin::HandleMethodCall(
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
    
    // Stop existing polling if any
    StopPolling();
    
    // Start new polling
    {
      std::lock_guard<std::mutex> lock(polling_mutex_);
      polling_url_ = StringToWString(url);
      polling_interval_minutes_ = interval > 0 ? interval : 15;
      polling_active_ = true;
    }
    
    polling_thread_ = std::thread(&NotificationMasterWindowsPlugin::PollingThread, this);
    result->Success(flutter::EncodableValue(true));
  } else if (method_name == "stopNotificationPolling") {
    StopPolling();
    result->Success(flutter::EncodableValue(true));
  } else if (method_name == "startForegroundService") {
    // On Windows, foreground service is same as polling
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
    
    {
      std::lock_guard<std::mutex> lock(polling_mutex_);
      polling_url_ = StringToWString(url);
      polling_interval_minutes_ = interval > 0 ? interval : 15;
      polling_active_ = true;
    }
    
    polling_thread_ = std::thread(&NotificationMasterWindowsPlugin::PollingThread, this);
    result->Success(flutter::EncodableValue(true));
  } else if (method_name == "stopForegroundService") {
    StopPolling();
    result->Success(flutter::EncodableValue(true));
  } else if (method_name == "setFirebaseAsActiveService") {
    result->Success(flutter::EncodableValue(true));
  } else if (method_name == "getActiveNotificationService") {
    std::string service = polling_active_ ? "polling" : "none";
    result->Success(flutter::EncodableValue(service));
  } else {
    result->NotImplemented();
  }
}

void NotificationMasterWindowsPlugin::StopPolling() {
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

void NotificationMasterWindowsPlugin::PollingThread() {
    while (true) {
        {
            std::lock_guard<std::mutex> lock(polling_mutex_);
            if (!polling_active_) {
                break;
            }
        }
        
        try {
            std::wstring url;
            {
                std::lock_guard<std::mutex> lock(polling_mutex_);
                url = polling_url_;
            }
            
            std::wstring response = HttpGetRequest(url);
            if (!response.empty()) {
                // Convert wstring to string for JSON parsing
                int size_needed = WideCharToMultiByte(CP_UTF8, 0, &response[0], (int)response.size(), NULL, 0, NULL, NULL);
                std::string jsonResponse(size_needed, 0);
                WideCharToMultiByte(CP_UTF8, 0, &response[0], (int)response.size(), &jsonResponse[0], size_needed, NULL, NULL);
                
                ParseAndShowNotifications(jsonResponse);
            }
        } catch (...) {
            // Ignore errors and continue polling
        }
        
        // Sleep for the interval
        int interval;
        {
            std::lock_guard<std::mutex> lock(polling_mutex_);
            interval = polling_interval_minutes_;
        }
        
        for (int i = 0; i < interval * 60 && polling_active_; ++i) {
            std::this_thread::sleep_for(std::chrono::seconds(1));
        }
    }
}

std::wstring NotificationMasterWindowsPlugin::HttpGetRequest(const std::wstring& url) {
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

void NotificationMasterWindowsPlugin::ParseAndShowNotifications(const std::string& jsonResponse) {
    // Simple JSON parsing for notifications
    // Supports two formats:
    // 1. {"notifications": [{"title": "...", "message": "...", ...}]}
    // 2. {"success": true, "data": {"title": "...", "message": "...", ...}} (PHP server format)
    
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
                }
                
                pos = objEnd + 1;
            }
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
                }
            }
        }
    }
}

std::map<std::string, std::string> NotificationMasterWindowsPlugin::ParseNotificationObject(const std::string& objStr) {
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

void NotificationMasterWindowsPlugin::ShowNotificationFromJson(const std::map<std::string, std::string>& notificationData) {
    if (!InitializeWinToast()) {
        return;
    }
    
    std::string title = notificationData.count("title") ? notificationData.at("title") : "";
    std::string message = notificationData.count("message") ? notificationData.at("message") : "";
    
    if (title.empty() && message.empty()) {
        return;
    }
    
    WinToastTemplate templ(WinToastTemplate::Text02);
    
    if (!title.empty()) {
        templ.setTextField(StringToWString(title), WinToastTemplate::FirstLine);
    }
    
    std::string displayMessage = message;
    if (notificationData.count("bigText") && !notificationData.at("bigText").empty()) {
        displayMessage = notificationData.at("bigText");
        templ = WinToastTemplate(WinToastTemplate::Text03);
        templ.setTextField(StringToWString(title), WinToastTemplate::FirstLine);
        templ.setTextField(StringToWString(displayMessage), WinToastTemplate::SecondLine);
    } else if (!message.empty()) {
        templ.setTextField(StringToWString(message), WinToastTemplate::SecondLine);
    }
    
    // Add image if available
    if (notificationData.count("imageUrl") && !notificationData.at("imageUrl").empty()) {
        std::string imageUrl = notificationData.at("imageUrl");
        std::wstring imagePath = StringToWString(imageUrl);
        
        // Check if it's an HTTP/HTTPS URL - need to download it
        if (imageUrl.find("http://") == 0 || imageUrl.find("https://") == 0) {
            imagePath = DownloadImageToTempFile(imagePath);
            if (imagePath.empty()) {
                // If download fails, skip image but continue with notification
                // Don't return, just don't add image
            } else {
                // Download succeeded, use ImageAndText02 template with image
                templ = WinToastTemplate(WinToastTemplate::ImageAndText02);
                templ.setTextField(StringToWString(title), WinToastTemplate::FirstLine);
                templ.setTextField(StringToWString(displayMessage), WinToastTemplate::SecondLine);
                templ.setImagePath(imagePath);
            }
        } else {
            // Local file path - use ImageAndText02 template with image
            templ = WinToastTemplate(WinToastTemplate::ImageAndText02);
            templ.setTextField(StringToWString(title), WinToastTemplate::FirstLine);
            templ.setTextField(StringToWString(displayMessage), WinToastTemplate::SecondLine);
            templ.setImagePath(imagePath);
        }
    }
    
    auto handler = new WinToastHandler(
        notification_id_counter_++,
        [](int id) { /* Activated */ },
        []() { /* Dismissed */ },
        []() { /* Failed */ }
    );
    
    WinToast::WinToastError error;
    WinToast::instance()->showToast(templ, handler, &error);
}

std::wstring NotificationMasterWindowsPlugin::DownloadImageToTempFile(const std::wstring& imageUrl) {
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

}  // namespace notification_master_windows
