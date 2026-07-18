// notification_master background poller daemon.
//
// This is a STANDALONE console executable. It is launched by the Flutter plugin
// (via startBackgroundPollingService) and keeps polling an HTTP endpoint and
// showing Windows toast notifications even after the main app is fully closed,
// because it runs in its own process.
//
// It reads its configuration (url + interval) from the registry, polls on a
// timer, parses the JSON response the same way the plugin does, and raises a
// toast for each notification. All activity is written to a log file placed
// NEXT TO THIS EXECUTABLE (notification_master_poller.log) so background
// behaviour can be diagnosed without the app running.
//
// Build: linked into the plugin CMakeLists.txt as a separate executable that
// reuses wintoastlib.cpp.

#define _SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS
#define NOMINMAX

#include <windows.h>
#include <shlwapi.h>
#include <string>
#include <vector>
#include <map>
#include <thread>
#include <chrono>
#include <atomic>
#include <mutex>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <iostream>
#include <winhttp.h>
#include <locale>
#include <codecvt>

#include "wintoastlib.h"
#include "nm_registry_config.h"

#pragma comment(lib, "winhttp.lib")
#pragma comment(lib, "windowsapp.lib")
#pragma comment(lib, "runtimeobject.lib")
#pragma comment(lib, "shlwapi.lib")

namespace {

using namespace WinToastLib;

std::string ToString(const std::wstring& w);  // forward decl (defined below)
void ShowFromJson(const std::map<std::string, std::string>& data);  // fwd
long long ToUnixMillis();  // fwd

// --- Logging -------------------------------------------------------------
// Writes to a file next to the executable AND to OutputDebugString.
class Logger {
 public:
  static Logger& instance() {
    static Logger inst;
    return inst;
  }

  void log(const std::wstring& msg) {
    std::lock_guard<std::mutex> lock(mutex_);
    std::wstring line = timestamp() + L" " + msg;
    OutputDebugStringW((line + L"\n").c_str());
    if (file_.is_open()) {
      file_ << "[NM-POLLER] " << ToString(line) << "\n";
      file_.flush();
    }
  }

 private:
  Logger() {
    // Place the log NEXT TO the executable (per user preference).
    wchar_t exePath[MAX_PATH] = {0};
    if (GetModuleFileNameW(nullptr, exePath, MAX_PATH) > 0) {
      std::filesystem::path p(exePath);
      auto logPath = p.parent_path() / L"notification_master_poller.log";
      file_.open(logPath, std::ios::out | std::ios::app);
    }
    // Fallback to temp if for some reason we could not open next to exe.
    if (!file_.is_open()) {
      wchar_t tmp[MAX_PATH] = {0};
      GetTempPathW(MAX_PATH, tmp);
      std::filesystem::path p(tmp);
      p /= L"notification_master_poller.log";
      file_.open(p, std::ios::out | std::ios::app);
    }
  }

  ~Logger() {
    if (file_.is_open()) file_.close();
  }

  std::wstring timestamp() {
    SYSTEMTIME st;
    GetLocalTime(&st);
    wchar_t buf[64];
    swprintf_s(buf, L"[%02d:%02d:%02d.%03d]", st.wHour, st.wMinute, st.wSecond,
               st.wMilliseconds);
    return buf;
  }

  std::mutex mutex_;
  std::ofstream file_;
};

#define LOG(...) Logger::instance().log(__VA_ARGS__)

std::wstring ToWString(const std::string& s) {
  if (s.empty()) return L"";
  int n = MultiByteToWideChar(CP_UTF8, 0, s.c_str(), (int)s.size(), nullptr, 0);
  std::wstring out(n, 0);
  MultiByteToWideChar(CP_UTF8, 0, s.c_str(), (int)s.size(), &out[0], n);
  return out;
}

std::string ToString(const std::wstring& w) {
  if (w.empty()) return "";
  int n = WideCharToMultiByte(CP_UTF8, 0, w.c_str(), (int)w.size(), nullptr, 0,
                              nullptr, nullptr);
  std::string out(n, 0);
  WideCharToMultiByte(CP_UTF8, 0, w.c_str(), (int)w.size(), &out[0], n, nullptr,
                      nullptr);
  return out;
}

// --- Registry helpers ----------------------------------------------------
std::wstring ReadRegString(const wchar_t* name) {
  HKEY hKey = nullptr;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, nm_config::kRegistryPath, 0, KEY_READ,
                    &hKey) != ERROR_SUCCESS)
    return L"";
  DWORD type = REG_SZ, size = 0;
  if (RegQueryValueExW(hKey, name, nullptr, &type, nullptr, &size) !=
          ERROR_SUCCESS ||
      type != REG_SZ || size == 0) {
    RegCloseKey(hKey);
    return L"";
  }
  std::wstring value(size / sizeof(wchar_t), L'\0');
  RegQueryValueExW(hKey, name, nullptr, &type,
                   reinterpret_cast<LPBYTE>(&value[0]), &size);
  RegCloseKey(hKey);
  if (!value.empty() && value.back() == L'\0') value.pop_back();
  return value;
}

