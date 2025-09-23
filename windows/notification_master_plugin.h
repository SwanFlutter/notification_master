#ifndef FLUTTER_PLUGIN_NOTIFICATION_MASTER_PLUGIN_H_
#define FLUTTER_PLUGIN_NOTIFICATION_MASTER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

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
};

}  // namespace notification_master

#endif  // FLUTTER_PLUGIN_NOTIFICATION_MASTER_PLUGIN_H_
