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
#include <map>
#include <mutex>
#include <signal.h>
#include <ctime>
#include <unistd.h>

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
  // Background daemon process (startBackgroundPollingService)
  GPid daemon_pid;
  gboolean daemon_active;
};

G_DEFINE_TYPE(NotificationMasterPlugin, notification_master_plugin, g_object_get_type())

// Forward declarations
static void start_polling_service(NotificationMasterPlugin* self, const gchar* polling_url, gint interval_minutes);
static void stop_polling_service(NotificationMasterPlugin* self);
static gboolean start_background_daemon(NotificationMasterPlugin* self, const gchar* url, gint interval_minutes);
static void     stop_background_daemon(NotificationMasterPlugin* self);
static gboolean is_background_daemon_running(NotificationMasterPlugin* self);

// Scheduled (background) notification tracking for Linux. A detached child
// process (see scheduleNotification) survives the app closing; we keep its pid
// so it can be cancelled during the same session.
static std::mutex g_scheduled_mutex;
static std::map<int, GPid> g_scheduled_pids;

// Shell-escape a string for use inside single quotes (sh -c command).
static gchar* sh_quote_string(const gchar* s) {
  if (!s) return g_strdup("''");
  GString* out = g_string_new("'");
  for (const gchar* p = s; *p; ++p) {
    if (*p == '\'') {
      g_string_append(out, "'\\''");
    } else {
      g_string_append_c(out, *p);
    }
  }
  g_string_append_c(out, '\'');
  return g_string_free(out, FALSE);
}

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
        
        // Stop any running service first (mutual exclusivity).
        stop_polling_service(self);
        self->is_foreground_active = FALSE;

        // Persist so getActiveNotificationService returns the right value.
        GKeyFile* kf = load_prefs();
        g_key_file_set_string(kf, "service", "active", "polling");
        save_prefs(kf);
        g_key_file_free(kf);

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
        
        // Stop any running service first (mutual exclusivity).
        stop_polling_service(self);

        // Persist service type.
        GKeyFile* kf = load_prefs();
        g_key_file_set_string(kf, "service", "active", "foreground");
        save_prefs(kf);
        g_key_file_free(kf);

        // Linux has no foreground service concept; treat as polling.
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
  } else if (strcmp(method, "getActiveNotificationService") == 0) {
    const gchar* service = "none";
    if (self->is_foreground_active) {
      service = "foreground";
    } else if (self->is_polling_active) {
      service = "polling";
    } else {
      // Check if firebase was set persistently.
      GKeyFile* kf = load_prefs();
      gchar* stored = g_key_file_get_string(kf, "service", "active", nullptr);
      g_key_file_free(kf);
      if (g_strcmp0(stored, "firebase") == 0) {
        service = "firebase";
      }
      g_free(stored);
    }
    g_autoptr(FlValue) result = fl_value_new_string(service);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "showHeadsUpNotification") == 0 ||
             strcmp(method, "showFullScreenNotification") == 0 ||
             strcmp(method, "showStyledNotification") == 0) {
    // Treat as regular notification on Linux
    if (fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* title_value = fl_value_lookup_string(args, "title");
      FlValue* message_value = fl_value_lookup_string(args, "message");
      const gchar* title = title_value ? fl_value_get_string(title_value) : "Notification";
      const gchar* message = message_value ? fl_value_get_string(message_value) : "";
      gboolean success = show_notification(title, message, "default");
      g_autoptr(FlValue) result = fl_value_new_int(success ? 1 : -1);
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGUMENTS", "Invalid arguments", nullptr));
    }
  } else if (strcmp(method, "getDeviceToken") == 0) {
    gchar* token = get_device_token();
    g_autoptr(FlValue) result = fl_value_new_string(token ? token : "");
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    g_free(token);
  } else if (strcmp(method, "subscribeToTopic") == 0) {
    if (fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* topic_value = fl_value_lookup_string(args, "topic");
      if (topic_value && fl_value_get_type(topic_value) == FL_VALUE_TYPE_STRING) {
        const gchar* topic = fl_value_get_string(topic_value);
        subscribe_to_topic(topic);
        g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
      } else {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_TOPIC", "topic is required", nullptr));
      }
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGUMENTS", "Invalid arguments", nullptr));
    }
  } else if (strcmp(method, "unsubscribeFromTopic") == 0) {
    if (fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* topic_value = fl_value_lookup_string(args, "topic");
      if (topic_value && fl_value_get_type(topic_value) == FL_VALUE_TYPE_STRING) {
        const gchar* topic = fl_value_get_string(topic_value);
        unsubscribe_from_topic(topic);
        g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
      } else {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_TOPIC", "topic is required", nullptr));
      }
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGUMENTS", "Invalid arguments", nullptr));
    }
  } else if (strcmp(method, "getSubscribedTopics") == 0) {
    g_autoptr(FlValue) list = get_subscribed_topics();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(list));
  } else if (strcmp(method, "scheduleNotification") == 0) {
    if (fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* id_value = fl_value_lookup_string(args, "id");
      FlValue* title_value = fl_value_lookup_string(args, "title");
      FlValue* message_value = fl_value_lookup_string(args, "message");
      FlValue* epoch_value = fl_value_lookup_string(args, "scheduledEpochMillis");
      FlValue* alarm_value = fl_value_lookup_string(args, "alarmSound");

      if (title_value && message_value && id_value && epoch_value) {
        gint id = fl_value_get_int(id_value);
        gint64 epoch_millis = fl_value_get_int(epoch_value);
        gboolean alarm_sound = alarm_value && fl_value_get_type(alarm_value) == FL_VALUE_TYPE_BOOL
            ? fl_value_get_bool(alarm_value) : FALSE;
        const gchar* title = fl_value_get_string(title_value);
        const gchar* message = fl_value_get_string(message_value);

        gint64 now_secs = (gint64)time(nullptr);
        gint64 target_secs = epoch_millis / 1000;
        gint64 delay = target_secs - now_secs;
        if (delay < 0) delay = 0;

        gboolean ok = FALSE;
        if (delay == 0) {
          show_notification(title, message, "default");
          ok = TRUE;
        } else {
          // Spawn a fully detached process (setsid) that sleeps then fires
          // notify-send. This survives the app being fully closed.
          gchar* escaped_title = sh_quote_string(title);
          gchar* escaped_message = sh_quote_string(message);
          gchar* command = g_strdup_printf(
              "sleep %lld && notify-send %s %s",
              (long long)delay, escaped_title, escaped_message);
          gchar* argv[] = { const_cast<gchar*>("setsid"),
                            const_cast<gchar*>("sh"),
                            const_cast<gchar*>("-c"),
                            command, nullptr };
          GPid pid = 0;
          GError* spawn_error = nullptr;
          gboolean spawned = g_spawn_async(
              nullptr, argv, nullptr,
              (GSpawnFlags)(G_SPAWN_SEARCH_PATH | G_SPAWN_STDOUT_TO_DEV_NULL |
                            G_SPAWN_STDERR_TO_DEV_NULL | G_SPAWN_DO_NOT_REAP_CHILD),
              nullptr, nullptr, &pid, &spawn_error);
          if (spawned) {
            std::lock_guard<std::mutex> lock(g_scheduled_mutex);
            g_scheduled_pids[id] = pid;
            ok = TRUE;
          } else {
            g_print("Failed to schedule notification: %s\n",
                    spawn_error ? spawn_error->message : "unknown");
            if (spawn_error) g_error_free(spawn_error);
            // Fall back to showing immediately.
            show_notification(title, message, "default");
            ok = TRUE;
          }
          g_free(escaped_title);
          g_free(escaped_message);
          g_free(command);
        }
        (void)alarm_sound;
        g_autoptr(FlValue) result = fl_value_new_bool(ok);
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
      } else {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGUMENTS", "id, title, message and scheduledEpochMillis are required", nullptr));
      }
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGUMENTS", "Invalid arguments for scheduleNotification", nullptr));
    }
  } else if (strcmp(method, "cancelScheduledNotification") == 0) {
    if (fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* id_value = fl_value_lookup_string(args, "id");
      if (id_value) {
        gint id = fl_value_get_int(id_value);
        std::lock_guard<std::mutex> lock(g_scheduled_mutex);
        auto it = g_scheduled_pids.find(id);
        if (it != g_scheduled_pids.end()) {
          kill(it->second, SIGKILL);
          g_spawn_close_pid(it->second);
          g_scheduled_pids.erase(it);
        }
        g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
      } else {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGUMENTS", "id is required", nullptr));
      }
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGUMENTS", "Invalid arguments for cancelScheduledNotification", nullptr));
    }
  } else if (strcmp(method, "cancelAllScheduledNotifications") == 0) {
    std::lock_guard<std::mutex> lock(g_scheduled_mutex);
    for (auto& kv : g_scheduled_pids) {
      kill(kv.second, SIGKILL);
      g_spawn_close_pid(kv.second);
    }
    g_scheduled_pids.clear();
    g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "getPendingScheduledNotifications") == 0) {
    g_autoptr(FlValue) list = fl_value_new_list();
    std::lock_guard<std::mutex> lock(g_scheduled_mutex);
    for (auto& kv : g_scheduled_pids) {
      fl_value_append_take(list, fl_value_new_int(kv.first));
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(list));

  // ── Android-only permission gates — always true / no-op on Linux ─────────
  } else if (strcmp(method, "canScheduleExactAlarms") == 0) {
    g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "openExactAlarmSettings") == 0) {
    g_autoptr(FlValue) result = fl_value_new_bool(FALSE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "openAppNotificationSettings") == 0) {
    // Open GNOME notification settings if available; ignore errors.
    g_spawn_command_line_async("gnome-control-center notifications", nullptr);
    g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));

  // ── Firebase — not applicable on Linux (returns true, no-op) ────────────
  } else if (strcmp(method, "setFirebaseAsActiveService") == 0) {
    // Mark firebase as active so getActiveNotificationService() reports it.
    GKeyFile* kf = load_prefs();
    g_key_file_set_string(kf, "service", "active", "firebase");
    save_prefs(kf);
    g_key_file_free(kf);
    stop_polling_service(self);
    self->is_foreground_active = FALSE;
    g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));

  // ── Background daemon (notification_master_poller) ─────────────────────
  } else if (strcmp(method, "startBackgroundPollingService") == 0) {
    if (fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* url_val = fl_value_lookup_string(args, "pollingUrl");
      FlValue* iv_val  = fl_value_lookup_string(args, "intervalMinutes");
      const gchar* url = (url_val && fl_value_get_type(url_val) == FL_VALUE_TYPE_STRING)
                         ? fl_value_get_string(url_val) : nullptr;
      gint interval    = (iv_val  && fl_value_get_type(iv_val)  == FL_VALUE_TYPE_INT)
                         ? (gint)fl_value_get_int(iv_val) : 15;
      if (!url || strlen(url) == 0) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGUMENT", "pollingUrl is required", nullptr));
      } else {
        gboolean ok = start_background_daemon(self, url, interval);
        g_autoptr(FlValue) result = fl_value_new_bool(ok);
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
      }
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGUMENT", "Invalid arguments", nullptr));
    }
  } else if (strcmp(method, "stopBackgroundPollingService") == 0) {
    stop_background_daemon(self);
    g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "isBackgroundPollingRunning") == 0) {
    gboolean running = is_background_daemon_running(self);
    g_autoptr(FlValue) result = fl_value_new_bool(running);
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

// ── GKeyFile-based persistent storage ────────────────────────────────────────
// File: ~/.config/notification_master/prefs.ini

static gchar* get_prefs_path() {
  return g_build_filename(g_get_user_config_dir(),
                          "notification_master", "prefs.ini", nullptr);
}

static GKeyFile* load_prefs() {
  GKeyFile* kf = g_key_file_new();
  gchar* path = get_prefs_path();
  g_key_file_load_from_file(kf, path, G_KEY_FILE_NONE, nullptr);
  g_free(path);
  return kf;
}

static void save_prefs(GKeyFile* kf) {
  gchar* path = get_prefs_path();
  // Ensure directory exists
  gchar* dir = g_path_get_dirname(path);
  g_mkdir_with_parents(dir, 0700);
  g_free(dir);
  g_key_file_save_to_file(kf, path, nullptr);
  g_free(path);
}

// Returns a heap-allocated string (caller must g_free)
static gchar* get_device_token() {
  GKeyFile* kf = load_prefs();
  gchar* token = g_key_file_get_string(kf, "device", "token", nullptr);
  g_key_file_free(kf);

  if (token && strlen(token) > 0) {
    // Local confirmation notification
    gchar* preview = g_strndup(token, 24);
    gchar* msg = g_strdup_printf("Token (cached): %s…", preview);
    show_notification("Device Token (Linux)", msg, "default");
    g_free(preview);
    g_free(msg);
    return token;
  }
  g_free(token);

  // Generate a stable ID from /etc/machine-id (standard on systemd distros)
  gchar* machine_id = nullptr;
  if (g_file_get_contents("/etc/machine-id", &machine_id, nullptr, nullptr)) {
    g_strstrip(machine_id);
    GKeyFile* kf2 = load_prefs();
    g_key_file_set_string(kf2, "device", "token", machine_id);
    save_prefs(kf2);
    g_key_file_free(kf2);
    gchar* preview = g_strndup(machine_id, 24);
    gchar* msg = g_strdup_printf("Token (machine-id): %s…", preview);
    show_notification("Device Token (Linux)", msg, "default");
    g_free(preview);
    g_free(msg);
    return machine_id;
  }

  // Fallback: hostname
  const gchar* host = g_get_host_name();
  gchar* id = g_strdup(host ? host : "linux-device");
  GKeyFile* kf3 = load_prefs();
  g_key_file_set_string(kf3, "device", "token", id);
  save_prefs(kf3);
  g_key_file_free(kf3);
  gchar* msg = g_strdup_printf("Token (hostname): %s", id);
  show_notification("Device Token (Linux)", msg, "default");
  g_free(msg);
  return id;
}

static void subscribe_to_topic(const gchar* topic) {
  GKeyFile* kf = load_prefs();
  gsize len = 0;
  gchar** topics = g_key_file_get_string_list(kf, "topics", "subscribed", &len, nullptr);

  gboolean found = FALSE;
  for (gsize i = 0; i < len; i++) {
    if (g_strcmp0(topics[i], topic) == 0) { found = TRUE; break; }
  }

  if (!found) {
    gchar** new_topics = g_new(gchar*, len + 2);
    for (gsize i = 0; i < len; i++) new_topics[i] = topics[i];
    new_topics[len] = g_strdup(topic);
    new_topics[len + 1] = nullptr;
    g_key_file_set_string_list(kf, "topics", "subscribed",
                               (const gchar* const*)new_topics, len + 1);
    g_free(new_topics[len]);
    g_free(new_topics);
    save_prefs(kf);
  }

  g_strfreev(topics);
  g_key_file_free(kf);

  // Local confirmation notification
  gchar* msg = g_strdup_printf("You are now subscribed to topic: %s", topic);
  show_notification("Subscribed", msg, "default");
  g_free(msg);
}

static void unsubscribe_from_topic(const gchar* topic) {
  GKeyFile* kf = load_prefs();
  gsize len = 0;
  gchar** topics = g_key_file_get_string_list(kf, "topics", "subscribed", &len, nullptr);

  GPtrArray* remaining = g_ptr_array_new();
  for (gsize i = 0; i < len; i++) {
    if (g_strcmp0(topics[i], topic) != 0) {
      g_ptr_array_add(remaining, topics[i]);
    }
  }

  g_key_file_set_string_list(kf, "topics", "subscribed",
                             (const gchar* const*)remaining->pdata,
                             remaining->len);
  save_prefs(kf);

  g_ptr_array_free(remaining, FALSE);
  g_strfreev(topics);
  g_key_file_free(kf);

  // Local confirmation notification
  gchar* msg = g_strdup_printf("You have unsubscribed from topic: %s", topic);
  show_notification("Unsubscribed", msg, "default");
  g_free(msg);
}

// Returns a new FlValue list — caller owns it (use g_autoptr)
static FlValue* get_subscribed_topics() {
  GKeyFile* kf = load_prefs();
  gsize len = 0;
  gchar** topics = g_key_file_get_string_list(kf, "topics", "subscribed", &len, nullptr);
  g_key_file_free(kf);

  FlValue* list = fl_value_new_list();
  for (gsize i = 0; i < len; i++) {
    fl_value_append_take(list, fl_value_new_string(topics[i]));
  }
  g_strfreev(topics);
  return list;
}

// ── HTTP polling helpers ──────────────────────────────────────────────────────
// Parse and display a JSON polling response.
// Expected shape: { "notifications": [ { "title": "...", "message": "...",
//                                        "bigText": "..." }, ... ] }
// Non-conforming responses fall back to a single generic notification.
static void process_poll_response(const gchar* body, gsize len) {
  if (!body || len == 0) {
    show_notification("Notification", "New notification received", "default");
    return;
  }

  GError* err = nullptr;
  JsonParser* parser = json_parser_new();
  gboolean ok = json_parser_load_from_data(parser, body, (gssize)len, &err);

  if (!ok || err) {
    g_print("[NotificationMaster] JSON parse error: %s\n",
            err ? err->message : "unknown");
    if (err) g_error_free(err);
    g_object_unref(parser);
    show_notification("Notification", "New notification received", "default");
    return;
  }

  JsonNode* root = json_parser_get_root(parser);
  if (!root || !JSON_NODE_HOLDS_OBJECT(root)) {
    g_object_unref(parser);
    show_notification("Notification", "New notification received", "default");
    return;
  }

  JsonObject* obj = json_node_get_object(root);
  if (!json_object_has_member(obj, "notifications")) {
    g_object_unref(parser);
    show_notification("Notification", "New notification received", "default");
    return;
  }

  JsonArray* arr = json_object_get_array_member(obj, "notifications");
  guint count = json_array_get_length(arr);
  for (guint i = 0; i < count; i++) {
    JsonObject* n = json_array_get_object_element(arr, i);
    const gchar* title   = json_object_has_member(n, "title")   ?
                           json_object_get_string_member(n, "title")   : "Notification";
    const gchar* big_text = json_object_has_member(n, "bigText") ?
                            json_object_get_string_member(n, "bigText") : nullptr;
    const gchar* message = json_object_has_member(n, "message") ?
                           json_object_get_string_member(n, "message") : "";
    const gchar* body_text = (big_text && big_text[0]) ? big_text : message;
    show_notification(title, body_text, "default");
  }

  g_object_unref(parser);
}

// Perform one synchronous HTTP GET using libsoup and process the response.
// Called from the background polling thread — must not touch GTK/GLib main loop.
static void perform_poll(const gchar* polling_url) {
#if SOUP_VERSION == 3
  SoupSession* session = soup_session_new();
  SoupMessage* msg = soup_message_new(SOUP_METHOD_GET, polling_url);
  if (!msg) { g_object_unref(session); return; }

  GError* err = nullptr;
  GBytes* bytes = soup_session_send_and_read(session, msg, nullptr, &err);
  if (err) {
    g_print("[NotificationMaster] HTTP error: %s\n", err->message);
    g_error_free(err);
  } else if (bytes) {
    gsize len = 0;
    const gchar* data = (const gchar*)g_bytes_get_data(bytes, &len);
    process_poll_response(data, len);
    g_bytes_unref(bytes);
  }
  g_object_unref(msg);
  g_object_unref(session);
#else
  // libsoup 2.4 synchronous API
  SoupSession* session = soup_session_new();
  SoupMessage* msg = soup_message_new(SOUP_METHOD_GET, polling_url);
  if (!msg) { g_object_unref(session); return; }

  guint status = soup_session_send_message(session, msg);
  if (SOUP_STATUS_IS_SUCCESSFUL(status)) {
    SoupMessageBody* body = msg->response_body;
    if (body && body->data) {
      process_poll_response(body->data, (gsize)body->length);
    }
  } else {
    g_print("[NotificationMaster] HTTP status %u for %s\n", status, polling_url);
  }
  g_object_unref(msg);
  g_object_unref(session);
#endif
}

// ---------------------------------------------------------------------------
// Background daemon helpers
// ---------------------------------------------------------------------------

// Write a value to ~/.config/notification_master/poller.conf
static void daemon_write_conf(const gchar* key, const gchar* value) {
  gchar* path = g_build_filename(g_get_user_config_dir(),
                                 "notification_master", "poller.conf", nullptr);
  gchar* dir  = g_build_filename(g_get_user_config_dir(),
                                 "notification_master", nullptr);
  g_mkdir_with_parents(dir, 0700);

  GKeyFile* kf = g_key_file_new();
  g_key_file_load_from_file(kf, path, G_KEY_FILE_NONE, nullptr);
  g_key_file_set_string(kf, "poller", key, value);
  g_key_file_save_to_file(kf, path, nullptr);

  g_key_file_free(kf);
  g_free(dir);
  g_free(path);
}

static gboolean start_background_daemon(NotificationMasterPlugin* self,
                                        const gchar* url,
                                        gint interval_minutes) {
  // If already running, update URL/interval and return success.
  if (is_background_daemon_running(self)) {
    daemon_write_conf("url", url);
    gchar* iv = g_strdup_printf("%d", interval_minutes > 0 ? interval_minutes : 15);
    daemon_write_conf("interval", iv);
    g_free(iv);
    return TRUE;
  }

  // Locate the daemon executable next to our own binary.
  // /proc/self/exe -> .../runner/notification_master_example
  // daemon lives in the same directory.
  char self_path[4096] = {};
  ssize_t n = readlink("/proc/self/exe", self_path, sizeof(self_path) - 1);
  if (n <= 0) return FALSE;
  gchar* exe_dir  = g_path_get_dirname(self_path);
  gchar* daemon   = g_build_filename(exe_dir, "notification_master_poller", nullptr);
  g_free(exe_dir);

  if (!g_file_test(daemon, G_FILE_TEST_IS_EXECUTABLE)) {
    g_printerr("[NM] daemon not found at %s\n", daemon);
    g_free(daemon);
    return FALSE;
  }

  gchar iv_str[32];
  snprintf(iv_str, sizeof(iv_str), "%d", interval_minutes > 0 ? interval_minutes : 15);

  gchar* argv[] = {
    daemon,
    const_cast<gchar*>("--url"),      const_cast<gchar*>(url),
    const_cast<gchar*>("--interval"), iv_str,
    nullptr
  };

  GError*    err    = nullptr;
  GPid       pid    = 0;
  gboolean   spawned = g_spawn_async(
      nullptr, argv, nullptr,
      (GSpawnFlags)(G_SPAWN_DO_NOT_REAP_CHILD |
                    G_SPAWN_STDOUT_TO_DEV_NULL |
                    G_SPAWN_STDERR_TO_DEV_NULL),
      nullptr, nullptr, &pid, &err);

  g_free(daemon);

  if (!spawned) {
    g_printerr("[NM] failed to launch daemon: %s\n",
               err ? err->message : "unknown");
    if (err) g_error_free(err);
    return FALSE;
  }

  self->daemon_pid    = pid;
  self->daemon_active = TRUE;
  daemon_write_conf("enabled", "1");
  return TRUE;
}

static void stop_background_daemon(NotificationMasterPlugin* self) {
  daemon_write_conf("enabled", "0");

  if (self->daemon_active && self->daemon_pid > 0) {
    kill(self->daemon_pid, SIGTERM);
    g_spawn_close_pid(self->daemon_pid);
    self->daemon_pid    = 0;
    self->daemon_active = FALSE;
  }
}

static gboolean is_background_daemon_running(NotificationMasterPlugin* self) {
  if (!self->daemon_active || self->daemon_pid <= 0) return FALSE;

  // kill(pid, 0) checks if process exists without sending a signal.
  if (kill(self->daemon_pid, 0) == 0) return TRUE;

  // Process gone — clean up state.
  g_spawn_close_pid(self->daemon_pid);
  self->daemon_pid    = 0;
  self->daemon_active = FALSE;
  return FALSE;
}

// Start the background polling thread with real HTTP + JSON parsing.
static void start_polling_service(NotificationMasterPlugin* self,
                                  const gchar* polling_url,
                                  gint interval_minutes) {
  if (self->is_polling_active) return;

  self->is_polling_active = TRUE;
  self->stop_polling = false;

  // Capture URL as an owned copy so the thread always has a valid pointer.
  std::string url_copy(polling_url ? polling_url : "");
  gint interval = (interval_minutes > 0) ? interval_minutes : 15;

  self->polling_thread = new std::thread([self, url_copy, interval]() {
    // Fire one poll immediately on start.
    if (!self->stop_polling && !url_copy.empty()) {
      perform_poll(url_copy.c_str());
    }

    // Then repeat every `interval` minutes, checking stop_polling every second
    // so shutdown is responsive without sleeping the full interval.
    for (gint elapsed = 0; !self->stop_polling; elapsed++) {
      std::this_thread::sleep_for(std::chrono::seconds(1));
      if (self->stop_polling) break;
      if (elapsed >= interval * 60) {
        elapsed = 0;
        if (!url_copy.empty()) {
          perform_poll(url_copy.c_str());
        }
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

  // Clear the persisted active service if it was polling/foreground.
  GKeyFile* kf = load_prefs();
  gchar* stored = g_key_file_get_string(kf, "service", "active", nullptr);
  if (g_strcmp0(stored, "polling") == 0 || g_strcmp0(stored, "foreground") == 0) {
    g_key_file_set_string(kf, "service", "active", "none");
    save_prefs(kf);
  }
  g_free(stored);
  g_key_file_free(kf);
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
  self->is_polling_active    = FALSE;
  self->is_foreground_active = FALSE;
  self->polling_thread       = nullptr;
  self->stop_polling         = false;
  self->daemon_pid           = 0;
  self->daemon_active        = FALSE;
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