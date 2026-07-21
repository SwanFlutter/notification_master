// notification_master background poller daemon — Linux
//
// Standalone executable launched by the Flutter plugin via
// startBackgroundPollingService(). Keeps polling an HTTP endpoint and showing
// desktop notifications via libnotify even after the main Flutter app closes.
//
// Config is stored in ~/.config/notification_master/poller.conf (GKeyFile).
// Keys written by the plugin before launching this process:
//   [poller]
//   url      = https://...
//   interval = 1          (minutes, default 15)
//   enabled  = 1
//
// Log is written next to this executable: notification_master_poller.log
//
// Build: added as add_executable(notification_master_poller ...) in
// linux/CMakeLists.txt, links libnotify + libcurl + glib-2.0 + json-glib-1.0.

#include <glib.h>
#include <glib/gstdio.h>
#include <libnotify/notify.h>
#include <curl/curl.h>
#include <json-glib/json-glib.h>

#include <atomic>
#include <chrono>
#include <cstdio>
#include <cstring>
#include <ctime>
#include <fstream>
#include <map>
#include <mutex>
#include <string>
#include <thread>
#include <unistd.h>
#include <signal.h>
#include <sys/stat.h>

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
static constexpr long long kDedupeWindowMs = 60LL * 60 * 1000; // 1 hour
static const char* kAppName  = "NotificationMaster";
static const char* kConfDir  = "notification_master";
static const char* kConfFile = "poller.conf";
static const char* kGroup    = "poller";

// ---------------------------------------------------------------------------
// Logging
// ---------------------------------------------------------------------------
static std::mutex  g_log_mtx;
static std::string g_log_path;

static std::string timestamp_str() {
  struct timespec ts;
  clock_gettime(CLOCK_REALTIME, &ts);
  struct tm t;
  localtime_r(&ts.tv_sec, &t);
  char buf[32];
  snprintf(buf, sizeof(buf), "[%02d:%02d:%02d.%03ld]",
           t.tm_hour, t.tm_min, t.tm_sec, ts.tv_nsec / 1000000L);
  return buf;
}

static void nm_log(const std::string& msg) {
  std::lock_guard<std::mutex> lk(g_log_mtx);
  std::string line = "[NM-POLLER] " + timestamp_str() + " " + msg + "\n";
  if (!g_log_path.empty()) {
    FILE* f = fopen(g_log_path.c_str(), "a");
    if (f) { fputs(line.c_str(), f); fclose(f); }
  }
  fputs(line.c_str(), stderr);
}

#define LOG(msg) nm_log(msg)

// ---------------------------------------------------------------------------
// Config helpers  (~/.config/notification_master/poller.conf)
// ---------------------------------------------------------------------------
static std::string config_path() {
  const char* base = g_get_user_config_dir();
  return std::string(base) + "/" + kConfDir + "/" + kConfFile;
}

static std::string read_conf(const char* key, const char* fallback = "") {
  GKeyFile* kf = g_key_file_new();
  std::string path = config_path();
  g_key_file_load_from_file(kf, path.c_str(), G_KEY_FILE_NONE, nullptr);
  gchar* val = g_key_file_get_string(kf, kGroup, key, nullptr);
  std::string result = val ? val : fallback;
  g_free(val);
  g_key_file_free(kf);
  return result;
}

static void write_conf(const char* key, const std::string& value) {
  std::string path = config_path();
  // Ensure directory exists
  std::string dir = std::string(g_get_user_config_dir()) + "/" + kConfDir;
  g_mkdir_with_parents(dir.c_str(), 0700);

  GKeyFile* kf = g_key_file_new();
  g_key_file_load_from_file(kf, path.c_str(), G_KEY_FILE_NONE, nullptr);
  g_key_file_set_string(kf, kGroup, key, value.c_str());
  g_key_file_save_to_file(kf, path.c_str(), nullptr);
  g_key_file_free(kf);
}

// ---------------------------------------------------------------------------
// HTTP GET  (libcurl)
// ---------------------------------------------------------------------------
struct CurlBuf {
  std::string data;
  static size_t write_cb(char* ptr, size_t size, size_t nmemb, void* ud) {
    auto* b = static_cast<CurlBuf*>(ud);
    b->data.append(ptr, size * nmemb);
    return size * nmemb;
  }
};