void WriteRegString(const wchar_t* name, const std::wstring& value) {
  HKEY hKey = nullptr;
  RegCreateKeyExW(HKEY_CURRENT_USER, nm_config::kRegistryPath, 0, nullptr,
                  REG_OPTION_NON_VOLATILE, KEY_WRITE, nullptr, &hKey, nullptr);
  if (!hKey) return;
  RegSetValueExW(hKey, name, 0, REG_SZ,
                 reinterpret_cast<const BYTE*>(value.c_str()),
                 static_cast<DWORD>((value.size() + 1) * sizeof(wchar_t)));
  RegCloseKey(hKey);
}

// --- JSON parsing (minimal, matches plugin behaviour) --------------------
std::map<std::string, std::string> ParseNotificationObject(
    const std::string& objStr) {
  std::map<std::string, std::string> d;
  auto extract = [&](const std::string& key) -> std::string {
    size_t p = objStr.find("\"" + key + "\"");
    if (p == std::string::npos) return "";
    size_t colon = objStr.find(':', p);
    if (colon == std::string::npos) return "";
    size_t q = objStr.find('"', colon);
    if (q == std::string::npos) return "";
    size_t e = objStr.find('"', q + 1);
    if (e == std::string::npos) return "";
    return objStr.substr(q + 1, e - q - 1);
  };
  d["title"] = extract("title");
  d["message"] = extract("message");
  d["bigText"] = extract("bigText");
  d["imageUrl"] = extract("imageUrl");
  return d;
}

void ParseAndShow(const std::string& json) {
  // Format 1: {"notifications":[ {...}, {...} ]}
  size_t pos = json.find("\"notifications\"");
  if (pos != std::string::npos) {
    size_t arr = json.find('[', pos);
    if (arr != std::string::npos) {
      size_t cur = arr + 1;
      while (cur < json.size()) {
        size_t o = json.find('{', cur);
        if (o == std::string::npos) break;
        size_t e = json.find('}', o);
        if (e == std::string::npos) break;
        auto data = ParseNotificationObject(json.substr(o, e - o + 1));
        if (!data.empty()) ShowFromJson(data);
        cur = e + 1;
      }
      return;
    }
  }
  // Format 2: {"data": {...}}
  size_t dp = json.find("\"data\"");
  if (dp != std::string::npos) {
    size_t o = json.find('{', dp);
    if (o != std::string::npos) {
      int depth = 0;
      size_t e = o;
      for (size_t i = o; i < json.size(); ++i) {
        if (json[i] == '{')
          ++depth;
        else if (json[i] == '}') {
          --depth;
          if (depth == 0) {
            e = i;
            break;
          }
        }
      }
      auto data = ParseNotificationObject(json.substr(o, e - o + 1));
      if (!data.empty()) ShowFromJson(data);
    }
  }
}

// --- WinToast handler ----------------------------------------------------
class Handler : public IWinToastHandler {
 public:
  void toastActivated() const override {}
  void toastActivated(int) const override {}
  void toastActivated(std::wstring) const override {}
  void toastDismissed(WinToastDismissalReason) const override {}
  void toastFailed() const override {}
};

