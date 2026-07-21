// notification_master background poller daemon — macOS
//
// Standalone Swift CLI executable launched by the Flutter plugin via
// startBackgroundPollingService(). Keeps polling an HTTP endpoint and showing
// macOS User Notifications (UNUserNotificationCenter) even after the main
// Flutter app closes, because it runs in its own process.
//
// Config is stored in UserDefaults suite "com.notification-master.poller":
//   nm_bg_poll_url      : String  – HTTP(S) endpoint
//   nm_bg_poll_interval : Int     – polling interval in minutes (default 15)
//   nm_bg_poll_enabled  : Bool    – set to false by stopBackgroundPollingService
//
// Log is written next to this executable: notification_master_poller.log
//
// Build: added as an executableTarget "notification_master_poller" in
// macos/notification_master/Package.swift (see CMakeLists for copy step).

import Foundation
import UserNotifications

// MARK: - Constants

let kSuite      = "com.notification-master.poller"
let kUrlKey     = "nm_bg_poll_url"
let kIntervalKey = "nm_bg_poll_interval"
let kEnabledKey  = "nm_bg_poll_enabled"
let kLastRunKey  = "nm_bg_poll_last_run"
let kLastErrKey  = "nm_bg_poll_last_error"
let kDedupeWindowSec: TimeInterval = 3600 // 1 hour

// MARK: - Logging

var logFileHandle: FileHandle?

func setupLog() {
    let exe = URL(fileURLWithPath: CommandLine.arguments[0])
    let dir = exe.deletingLastPathComponent()
    let logURL = dir.appendingPathComponent("notification_master_poller.log")
    if !FileManager.default.fileExists(atPath: logURL.path) {
        FileManager.default.createFile(atPath: logURL.path, contents: nil)
    }
    logFileHandle = try? FileHandle(forWritingTo: logURL)
    logFileHandle?.seekToEndOfFile()
}

func nmLog(_ msg: String) {
    let df = DateFormatter()
    df.dateFormat = "HH:mm:ss.SSS"
    let ts = df.string(from: Date())
    let line = "[NM-POLLER] [\(ts)] \(msg)\n"
    if let data = line.data(using: .utf8) {
        logFileHandle?.write(data)
    }
    fputs(line, stderr)
}

// MARK: - Config (UserDefaults shared suite)

let defaults = UserDefaults(suiteName: kSuite)!

func readConf(_ key: String) -> String {
    return defaults.string(forKey: key) ?? ""
}

func writeConf(_ key: String, _ value: String) {
    defaults.set(value, forKey: key)
    defaults.synchronize()
}

// MARK: - Deduplication

var dedupeSeen: [String: Date] = [:]
let dedupeLock = NSLock()

func shouldShow(title: String, body: String) -> Bool {
    let key = "\(title)\0\(body)"
    dedupeLock.lock()
    defer { dedupeLock.unlock() }
    if let last = dedupeSeen[key], Date().timeIntervalSince(last) < kDedupeWindowSec {
        return false
    }
    dedupeSeen[key] = Date()
    return true
}

// MARK: - Show notification

func showNotification(title: String, body: String) {
    guard shouldShow(title: title, body: body) else {
        nmLog("showNotification: SKIPPED (already shown recently): title='\(title)'")
        return
    }

    let content = UNMutableNotificationContent()
    content.title = title
    content.body  = body.isEmpty ? title : body
    content.sound = .default

    let id  = "nm_daemon_\(Date().timeIntervalSince1970)_\(title.hashValue)"
    let req = UNNotificationRequest(identifier: id, content: content, trigger: nil)

    // UNUserNotificationCenter requires an authorised app. From a background
    // daemon that has no bundle ID we use the system notification API via
    // NSUserNotificationCenter (deprecated but works for menu-bar-less helpers)
    // as a fallback when the UNUserNotificationCenter delegate cannot be set up.
    let center = UNUserNotificationCenter.current()
    let sema   = DispatchSemaphore(value: 0)
    center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
        if granted {
            center.add(req) { err in
                if let err = err {
                    nmLog("showNotification: UNError: \(err.localizedDescription)")
                }
            }
        } else {
            nmLog("showNotification: permission not granted — trying osascript fallback")
            // Fallback: use osascript (display notification) which works without
            // a proper app bundle and does not require UNUserNotificationCenter auth.
            let escaped_title = title.replacingOccurrences(of: "\"", with: "\\\"")
            let escaped_body  = body.replacingOccurrences(of:  "\"", with: "\\\"")
            let script = "display notification \"\(escaped_body)\" with title \"\(escaped_title)\""
            let proc = Process()
            proc.launchPath = "/usr/bin/osascript"
            proc.arguments  = ["-e", script]
            proc.launch()
        }
        sema.signal()
    }
    sema.wait()

    nmLog("showNotification: title='\(title)' body='\(body)'")
}

