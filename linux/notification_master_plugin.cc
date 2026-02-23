#include "include/notification_master/notification_master_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>
#include <json-glib/json-glib.h>
#include <libsoup/soup.h>
#include <libnotify/notify.h>

#include <cstring>
#include <thread>
#include <chrono>
#include <atomic>
#include <iostream>

#include "notification_master_plugin_private.h"

#define NOTIFICATION_MASTER_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), notification_master_plugin_get_type(), \
                              NotificationMasterPlugin))

struct _NotificationMasterPlugin {
  GObject parent_instance;
  FlMethodChannel* channel;
  gboolean is_polling_active;
  gboolean is_foreground_active;
  std::thread* polling_thread;
  std::atomic<bool> stop_polling;
};

G_DEFINE_TYPE(NotificationMasterPlugin, notification_master_plugin, g_object_get_type())

// Forward declarations
static void start_polling_service(NotificationMasterPlugin* self, const gchar* polling_url, gint interval_minutes);
static void stop_polling_service(NotificationMasterPlugin* self);

// Show a simple notification using libnotify
static gboolean show_notification(const gchar* title, const gchar* message, const gchar* channel_id) {
  if (!notify_is_initted()) {
    notify_init("NotificationMaster");
  }
  
  NotifyNotification* notification = notify_notification_new(title, message, NULL);
  notify_notification_set_timeout(notification, 5000); // 5 seconds
  
  GError* error = NULL;
  gboolean success = notify_notification_show(notification, &error);
  
  if (error) {
    g_print("Error showing notification: %s\n", error->message);
    g_error_free(error);
  }
  
  g_object_unref(G_OBJECT(notification));
  return success;
}

// Show a big text notification
static gboolean show_big_text_notification(const gchar* title, const gchar* message, const gchar* big_text, const gchar* channel_id) {
  // For simplicity, we'll concatenate the big text to the message
  gchar* full_message = g_strdup_printf("%s\n%s", message, big_text);
  gboolean result = show_notification(title, full_message, channel_id);
  g_free(full_message);
  return result;
}

// Create a notification channel (stub for Linux)
static void create_notification_channel(const gchar* channel_id, const gchar* channel_name, const gchar* channel_description) {
  // Linux doesn't have notification channels like Android, so we'll just log this
  g_print("Created notification channel: %s (%s)\n", channel_name, channel_id);
}