void ShowFromJson(const std::map<std::string, std::string>& data) {
  std::string title = data.count("title") ? data.at("title") : "";
  std::string message = data.count("message") ? data.at("message") : "";
  if (title.empty() && message.empty()) return;
  if (title.empty()) title = message;
  if (message.empty()) message = title;

  WinToastTemplate templ(WinToastTemplate::Text02);
  templ.setTextField(ToWString(title), WinToastTemplate::FirstLine);
  templ.setTextField(ToWString(message), WinToastTemplate::SecondLine);

  auto big = data.find("bigText");
  if (big != data.end() && !big->second.empty()) {
    templ = WinToastTemplate(WinToastTemplate::Text03);
    templ.setTextField(ToWString(title), WinToastTemplate::FirstLine);
    templ.setTextField(ToWString(big->second), WinToastTemplate::SecondLine);
  }

  auto img = data.find("imageUrl");
  if (img != data.end() && !img->second.empty()) {
    templ = WinToastTemplate(WinToastTemplate::ImageAndText02);
    templ.setTextField(ToWString(title), WinToastTemplate::FirstLine);
    templ.setTextField(ToWString(message), WinToastTemplate::SecondLine);
    templ.setImagePath(ToWString(img->second));
  }

  WinToast::WinToastError err;
  INT64 id = WinToast::instance()->showToast(templ, new Handler(), &err);
  LOG(L"ShowFromJson: title='" + ToWString(title) + L"' result=" +
      std::to_wstring(id) + L" err=" + std::to_wstring((int)err));
}

// --- HTTP GET (WinHTTP) --------------------------------------------------
std::wstring HttpGet(const std::wstring& url) {
  std::wstring result;
  URL_COMPONENTS uc = {0};
  uc.dwStructSize = sizeof(uc);
  uc.dwSchemeLength = (DWORD)-1;
  uc.dwHostNameLength = (DWORD)-1;
  uc.dwUrlPathLength = (DWORD)-1;
  uc.dwExtraInfoLength = (DWORD)-1;
  wchar_t scheme[32] = {0}, host[256] = {0}, path[1024] = {0}, extra[256] = {0};
  uc.lpszScheme = scheme;
  uc.lpszHostName = host;
  uc.lpszUrlPath = path;
  uc.lpszExtraInfo = extra;
  if (!WinHttpCrackUrl(url.c_str(), (DWORD)url.size(), 0, &uc)) {
    LOG(L"HttpGet: WinHttpCrackUrl failed for " + url);
    return result;
  }

  HINTERNET s = WinHttpOpen(L"NotificationMasterPoller/1.0",
                            WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
                            WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, 0);
  if (!s) return result;
  HINTERNET c = WinHttpConnect(s, host, uc.nPort, 0);
  if (!c) {
    WinHttpCloseHandle(s);
    return result;
  }
  std::wstring full = std::wstring(path) + std::wstring(extra);
  HINTERNET r = WinHttpOpenRequest(
      c, L"GET", full.c_str(), nullptr, WINHTTP_NO_REFERER,
      WINHTTP_DEFAULT_ACCEPT_TYPES,
      uc.nScheme == INTERNET_SCHEME_HTTPS ? WINHTTP_FLAG_SECURE : 0);
  if (!r) {
    WinHttpCloseHandle(c);
    WinHttpCloseHandle(s);
    return result;
  }
  if (!WinHttpSendRequest(r, WINHTTP_NO_ADDITIONAL_HEADERS, 0,
                          WINHTTP_NO_REQUEST_DATA, 0, 0, 0) ||
      !WinHttpReceiveResponse(r, nullptr)) {
    WinHttpCloseHandle(r);
    WinHttpCloseHandle(c);
    WinHttpCloseHandle(s);
    return result;
  }
  DWORD avail = 0, read = 0;
  std::vector<char> buf;
  while (WinHttpQueryDataAvailable(r, &avail) && avail > 0) {
    size_t cur = buf.size();
    buf.resize(cur + avail);
    if (!WinHttpReadData(r, &buf[cur], avail, &read)) break;
    if (read < avail) buf.resize(cur + read);
  }
  WinHttpCloseHandle(r);
  WinHttpCloseHandle(c);
  WinHttpCloseHandle(s);
  if (!buf.empty()) {
    int n = MultiByteToWideChar(CP_UTF8, 0, &buf[0], (int)buf.size(), nullptr, 0);
    result.resize(n);
    MultiByteToWideChar(CP_UTF8, 0, &buf[0], (int)buf.size(), &result[0], n);
  }
  return result;
}