// MARK: - HTTP GET

func httpGet(urlString: String) -> String? {
    guard let url = URL(string: urlString) else {
        nmLog("httpGet: invalid URL: \(urlString)")
        return nil
    }
    var result: String?
    let sema = DispatchSemaphore(value: 0)
    let task = URLSession.shared.dataTask(with: url) { data, _, error in
        if let error = error {
            nmLog("httpGet: error: \(error.localizedDescription)")
        } else if let data = data {
            result = String(data: data, encoding: .utf8)
        }
        sema.signal()
    }
    task.resume()
    sema.wait()
    return result
}

// MARK: - JSON parse + show

func parseAndShow(_ jsonString: String) {
    guard let data = jsonString.data(using: .utf8),
          let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
        nmLog("parseAndShow: JSON parse failed")
        return
    }

    // Format 1: {"notifications": [...]}
    if let notifs = root["notifications"] as? [[String: Any]] {
        nmLog("parseAndShow: found \(notifs.count) notification(s)")
        for n in notifs {
            let title = (n["title"] as? String) ?? ""
            let msg   = (n["message"] as? String) ?? ""
            let big   = (n["bigText"] as? String) ?? ""
            let t = title.isEmpty ? msg : title
            let b = big.isEmpty   ? msg : big
            if !t.isEmpty || !b.isEmpty { showNotification(title: t, body: b) }
        }
        return
    }

    // Format 2: {"data": {...}}
    if let data_obj = root["data"] as? [String: Any] {
        let title = (data_obj["title"]   as? String) ?? ""
        let msg   = (data_obj["message"] as? String) ?? ""
        let big   = (data_obj["bigText"] as? String) ?? ""
        let t = title.isEmpty ? msg : title
        let b = big.isEmpty   ? msg : big
        if !t.isEmpty || !b.isEmpty { showNotification(title: t, body: b) }
    }
}

// MARK: - Polling loop

func pollingLoop() {
    nmLog("pollingLoop: started — pid=\(ProcessInfo.processInfo.processIdentifier)")

    while true {
        let enabled  = readConf(kEnabledKey)
        if enabled == "0" {
            nmLog("pollingLoop: enabled=0 — exiting")
            break
        }

        let url      = readConf(kUrlKey)
        let ivStr    = readConf(kIntervalKey)
        let interval = Int(ivStr) ?? 15
        let sleepSec = max(1, interval) * 60

        if url.isEmpty {
            nmLog("pollingLoop: no url configured — waiting")
        } else {
            nmLog("pollingLoop: requesting \(url)")
            if let resp = httpGet(urlString: url) {
                nmLog("pollingLoop: got \(resp.count) bytes")
                parseAndShow(resp)
                writeConf(kLastRunKey, "\(Int(Date().timeIntervalSince1970))")
                writeConf(kLastErrKey, "")
            } else {
                nmLog("pollingLoop: empty/failed response")
                writeConf(kLastErrKey, "empty response")
            }
        }

        // Sleep in 1-second slices so we react to enabled=0 quickly.
        for _ in 0..<sleepSec {
            Thread.sleep(forTimeInterval: 1)
            if readConf(kEnabledKey) == "0" {
                nmLog("pollingLoop: enabled cleared — stopping")
                return
            }
        }
    }

    nmLog("pollingLoop: exited")
}

// MARK: - Entry point

setupLog()
nmLog("daemon starting")

// Accept --url and --interval CLI args so the plugin can pass config directly.
var args = CommandLine.arguments.dropFirst()
while args.count >= 2 {
    let flag = args.removeFirst()
    let val  = args.removeFirst()
    switch flag {
    case "--url":      writeConf(kUrlKey, val)
    case "--interval": writeConf(kIntervalKey, val)
    default: break
    }
}
writeConf(kEnabledKey, "1")

// Handle SIGTERM cleanly.
signal(SIGTERM) { _ in
    UserDefaults(suiteName: kSuite)?.set("0", forKey: kEnabledKey)
    UserDefaults(suiteName: kSuite)?.synchronize()
    exit(0)
}

pollingLoop()
nmLog("daemon exiting")