static std::string http_get(const std::string& url) {
  CURL* curl = curl_easy_init();
  if (!curl) return "";

  CurlBuf buf;
  curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
  curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, CurlBuf::write_cb);
  curl_easy_setopt(curl, CURLOPT_WRITEDATA, &buf);
  curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
  curl_easy_setopt(curl, CURLOPT_TIMEOUT, 30L);
  curl_easy_setopt(curl, CURLOPT_USERAGENT, "NotificationMasterPoller/1.0");
  // Accept self-signed certs in dev; remove for production hardening
  curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);

  CURLcode res = curl_easy_perform(curl);
  curl_easy_cleanup(curl);

  if (res != CURLE_OK) {
    LOG("http_get: CURL error: " + std::string(curl_easy_strerror(res)));
    return "";
  }
  return buf.data;
}

// ---------------------------------------------------------------------------
// JSON parsing  (minimal — mirrors Windows poller)
// ---------------------------------------------------------------------------
static std::map<std::string, std::string> parse_notification_obj(
    JsonObject* obj) {
  std::map<std::string, std::string> d;
  auto get = [&](const char* k) -> std::string {
    JsonNode* n = json_object_get_member(obj, k);
    if (!n || JSON_NODE_TYPE(n) != JSON_NODE_VALUE) return "";
    const char* v = json_node_get_string(n);
    return v ? v : "";
  };
  d["title"]    = get("title");
  d["message"]  = get("message");
  d["bigText"]  = get("bigText");
  d["imageUrl"] = get("imageUrl");
  return d;
}

// ---------------------------------------------------------------------------
// Deduplication cache
// ---------------------------------------------------------------------------
struct DedupeCache {
  std::mutex mtx;
  std::map<std::string, long long> seen;

  static long long now_ms() {
    using namespace std::chrono;
    return duration_cast<milliseconds>(
               system_clock::now().time_since_epoch())
        .count();
  }

  bool should_show(const std::string& key) {
    long long now = now_ms();
    std::lock_guard<std::mutex> lk(mtx);
    auto it = seen.find(key);
    if (it != seen.end() && (now - it->second) < kDedupeWindowMs)
      return false;
    seen[key] = now;
    return true;
  }
};

static DedupeCache g_dedupe;

// ---------------------------------------------------------------------------
// Show a single notification via libnotify
// ---------------------------------------------------------------------------
static void show_notification(const std::string& title,
                               const std::string& body) {
  if (!notify_is_initted()) notify_init(kAppName);

  std::string key = title + '\0' + body;
  if (!g_dedupe.should_show(key)) {
    LOG("show_notification: SKIPPED (already shown recently): title='" +
        title + "'");
    return;
  }

  LOG("show_notification: title='" + title + "' body='" + body + "'");
  NotifyNotification* n = notify_notification_new(
      title.c_str(), body.empty() ? nullptr : body.c_str(), nullptr);
  notify_notification_set_timeout(n, NOTIFY_EXPIRES_DEFAULT);
  GError* err = nullptr;
  if (!notify_notification_show(n, &err)) {
    LOG("show_notification: ERROR " +
        std::string(err ? err->message : "unknown"));
    if (err) g_error_free(err);
  }
  g_object_unref(G_OBJECT(n));
}

// ---------------------------------------------------------------------------
// Parse server response and show notifications
// ---------------------------------------------------------------------------
static void parse_and_show(const std::string& json_str) {
  GError* err = nullptr;
  JsonParser* parser = json_parser_new();
  if (!json_parser_load_from_data(parser, json_str.c_str(),
                                   (gssize)json_str.size(), &err)) {
    LOG("parse_and_show: JSON parse error: " +
        std::string(err ? err->message : "?"));
    if (err) g_error_free(err);
    g_object_unref(parser);
    return;
  }

  JsonNode* root = json_parser_get_root(parser);
  if (!root || JSON_NODE_TYPE(root) != JSON_NODE_OBJECT) {
    g_object_unref(parser);
    return;
  }
  JsonObject* root_obj = json_node_get_object(root);

  // Format: {"notifications": [...]}
  if (json_object_has_member(root_obj, "notifications")) {
    JsonArray* arr = json_object_get_array_member(root_obj, "notifications");
    if (arr) {
      guint len = json_array_get_length(arr);
      LOG("parse_and_show: found " + std::to_string(len) + " notification(s)");
      for (guint i = 0; i < len; ++i) {
        JsonNode* node = json_array_get_element(arr, i);
        if (JSON_NODE_TYPE(node) == JSON_NODE_OBJECT) {
          auto d = parse_notification_obj(json_node_get_object(node));
          std::string title = d["title"].empty() ? d["message"] : d["title"];
          std::string body  = d["bigText"].empty() ? d["message"] : d["bigText"];
          if (!title.empty() || !body.empty())
            show_notification(title, body);
        }
      }
    }
  }
  // Format: {"data": {...}}
  else if (json_object_has_member(root_obj, "data")) {
    JsonObject* data_obj =
        json_object_get_object_member(root_obj, "data");
    if (data_obj) {
      auto d = parse_notification_obj(data_obj);
      std::string title = d["title"].empty() ? d["message"] : d["title"];
      std::string body  = d["bigText"].empty() ? d["message"] : d["bigText"];
      if (!title.empty() || !body.empty())
        show_notification(title, body);
    }
  }

  g_object_unref(parser);
}

