#ifndef NM_REGISTRY_CONFIG_H_
#define NM_REGISTRY_CONFIG_H_

// Shared registry layout used by BOTH the Flutter plugin
// (notification_master_plugin.cpp) and the standalone background poller daemon
// (nm_background_poller.cpp). Keeping it in one place guarantees the daemon and
// the app agree on where the polling configuration lives.
//
// Everything lives under HKCU\SOFTWARE\NotificationMaster\notification_master
// (the same key the plugin already uses for scheduled notifications and topics).

namespace nm_config {

// Root registry path (HKCU). Mirrors kRegistryPath in the plugin.
static const wchar_t* kRegistryPath =
    L"SOFTWARE\\NotificationMaster\\notification_master";

// --- Background polling service configuration ---
// "bg_poll_url"     REG_SZ   : HTTP(S) endpoint returning JSON notifications.
// "bg_poll_interval"REG_SZ   : interval in minutes (stored as text).
// "bg_poll_enabled" REG_SZ   : "1" when the daemon should be running, "0" off.
// "bg_poll_last_run"REG_SZ   : last successful poll epoch millis (diagnostics).
// "bg_poll_last_err"REG_SZ   : last error message (diagnostics / logging).
static const wchar_t* kBgPollUrl        = L"bg_poll_url";
static const wchar_t* kBgPollInterval   = L"bg_poll_interval";
static const wchar_t* kBgPollEnabled    = L"bg_poll_enabled";
static const wchar_t* kBgPollLastRun    = L"bg_poll_last_run";
static const wchar_t* kBgPollLastErr    = L"bg_poll_last_err";

// The AUMI the daemon must register so its toasts display. Must match the AUMI
// the plugin configures (NotificationMaster / NotificationMaster /
// NotificationMaster / 1.0.0). See WinToast::configureAUMI in the plugin.
static const wchar_t* kCompanyName    = L"NotificationMaster";
static const wchar_t* kProductName    = L"NotificationMaster";
static const wchar_t* kSubProduct     = L"NotificationMaster";
static const wchar_t* kVersionInfo    = L"1.0.0";

}  // namespace nm_config

#endif  // NM_REGISTRY_CONFIG_H_