// Called when a method call is received from Flutter.
static void notification_master_plugin_handle_method_call(
    NotificationMasterPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  if (strcmp(method, "getPlatformVersion") == 0) {
    response = get_platform_version();
  } else if (strcmp(method, "requestNotificationPermission") == 0) {
    // Linux notifications don't typically require explicit permission
    g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "checkNotificationPermission") == 0) {
    // Linux notifications are generally allowed by default
    g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "showNotification") == 0) {
    if (fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* title_value = fl_value_lookup_string(args, "title");
      FlValue* message_value = fl_value_lookup_string(args, "message");
      FlValue* id_value = fl_value_lookup_string(args, "id");
      
      if (title_value && message_value) {
        const gchar* title = fl_value_get_string(title_value);
        const gchar* message = fl_value_get_string(message_value);
        const gchar* channel_id = "default";
        int notification_id = 1; // Default ID
        
        FlValue* channel_id_value = fl_value_lookup_string(args, "channelId");
        if (channel_id_value) {
          channel_id = fl_value_get_string(channel_id_value);
        }
        
        // Extract custom ID if provided
        if (id_value && fl_value_get_type(id_value) == FL_VALUE_TYPE_INT) {
          notification_id = fl_value_get_int(id_value);
        }
        
        gboolean success = show_notification(title, message, channel_id);
        g_autoptr(FlValue) result = fl_value_new_int(success ? notification_id : -1);
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
      } else {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGUMENTS", "Invalid arguments for showNotification", nullptr));
      }
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGUMENTS", "Invalid arguments for showNotification", nullptr));
    }
  } else if (strcmp(method, "showBigTextNotification") == 0) {
    if (fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* title_value = fl_value_lookup_string(args, "title");
      FlValue* message_value = fl_value_lookup_string(args, "message");
      FlValue* big_text_value = fl_value_lookup_string(args, "bigText");
      
      if (title_value && message_value && big_text_value) {
        const gchar* title = fl_value_get_string(title_value);
        const gchar* message = fl_value_get_string(message_value);
        const gchar* big_text = fl_value_get_string(big_text_value);
        const gchar* channel_id = "default";
        
        FlValue* channel_id_value = fl_value_lookup_string(args, "channelId");
        if (channel_id_value) {
          channel_id = fl_value_get_string(channel_id_value);
        }
        
        gboolean success = show_big_text_notification(title, message, big_text, channel_id);
        g_autoptr(FlValue) result = fl_value_new_int(success ? 1 : -1);
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
      } else {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGUMENTS", "Invalid arguments for showBigTextNotification", nullptr));
      }
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGUMENTS", "Invalid arguments for showBigTextNotification", nullptr));
    }
  } else if (strcmp(method, "showImageNotification") == 0) {
    if (fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* title_value = fl_value_lookup_string(args, "title");
      FlValue* message_value = fl_value_lookup_string(args, "message");
      FlValue* image_url_value = fl_value_lookup_string(args, "imageUrl");
      
      if (title_value && message_value && image_url_value) {
        const gchar* title = fl_value_get_string(title_value);
        const gchar* message = fl_value_get_string(message_value);
        const gchar* image_url = fl_value_get_string(image_url_value);
        const gchar* channel_id = "default";
        
        FlValue* channel_id_value = fl_value_lookup_string(args, "channelId");
        if (channel_id_value) {
          channel_id = fl_value_get_string(channel_id_value);
        }
        
        // For simplicity, we'll just include the image URL in the message
        gchar* full_message = g_strdup_printf("%s\nImage: %s", message, image_url);
        gboolean success = show_notification(title, full_message, channel_id);
        g_free(full_message);
        
        g_autoptr(FlValue) result = fl_value_new_int(success ? 1 : -1);
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
      } else {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGUMENTS", "Invalid arguments for showImageNotification", nullptr));
      }
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGUMENTS", "Invalid arguments for showImageNotification", nullptr));
    }
  } else if (strcmp(method, "showNotificationWithActions") == 0) {
    if (fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* title_value = fl_value_lookup_string(args, "title");
      FlValue* message_value = fl_value_lookup_string(args, "message");
      
      if (title_value && message_value) {
        const gchar* title = fl_value_get_string(title_value);
        const gchar* message = fl_value_get_string(message_value);
        const gchar* channel_id = "default";
        
        FlValue* channel_id_value = fl_value_lookup_string(args, "channelId");
        if (channel_id_value) {
          channel_id = fl_value_get_string(channel_id_value);
        }
        
        // For simplicity, we'll just show a regular notification
        gboolean success = show_notification(title, message, channel_id);
        g_autoptr(FlValue) result = fl_value_new_int(success ? 1 : -1);
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
      } else {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGUMENTS", "Invalid arguments for showNotificationWithActions", nullptr));
      }
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGUMENTS", "Invalid arguments for showNotificationWithActions", nullptr));
    }
  } else if (strcmp(method, "createCustomChannel") == 0) {
    if (fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* channel_id_value = fl_value_lookup_string(args, "channelId");
      FlValue* channel_name_value = fl_value_lookup_string(args, "channelName");
      
      if (channel_id_value && channel_name_value) {
        const gchar* channel_id = fl_value_get_string(channel_id_value);
        const gchar* channel_name = fl_value_get_string(channel_name_value);
        const gchar* channel_description = "";
        
        FlValue* channel_description_value = fl_value_lookup_string(args, "channelDescription");
        if (channel_description_value) {
          channel_description = fl_value_get_string(channel_description_value);
        }
        
        create_notification_channel(channel_id, channel_name, channel_description);
        g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
      } else {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGUMENTS", "Invalid arguments for createCustomChannel", nullptr));
      }
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGUMENTS", "Invalid arguments for createCustomChannel", nullptr));
    }
  } else if (strcmp(method, "startNotificationPolling") == 0) {
    if (fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* polling_url_value = fl_value_lookup_string(args, "pollingUrl");
      
      if (polling_url_value) {
        const gchar* polling_url = fl_value_get_string(polling_url_value);
        gint interval_minutes = 15; // Default value
        
        FlValue* interval_minutes_value = fl_value_lookup_string(args, "intervalMinutes");
        if (interval_minutes_value) {
          interval_minutes = fl_value_get_int(interval_minutes_value);
        }
        
        start_polling_service(self, polling_url, interval_minutes);
        g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
      } else {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGUMENTS", "Invalid arguments for startNotificationPolling", nullptr));
      }
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGUMENTS", "Invalid arguments for startNotificationPolling", nullptr));
    }
  } else if (strcmp(method, "stopNotificationPolling") == 0) {
    stop_polling_service(self);
    g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "startForegroundService") == 0) {
    if (fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* polling_url_value = fl_value_lookup_string(args, "pollingUrl");
      
      if (polling_url_value) {
        const gchar* polling_url = fl_value_get_string(polling_url_value);
        gint interval_minutes = 15; // Default value
        
        FlValue* interval_minutes_value = fl_value_lookup_string(args, "intervalMinutes");
        if (interval_minutes_value) {
          interval_minutes = fl_value_get_int(interval_minutes_value);
        }
        
        // Linux doesn't have foreground services in the same way as Android
        // We'll treat this as starting the polling service
        self->is_foreground_active = TRUE;
        start_polling_service(self, polling_url, interval_minutes);
        g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
      } else {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGUMENTS", "Invalid arguments for startForegroundService", nullptr));
      }
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGUMENTS", "Invalid arguments for startForegroundService", nullptr));
    }
  } else if (strcmp(method, "stopForegroundService") == 0) {
    stop_polling_service(self);
    self->is_foreground_active = FALSE;
    g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "setFirebaseAsActiveService") == 0) {
    // Not applicable on Linux
    g_autoptr(FlValue) result = fl_value_new_bool(FALSE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "getActiveNotificationService") == 0) {
    const gchar* service = "none";
    if (self->is_foreground_active) {
      service = "foreground";
    } else if (self->is_polling_active) {
      service = "polling";
    }
    
    g_autoptr(FlValue) result = fl_value_new_string(service);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

FlMethodResponse* get_platform_version() {
  struct utsname uname_data = {};
  uname(&uname_data);
  g_autofree gchar *version = g_strdup_printf("Linux %s", uname_data.version);
  g_autoptr(FlValue) result = fl_value_new_string(version);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

// Function to start polling for notifications
static void start_polling_service(NotificationMasterPlugin* self, const gchar* polling_url, gint interval_minutes) {
  if (self->is_polling_active) return;
  
  self->is_polling_active = TRUE;
  self->stop_polling = false;
  
  // Start polling in a separate thread
  self->polling_thread = new std::thread([self, polling_url, interval_minutes]() {
    while (!self->stop_polling) {
      try {
        // In a real implementation, you would make an HTTP request to the polling_url
        // and parse the JSON response to show notifications
        // For now, we'll just sleep for the specified interval
        
        // Sleep for the specified interval
        std::this_thread::sleep_for(std::chrono::minutes(interval_minutes));
      }
      catch (...) {
        // Handle any exceptions
      }
    }
  });
}

// Function to stop polling service
static void stop_polling_service(NotificationMasterPlugin* self) {
  if (!self->is_polling_active) return;
  
  self->stop_polling = true;
  if (self->polling_thread && self->polling_thread->joinable()) {
    self->polling_thread->join();
    delete self->polling_thread;
    self->polling_thread = nullptr;
  }
  self->is_polling_active = FALSE;
}

static void notification_master_plugin_dispose(GObject* object) {
  NotificationMasterPlugin* self = NOTIFICATION_MASTER_PLUGIN(object);
  
  // Stop any active services
  stop_polling_service(self);
  
  G_OBJECT_CLASS(notification_master_plugin_parent_class)->dispose(object);
}

static void notification_master_plugin_class_init(NotificationMasterPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = notification_master_plugin_dispose;
}

static void notification_master_plugin_init(NotificationMasterPlugin* self) {
  self->is_polling_active = FALSE;
  self->is_foreground_active = FALSE;
  self->polling_thread = nullptr;
  self->stop_polling = false;
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  NotificationMasterPlugin* plugin = NOTIFICATION_MASTER_PLUGIN(user_data);
  notification_master_plugin_handle_method_call(plugin, method_call);
}

void notification_master_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  NotificationMasterPlugin* plugin = NOTIFICATION_MASTER_PLUGIN(
      g_object_new(notification_master_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  plugin->channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "notification_master",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(plugin->channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}