// ---------------------------------------------------------------------------
// Polling loop
// ---------------------------------------------------------------------------
static std::atomic<bool> g_running{true};

static void handle_signal(int) { g_running.store(false); }

static void polling_loop() {
  LOG("polling_loop: started");

  while (g_running.load()) {
    // Re-read config each cycle so the plugin can update URL/interval live.
    std::string url      = read_conf("url");
    std::string en       = read_conf("enabled", "1");
    std::string iv_str   = read_conf("interval", "15");
    int interval         = std::atoi(iv_str.c_str());
    if (interval <= 0) interval = 15;

    if (en != "1") {
      LOG("polling_loop: enabled=0 — exiting");
      break;
    }
    if (url.empty()) {
      LOG("polling_loop: no url configured — waiting");
    } else {
      LOG("polling_loop: requesting " + url);
      std::string resp = http_get(url);
      if (resp.empty()) {
        LOG("polling_loop: empty/failed response");
        write_conf("last_error", "empty response");
      } else {
        LOG("polling_loop: got " + std::to_string(resp.size()) + " bytes");
        parse_and_show(resp);
        // Record last-run timestamp (epoch seconds as string)
        write_conf("last_run",
                   std::to_string(
                       std::chrono::duration_cast<std::chrono::seconds>(
                           std::chrono::system_clock::now().time_since_epoch())
                           .count()));
        write_conf("last_error", "");
      }
    }

    // Sleep interval*60 seconds in 1s slices so SIGTERM is handled quickly.
    for (int i = 0; i < interval * 60 && g_running.load(); ++i) {
      std::this_thread::sleep_for(std::chrono::seconds(1));
    }
  }
  LOG("polling_loop: exited");
}

// ---------------------------------------------------------------------------
// Resolve the log path next to this executable
// ---------------------------------------------------------------------------
static std::string resolve_log_path() {
  char self[4096] = {};
  ssize_t n = readlink("/proc/self/exe", self, sizeof(self) - 1);
  if (n <= 0) return "/tmp/notification_master_poller.log";
  std::string exe(self, n);
  size_t slash = exe.rfind('/');
  std::string dir = (slash != std::string::npos) ? exe.substr(0, slash) : ".";
  return dir + "/notification_master_poller.log";
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------
int main(int argc, char* argv[]) {
  // Set log path next to executable.
  g_log_path = resolve_log_path();

  // Handle termination signals so the daemon exits cleanly.
  signal(SIGTERM, handle_signal);
  signal(SIGINT,  handle_signal);

  // Optionally accept --url and --interval on the command line so the plugin
  // can pass config directly without waiting for the conf file to be written.
  for (int i = 1; i < argc - 1; ++i) {
    if (strcmp(argv[i], "--url") == 0)
      write_conf("url", argv[i + 1]);
    else if (strcmp(argv[i], "--interval") == 0)
      write_conf("interval", argv[i + 1]);
  }
  write_conf("enabled", "1");

  LOG("daemon started — pid=" + std::to_string(getpid()));

  // Initialise libnotify.
  if (!notify_init(kAppName)) {
    LOG("WARNING: notify_init failed — notifications may not appear");
  }

  // Initialise libcurl globally (once per process).
  curl_global_init(CURL_GLOBAL_DEFAULT);

  polling_loop();

  curl_global_cleanup();
  if (notify_is_initted()) notify_uninit();

  LOG("daemon exiting");
  return 0;
}