// --- Polling loop --------------------------------------------------------
std::atomic<bool> g_running{true};

void PollOnce(const std::wstring& url) {
  LOG(L"PollOnce: requesting " + url);
  std::wstring resp = HttpGet(url);
  if (resp.empty()) {
    LOG(L"PollOnce: empty response (request failed)");
    WriteRegString(nm_config::kBgPollLastErr, L"empty response");
    return;
  }
  std::string s = ToString(resp);
  LOG(L"PollOnce: got " + std::to_wstring(s.size()) + L" bytes");
  ParseAndShow(s);
  WriteRegString(nm_config::kBgPollLastRun,
                 std::to_wstring(ToUnixMillis()));
  WriteRegString(nm_config::kBgPollLastErr, L"");
}

long long ToUnixMillis() {
  FILETIME ft;
  GetSystemTimeAsFileTime(&ft);
  ULARGE_INTEGER li;
  li.LowPart = ft.dwLowDateTime;
  li.HighPart = ft.dwHighDateTime;
  // 100ns ticks since 1601; epoch delta to 1970 is 11644473600 seconds.
  return (long long)(li.QuadPart / 10000ULL) - 11644473600000LL;
}

void PollingLoop() {
  while (g_running.load()) {
    std::wstring url = ReadRegString(nm_config::kBgPollUrl);
    int interval = 15;
    std::wstring iv = ReadRegString(nm_config::kBgPollInterval);
    if (!iv.empty()) interval = _wtoi(iv.c_str());
    if (interval <= 0) interval = 15;

    if (!url.empty()) {
      try {
        PollOnce(url);
      } catch (const std::exception& ex) {
        LOG(L"PollOnce exception: " + ToWString(ex.what()));
      }
    } else {
      LOG(L"PollingLoop: no url configured, stopping");
      break;
    }

    // Sleep in 1s chunks so we can react to shutdown quickly.
    for (int i = 0; i < interval * 60 && g_running.load(); ++i) {
      std::this_thread::sleep_for(std::chrono::seconds(1));
    }
  }
  LOG(L"PollingLoop: exited");
}

}  // namespace

int wmain(int argc, wchar_t* argv[]) {
  // Initialize COM (apartment threaded) for WinToast / WinRT.
  HRESULT hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  if (FAILED(hr)) {
    Logger::instance().log(L"CoInitializeEx FAILED hr=" +
                            std::to_wstring(hr));
  }

  // Configure WinToast with the SAME AUMI the plugin uses so toasts show up
  // under the same Start Menu shortcut.
  WinToast::instance()->setAppName(nm_config::kProductName);
  std::wstring aumi = WinToast::configureAUMI(
      nm_config::kCompanyName, nm_config::kProductName, nm_config::kSubProduct,
      nm_config::kVersionInfo);
  WinToast::instance()->setAppUserModelId(aumi);
  WinToast::WinToastError err;
  if (!WinToast::instance()->initialize(&err)) {
    // Retry without requiring a shortcut (e.g. during dev / flutter run).
    WinToast::instance()->setShortcutPolicy(WinToast::SHORTCUT_POLICY_IGNORE);
    WinToast::instance()->initialize(&err);
  }
  LOG(L"Daemon started. AUMI=" + aumi);

  // Mark enabled so the plugin sees us running.
  WriteRegString(nm_config::kBgPollEnabled, L"1");

  // Spawn the polling loop on a worker thread.
  std::thread loop(PollingLoop);

  // Wait for a quit signal (Ctrl+C / console close / process kill).
  // Also stop if the registry is cleared by the plugin.
  while (g_running.load()) {
    std::wstring enabled = ReadRegString(nm_config::kBgPollEnabled);
    if (enabled != L"1") {
      LOG(L"Daemon: bg_poll_enabled cleared, shutting down");
      g_running.store(false);
      break;
    }
    std::this_thread::sleep_for(std::chrono::seconds(2));
  }

  g_running.store(false);
  if (loop.joinable()) loop.join();

  WriteRegString(nm_config::kBgPollEnabled, L"0");
  LOG(L"Daemon stopped.");
  if (SUCCEEDED(hr)) CoUninitialize();
  return 0;
}
