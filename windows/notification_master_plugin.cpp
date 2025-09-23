#include "notification_master_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Data.Xml.Dom.h>
#include <winrt/Windows.UI.Notifications.h>
#include <winrt/Windows.ApplicationModel.Background.h>
#include <winrt/Windows.Networking.BackgroundTransfer.h>
#include <winrt/Windows.Web.Http.h>
#include <winrt/Windows.Web.Http.Headers.h>
#include <winrt/Windows.Storage.Streams.h>
#include <winrt/Windows.System.Threading.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <string>
#include <map>
#include <vector>
#include <thread>
#include <chrono>
#include <future>
#include <iostream>

namespace notification_master {

// Static variables to keep track of notifications and services
static std::map<std::string, std::string> notificationChannels;
static bool isPollingServiceActive = false;
static bool isForegroundServiceActive = false;
static std::thread pollingThread;
static std::atomic<bool> stopPolling(false);

// Function to show a simple toast notification
void ShowToastNotification(const std::string& title, const std::string& message, const std::string& channelId = "") {
    try {
        std::cout << "[NotificationMaster] Attempting to show notification - Title: " << title << ", Message: " << message << ", Channel: " << channelId << std::endl;
        
        // Create the toast notification XML with actions and sound
        std::wstring xmlString = L"<toast activationType=\"foreground\" launch=\"action=viewConversation&amp;conversationId=9813\">";
        xmlString += L"<visual>";
        xmlString += L"<binding template=\"ToastGeneric\">";
        xmlString += L"<text>" + std::wstring(title.begin(), title.end()) + L"</text>";
        xmlString += L"<text>" + std::wstring(message.begin(), message.end()) + L"</text>";
        xmlString += L"</binding>";
        xmlString += L"</visual>";
        xmlString += L"<actions>";
        xmlString += L"<action content=\"Reply\" arguments=\"action=reply&amp;conversationId=9813\" activationType=\"foreground\"/>";
        xmlString += L"<action content=\"Like\" arguments=\"action=like&amp;conversationId=9813\" activationType=\"background\"/>";
        xmlString += L"</actions>";
        xmlString += L"<audio src=\"ms-winsoundevent:Notification.Default\" loop=\"false\"/>";
        xmlString += L"</toast>";

        std::wcout << L"[NotificationMaster] XML: " << xmlString << std::endl;

        // Create the toast notification
        winrt::Windows::Data::Xml::Dom::XmlDocument doc;
        doc.LoadXml(xmlString);
        
        winrt::Windows::UI::Notifications::ToastNotification toast{ doc };
        
        // Set expiration time (optional)
        auto expirationTime = winrt::Windows::Foundation::DateTime::clock::now() + std::chrono::minutes(5);
        toast.ExpirationTime(expirationTime);
        
        // Create a toast notifier with a specific app ID
        auto notifier = winrt::Windows::UI::Notifications::ToastNotificationManager::CreateToastNotifier(L"Microsoft.WindowsCalculator_8wekyb3d8bbwe!App");
        notifier.Show(toast);
        
        std::cout << "[NotificationMaster] Notification sent successfully with actions and sound!" << std::endl;
    }
    catch (const winrt::hresult_error& ex) {
        std::wcout << L"[NotificationMaster] WinRT exception occurred: " << ex.message().c_str() << L" (HRESULT: 0x" << std::hex << ex.code() << L")" << std::endl;
    }
    catch (const std::exception& e) {
        std::cout << "[NotificationMaster] Exception occurred: " << e.what() << std::endl;
    }
    catch (...) {
        std::cout << "[NotificationMaster] Unknown exception occurred while showing notification" << std::endl;
    }
}

// Function to show a big text notification
void ShowBigTextNotification(const std::string& title, const std::string& message, const std::string& bigText, const std::string& channelId = "") {
    try {
        // Create the toast notification XML with big text
        std::wstring xmlString = L"<toast><visual><binding template=\"ToastGeneric\">";
        xmlString += L"<text>" + std::wstring(title.begin(), title.end()) + L"</text>";
        xmlString += L"<text>" + std::wstring(message.begin(), message.end()) + L"</text>";
        xmlString += L"<text>" + std::wstring(bigText.begin(), bigText.end()) + L"</text>";
        xmlString += L"</binding></visual></toast>";

        // Create the toast notification
        winrt::Windows::Data::Xml::Dom::XmlDocument doc;
        doc.LoadXml(xmlString);
        
        winrt::Windows::UI::Notifications::ToastNotification toast{ doc };
        winrt::Windows::UI::Notifications::ToastNotificationManager::CreateToastNotifier().Show(toast);
    }
    catch (...) {
        // Handle any exceptions silently
        // Fallback to simple notification
        ShowToastNotification(title, message, channelId);
    }
}

// Function to create a notification channel (stub for Windows)
void CreateNotificationChannel(const std::string& channelId, const std::string& channelName, const std::string& channelDescription = "") {
    notificationChannels[channelId] = channelName;
}

// Function to start polling for notifications
void StartPollingService(const std::string& pollingUrl, int intervalMinutes) {
    if (isPollingServiceActive) return;
    
    isPollingServiceActive = true;
    stopPolling = false;
    
    // Start polling in a separate thread
    pollingThread = std::thread([pollingUrl, intervalMinutes]() {
        while (!stopPolling) {
            try {
                // In a real implementation, you would make an HTTP request to the pollingUrl
                // and parse the JSON response to show notifications
                // For now, we'll just simulate a notification
                
                // Sleep for the specified interval
                std::this_thread::sleep_for(std::chrono::minutes(intervalMinutes));
            }
            catch (...) {
                // Handle any exceptions
            }
        }
    });
}

// Function to stop polling service
void StopPollingService() {
    if (!isPollingServiceActive) return;
    
    stopPolling = true;
    if (pollingThread.joinable()) {
        pollingThread.join();
    }
    isPollingServiceActive = false;
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

NotificationMasterPlugin::NotificationMasterPlugin() {}

NotificationMasterPlugin::~NotificationMasterPlugin() {}

void NotificationMasterPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    
    if (method_call.method_name().compare("getPlatformVersion") == 0) {
        std::ostringstream version_stream;
        version_stream << "Windows ";
        
        // More future-proof version detection
        NTSTATUS (NTAPI *RtlGetVersion)(PRTL_OSVERSIONINFOW) = nullptr;
        HMODULE hNtDll = GetModuleHandleA("ntdll.dll");
        if (hNtDll) {
            RtlGetVersion = (NTSTATUS (NTAPI*)(PRTL_OSVERSIONINFOW))GetProcAddress(hNtDll, "RtlGetVersion");
        }
        
        if (RtlGetVersion) {
            RTL_OSVERSIONINFOW osInfo = {0};
            osInfo.dwOSVersionInfoSize = sizeof(osInfo);
            if (RtlGetVersion(&osInfo) == 0) {
                // Windows 11 starts from build 22000
                if (osInfo.dwBuildNumber >= 22000) {
                    version_stream << "11 (Build " << osInfo.dwBuildNumber << ")";
                } else if (osInfo.dwBuildNumber >= 10240) {
                    // Windows 10 starts from build 10240
                    version_stream << "10 (Build " << osInfo.dwBuildNumber << ")";
                } else if (osInfo.dwBuildNumber >= 9200) {
                    // Windows 8.1 = 9600, Windows 8 = 9200
                    version_stream << "8 (Build " << osInfo.dwBuildNumber << ")";
                } else if (osInfo.dwBuildNumber >= 7600) {
                    // Windows 7 starts from build 7600
                    version_stream << "7 (Build " << osInfo.dwBuildNumber << ")";
                } else {
                    version_stream << "Vista or earlier (Build " << osInfo.dwBuildNumber << ")";
                }
            } else {
                // Fallback to older method
                if (IsWindows10OrGreater()) {
                    version_stream << "10+";
                } else if (IsWindows8OrGreater()) {
                    version_stream << "8";
                } else if (IsWindows7OrGreater()) {
                    version_stream << "7";
                }
            }
        } else {
            // Fallback to older method
            if (IsWindows10OrGreater()) {
                version_stream << "10+";
            } else if (IsWindows8OrGreater()) {
                version_stream << "8";
            } else if (IsWindows7OrGreater()) {
                version_stream << "7";
            }
        }
        result->Success(flutter::EncodableValue(version_stream.str()));
    } else if (method_call.method_name().compare("requestNotificationPermission") == 0) {
        // Windows notifications don't require explicit permission in the same way as Android
        result->Success(flutter::EncodableValue(true));
    } else if (method_call.method_name().compare("checkNotificationPermission") == 0) {
        // Windows notifications are generally allowed by default
        result->Success(flutter::EncodableValue(true));
    } else if (method_call.method_name().compare("showNotification") == 0) {
        std::cout << "[NotificationMaster] showNotification method called" << std::endl;
        
        if (arguments) {
            std::cout << "[NotificationMaster] Arguments received, parsing..." << std::endl;
            
            auto title_it = arguments->find(flutter::EncodableValue("title"));
            auto message_it = arguments->find(flutter::EncodableValue("message"));
            auto id_it = arguments->find(flutter::EncodableValue("id"));
            
            if (title_it != arguments->end() && message_it != arguments->end()) {
                std::string title = std::get<std::string>(title_it->second);
                std::string message = std::get<std::string>(message_it->second);
                std::string channelId = "default";
                int notificationId = 1; // Default ID
                
                auto channel_it = arguments->find(flutter::EncodableValue("channelId"));
                if (channel_it != arguments->end()) {
                    channelId = std::get<std::string>(channel_it->second);
                }
                
                // Extract custom ID if provided
                if (id_it != arguments->end()) {
                    notificationId = std::get<int>(id_it->second);
                }
                
                std::cout << "[NotificationMaster] Parsed arguments - Title: " << title << ", Message: " << message << ", ChannelId: " << channelId << ", ID: " << notificationId << std::endl;
                
                ShowToastNotification(title, message, channelId);
                result->Success(flutter::EncodableValue(notificationId)); // Return the notification ID
                return;
            } else {
                std::cout << "[NotificationMaster] Missing title or message in arguments" << std::endl;
            }
        } else {
            std::cout << "[NotificationMaster] No arguments provided" << std::endl;
        }
        result->Error("INVALID_ARGUMENTS", "Invalid arguments for showNotification");
    } else if (method_call.method_name().compare("showBigTextNotification") == 0) {
        if (arguments) {
            auto title_it = arguments->find(flutter::EncodableValue("title"));
            auto message_it = arguments->find(flutter::EncodableValue("message"));
            auto bigText_it = arguments->find(flutter::EncodableValue("bigText"));
            
            if (title_it != arguments->end() && message_it != arguments->end() && bigText_it != arguments->end()) {
                std::string title = std::get<std::string>(title_it->second);
                std::string message = std::get<std::string>(message_it->second);
                std::string bigText = std::get<std::string>(bigText_it->second);
                std::string channelId = "default";
                
                auto channel_it = arguments->find(flutter::EncodableValue("channelId"));
                if (channel_it != arguments->end()) {
                    channelId = std::get<std::string>(channel_it->second);
                }
                
                ShowBigTextNotification(title, message, bigText, channelId);
                result->Success(flutter::EncodableValue(1)); // Return notification ID
                return;
            }
        }
        result->Error("INVALID_ARGUMENTS", "Invalid arguments for showBigTextNotification");
    } else if (method_call.method_name().compare("showImageNotification") == 0) {
        if (arguments) {
            auto title_it = arguments->find(flutter::EncodableValue("title"));
            auto message_it = arguments->find(flutter::EncodableValue("message"));
            auto imageUrl_it = arguments->find(flutter::EncodableValue("imageUrl"));
            
            if (title_it != arguments->end() && message_it != arguments->end() && imageUrl_it != arguments->end()) {
                std::string title = std::get<std::string>(title_it->second);
                std::string message = std::get<std::string>(message_it->second);
                std::string imageUrl = std::get<std::string>(imageUrl_it->second);
                std::string channelId = "default";
                
                auto channel_it = arguments->find(flutter::EncodableValue("channelId"));
                if (channel_it != arguments->end()) {
                    channelId = std::get<std::string>(channel_it->second);
                }
                
                // For simplicity, we'll show a regular notification with the image URL in the message
                std::string fullMessage = message + " Image: " + imageUrl;
                ShowToastNotification(title, fullMessage, channelId);
                result->Success(flutter::EncodableValue(1)); // Return notification ID
                return;
            }
        }
        result->Error("INVALID_ARGUMENTS", "Invalid arguments for showImageNotification");
    } else if (method_call.method_name().compare("showNotificationWithActions") == 0) {
        if (arguments) {
            auto title_it = arguments->find(flutter::EncodableValue("title"));
            auto message_it = arguments->find(flutter::EncodableValue("message"));
            
            if (title_it != arguments->end() && message_it != arguments->end()) {
                std::string title = std::get<std::string>(title_it->second);
                std::string message = std::get<std::string>(message_it->second);
                std::string channelId = "default";
                
                auto channel_it = arguments->find(flutter::EncodableValue("channelId"));
                if (channel_it != arguments->end()) {
                    channelId = std::get<std::string>(channel_it->second);
                }
                
                // For simplicity, we'll show a regular notification
                ShowToastNotification(title, message, channelId);
                result->Success(flutter::EncodableValue(1)); // Return notification ID
                return;
            }
        }
        result->Error("INVALID_ARGUMENTS", "Invalid arguments for showNotificationWithActions");
    } else if (method_call.method_name().compare("createCustomChannel") == 0) {
        if (arguments) {
            auto channelId_it = arguments->find(flutter::EncodableValue("channelId"));
            auto channelName_it = arguments->find(flutter::EncodableValue("channelName"));
            
            if (channelId_it != arguments->end() && channelName_it != arguments->end()) {
                std::string channelId = std::get<std::string>(channelId_it->second);
                std::string channelName = std::get<std::string>(channelName_it->second);
                std::string channelDescription = "";
                
                auto description_it = arguments->find(flutter::EncodableValue("channelDescription"));
                if (description_it != arguments->end()) {
                    channelDescription = std::get<std::string>(description_it->second);
                }
                
                CreateNotificationChannel(channelId, channelName, channelDescription);
                result->Success(flutter::EncodableValue(true));
                return;
            }
        }
        result->Error("INVALID_ARGUMENTS", "Invalid arguments for createCustomChannel");
    } else if (method_call.method_name().compare("startNotificationPolling") == 0) {
        if (arguments) {
            auto pollingUrl_it = arguments->find(flutter::EncodableValue("pollingUrl"));
            if (pollingUrl_it != arguments->end()) {
                std::string pollingUrl = std::get<std::string>(pollingUrl_it->second);
                int intervalMinutes = 15; // Default value
                
                auto interval_it = arguments->find(flutter::EncodableValue("intervalMinutes"));
                if (interval_it != arguments->end()) {
                    intervalMinutes = std::get<int32_t>(interval_it->second);
                }
                
                StartPollingService(pollingUrl, intervalMinutes);
                result->Success(flutter::EncodableValue(true));
                return;
            }
        }
        result->Error("INVALID_ARGUMENTS", "Invalid arguments for startNotificationPolling");
    } else if (method_call.method_name().compare("stopNotificationPolling") == 0) {
        StopPollingService();
        result->Success(flutter::EncodableValue(true));
    } else if (method_call.method_name().compare("startForegroundService") == 0) {
        // Windows doesn't have foreground services in the same way as Android
        // We'll treat this as starting the polling service
        if (arguments) {
            auto pollingUrl_it = arguments->find(flutter::EncodableValue("pollingUrl"));
            if (pollingUrl_it != arguments->end()) {
                std::string pollingUrl = std::get<std::string>(pollingUrl_it->second);
                int intervalMinutes = 15; // Default value
                
                auto interval_it = arguments->find(flutter::EncodableValue("intervalMinutes"));
                if (interval_it != arguments->end()) {
                    intervalMinutes = std::get<int32_t>(interval_it->second);
                }
                
                StartPollingService(pollingUrl, intervalMinutes);
                isForegroundServiceActive = true;
                result->Success(flutter::EncodableValue(true));
                return;
            }
        }
        result->Error("INVALID_ARGUMENTS", "Invalid arguments for startForegroundService");
    } else if (method_call.method_name().compare("stopForegroundService") == 0) {
        StopPollingService();
        isForegroundServiceActive = false;
        result->Success(flutter::EncodableValue(true));
    } else if (method_call.method_name().compare("setFirebaseAsActiveService") == 0) {
        // Not applicable on Windows
        result->Success(flutter::EncodableValue(false));
    } else if (method_call.method_name().compare("getActiveNotificationService") == 0) {
        if (isForegroundServiceActive) {
            result->Success(flutter::EncodableValue("foreground"));
        } else if (isPollingServiceActive) {
            result->Success(flutter::EncodableValue("polling"));
        } else {
            result->Success(flutter::EncodableValue("none"));
        }
    } else {
        result->NotImplemented();
    }
}

}  // namespace notification_master