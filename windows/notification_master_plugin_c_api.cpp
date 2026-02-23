#include "include/notification_master/notification_master_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "notification_master_plugin.h"

void NotificationMasterPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  notification_master_windows::NotificationMasterWindowsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
