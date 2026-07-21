import Cocoa
import FlutterMacOS
import UserNotifications

// MARK: - Plugin

public class NotificationMasterPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
  private static let channelName = "notification_master"
  private static let prefsPollingUrl = "polling_url"
  private static let prefsPollingInterval = "polling_interval_minutes"
  private static let prefsActiveService = "active_notification_service"
  private static let defaultIntervalMinutes = 15
  private static let scheduledPrefix = "nm_sched_"

  private var channel: FlutterMethodChannel?

  /// Service type — mirrors the Dart-side string contract exactly.
  private enum ServiceType: String {
    case none = "none"
    case polling = "polling"
    case foreground = "foreground"
    case firebase = "firebase"
  }

  /// In-process polling timer (macOS has no BGTaskScheduler equivalent).
  private var pollingTimer: Timer?
  private var isPollingActive = false

  // Background daemon (notification_master_poller binary)
  private var daemonProcess: Process?
  private static let kSuite      = "com.notification-master.poller"
  private static let kUrlKey     = "nm_bg_poll_url"
  private static let kIntervalKey = "nm_bg_poll_interval"
  private static let kEnabledKey  = "nm_bg_poll_enabled"

  // MARK: - Registration

  public static func register(with registrar: FlutterPluginRegistrar) {
    let ch = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger)
    let instance = NotificationMasterPlugin()
    instance.channel = ch
    registrar.addMethodCallDelegate(instance, channel: ch)

    // Become UNUserNotificationCenter delegate so notifications show while
    // the app is in the foreground.
    UNUserNotificationCenter.current().delegate = instance
  }

  // MARK: - Method Channel Dispatch

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {

    // ── Meta ────────────────────────────────────────────────────────────────
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)

    // ── Permissions ─────────────────────────────────────────────────────────
    case "requestNotificationPermission":
      requestNotificationPermission(result: result)

    case "checkNotificationPermission":
      checkNotificationPermission(result: result)

    // Android-only gates — always true / no-op on macOS.
    case "canScheduleExactAlarms":
      result(true)

    case "openExactAlarmSettings":
      result(false)

    case "openAppNotificationSettings":
      // Open System Settings → Notifications on macOS 13+; silently no-op earlier.
      if #available(macOS 13.0, *) {
        NSWorkspace.shared.open(
          URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!
        )
      }
      result(true)

    // ── Notification Display ─────────────────────────────────────────────────
    case "showNotification":
      showNotification(call: call, result: result)

    case "showBigTextNotification":
      showBigTextNotification(call: call, result: result)

    case "showImageNotification":
      showImageNotification(call: call, result: result)

    case "showNotificationWithActions":
      showNotificationWithActions(call: call, result: result)

    case "showHeadsUpNotification",
         "showFullScreenNotification",
         "showStyledNotification":
      // macOS has no heads-up / full-screen / styled distinction — show a
      // standard banner with the highest sound level.
      showNotification(call: call, result: result)

    // ── Channels (stub — macOS has no Android-style channels) ───────────────
    case "createCustomChannel":
      result(true)

    // ── Remote Services ──────────────────────────────────────────────────────
    case "startNotificationPolling":
      startNotificationPolling(call: call, result: result)

    case "stopNotificationPolling":
      stopNotificationPolling(result: result)

    case "startForegroundService":
      startForegroundService(call: call, result: result)

    case "stopForegroundService":
      stopForegroundService(result: result)

    case "setFirebaseAsActiveService":
      setFirebaseAsActiveService(result: result)

    case "getActiveNotificationService":
      getActiveNotificationService(result: result)

    // ── Device Token & Topics ────────────────────────────────────────────────
    case "getDeviceToken":
      getDeviceToken(result: result)

    case "subscribeToTopic":
      guard let args = call.arguments as? [String: Any],
            let topic = args["topic"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "topic is required", details: nil))
        return
      }
      subscribeToTopic(topic, result: result)

    case "unsubscribeFromTopic":
      guard let args = call.arguments as? [String: Any],
            let topic = args["topic"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "topic is required", details: nil))
        return
      }
      unsubscribeFromTopic(topic, result: result)

    case "getSubscribedTopics":
      getSubscribedTopics(result: result)

    // ── Scheduled Notifications ──────────────────────────────────────────────
    case "scheduleNotification":
      scheduleNotification(call: call, result: result)

    case "cancelScheduledNotification":
      guard let args = call.arguments as? [String: Any], let id = args["id"] as? Int else {
        result(FlutterError(code: "INVALID_ARGS", message: "id required", details: nil))
        return
      }
      cancelScheduledNotification(id: id)
      result(true)

    case "cancelAllScheduledNotifications":
      cancelAllScheduledNotifications()
      result(true)

    case "getPendingScheduledNotifications":
      getPendingScheduledNotifications { ids in result(ids) }

    // Background daemon (notification_master_poller) — macOS implementation.
    // Launches a standalone Swift executable next to the app bundle that keeps
    // polling even after the main app closes.
    case "startBackgroundPollingService":
      startBackgroundDaemon(call: call, result: result)

    case "stopBackgroundPollingService":
      stopBackgroundDaemon(result: result)

    case "isBackgroundPollingRunning":
      result(isBackgroundDaemonRunning())

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Permissions

  private func requestNotificationPermission(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current()
      .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
        DispatchQueue.main.async { result(granted) }
      }
  }

  private func checkNotificationPermission(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      DispatchQueue.main.async {
        let ok = settings.authorizationStatus == .authorized
               || settings.authorizationStatus == .provisional
        result(ok)
      }
    }
  }

  // MARK: - Notification Display

  private func showNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let title = args["title"] as? String,
          let message = args["message"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "title and message required", details: nil))
      return
    }
    let id = args["id"] as? Int ?? Int.random(in: 1..<Int.max)
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = message
    content.sound = .default

    var userInfo: [String: Any] = [:]
    if let ts = args["targetScreen"] as? String { userInfo["targetScreen"] = ts }
    if let ed = args["extraData"] as? [String: Any] { userInfo["extraData"] = ed }
    content.userInfo = userInfo

    let request = UNNotificationRequest(identifier: "\(id)", content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request) { err in
      DispatchQueue.main.async { result(err == nil ? id : -1) }
    }
  }

  private func showBigTextNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let title = args["title"] as? String,
          let message = args["message"] as? String,
          let bigText = args["bigText"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "title, message, bigText required", details: nil))
      return
    }
    let id = Int.random(in: 1..<Int.max)
    let content = UNMutableNotificationContent()
    content.title = title
    // Show bigText as the body (most visible); keep original message as subtitle.
    content.subtitle = message
    content.body = bigText.isEmpty ? message : bigText
    content.sound = .default

    var userInfo: [String: Any] = [:]
    if let ts = args["targetScreen"] as? String { userInfo["targetScreen"] = ts }
    if let ed = args["extraData"] as? [String: Any] { userInfo["extraData"] = ed }
    content.userInfo = userInfo

    let request = UNNotificationRequest(identifier: "\(id)", content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request) { err in
      DispatchQueue.main.async { result(err == nil ? id : -1) }
    }
  }

  private func showImageNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let title = args["title"] as? String,
          let message = args["message"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "title and message required", details: nil))
      return
    }
    let id = Int.random(in: 1..<Int.max)
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = message
    content.sound = .default

    var userInfo: [String: Any] = [:]
    if let ts = args["targetScreen"] as? String { userInfo["targetScreen"] = ts }
    if let ed = args["extraData"] as? [String: Any] { userInfo["extraData"] = ed }
    content.userInfo = userInfo

    // Attempt to attach the image. For remote URLs the image must be downloaded
    // first; skip attachment on failure (notification still shows text).
    if let urlString = args["imageUrl"] as? String, let imageURL = URL(string: urlString) {
      downloadToTemp(url: imageURL) { tempURL in
        if let tempURL = tempURL,
           let attachment = try? UNNotificationAttachment(
             identifier: "img_\(id)", url: tempURL, options: nil) {
          content.attachments = [attachment]
        }
        let req = UNNotificationRequest(identifier: "\(id)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req) { err in
          DispatchQueue.main.async { result(err == nil ? id : -1) }
        }
      }
    } else {
      let req = UNNotificationRequest(identifier: "\(id)", content: content, trigger: nil)
      UNUserNotificationCenter.current().add(req) { err in
        DispatchQueue.main.async { result(err == nil ? id : -1) }
      }
    }
  }

  private func showNotificationWithActions(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let title = args["title"] as? String,
          let message = args["message"] as? String,
          let actions = args["actions"] as? [[String: String]] else {
      result(FlutterError(code: "INVALID_ARGS", message: "title, message, actions required", details: nil))
      return
    }
    let id = Int.random(in: 1..<Int.max)
    let catId = "nm_actions_\(id)"

    let content = UNMutableNotificationContent()
    content.title = title
    content.body = message
    content.sound = .default
    content.categoryIdentifier = catId

    var userInfo: [String: Any] = [:]
    if let ts = args["targetScreen"] as? String { userInfo["targetScreen"] = ts }
    if let ed = args["extraData"] as? [String: Any] { userInfo["extraData"] = ed }
    content.userInfo = userInfo

    var unActions: [UNNotificationAction] = []
    for (idx, act) in actions.prefix(4).enumerated() {
      if let actionTitle = act["title"] {
        let route = act["route"] ?? ""
        unActions.append(UNNotificationAction(
          identifier: "ACTION_\(idx)_\(route)",
          title: actionTitle,
          options: [.foreground]
        ))
      }
    }

    let category = UNNotificationCategory(
      identifier: catId, actions: unActions,
      intentIdentifiers: [], options: [])
    UNUserNotificationCenter.current().getNotificationCategories { existing in
      var all = existing
      all.insert(category)
      UNUserNotificationCenter.current().setNotificationCategories(all)

      let req = UNNotificationRequest(identifier: "\(id)", content: content, trigger: nil)
      UNUserNotificationCenter.current().add(req) { err in
        DispatchQueue.main.async { result(err == nil ? id : -1) }
      }
    }
  }

  private func downloadToTemp(url: URL, completion: @escaping (URL?) -> Void) {
    URLSession.shared.downloadTask(with: url) { localURL, _, _ in
      guard let localURL = localURL else { completion(nil); return }
      let dest = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension(url.pathExtension.isEmpty ? "jpg" : url.pathExtension)
      do {
        try FileManager.default.moveItem(at: localURL, to: dest)
        completion(dest)
      } catch {
        completion(nil)
      }
    }.resume()
  }

  // MARK: - Background Daemon (notification_master_poller)

  /// Locate the daemon binary. It is placed next to the .app bundle by the
  /// build system (CMakeLists.txt copy step / flutter_build hook).
  private func daemonPath() -> String? {
    // Option A: next to the running executable (works for flutter run / debug).
    let exe = Bundle.main.executablePath ?? ""
    let dir = (exe as NSString).deletingLastPathComponent
    let candidate = (dir as NSString).appendingPathComponent("notification_master_poller")
    if FileManager.default.isExecutableFile(atPath: candidate) { return candidate }

    // Option B: in the app bundle's Resources.
    if let bundled = Bundle.main.path(forResource: "notification_master_poller",
                                      ofType: nil) { return bundled }
    return nil
  }

  private func daemonDefaults() -> UserDefaults {
    return UserDefaults(suiteName: NotificationMasterPlugin.kSuite)
        ?? UserDefaults.standard
  }

  private func startBackgroundDaemon(call: FlutterMethodCall,
                                     result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let url  = args["pollingUrl"] as? String, !url.isEmpty else {
      result(FlutterError(code: "INVALID_ARGUMENT",
                          message: "pollingUrl is required", details: nil))
      return
    }
    let interval = args["intervalMinutes"] as? Int ?? 15

    // Already running? Update config and return true.
    if isBackgroundDaemonRunning() {
      let ud = daemonDefaults()
      ud.set(url,               forKey: NotificationMasterPlugin.kUrlKey)
      ud.set("\(interval)",     forKey: NotificationMasterPlugin.kIntervalKey)
      ud.synchronize()
      result(true)
      return
    }

    guard let path = daemonPath() else {
      result(FlutterError(
        code: "DAEMON_NOT_FOUND",
        message: "notification_master_poller not found next to the app executable. "
               + "Make sure the plugin was built with the daemon target.",
        details: nil))
      return
    }

    let ud = daemonDefaults()
    ud.set(url,           forKey: NotificationMasterPlugin.kUrlKey)
    ud.set("\(interval)", forKey: NotificationMasterPlugin.kIntervalKey)
    ud.set("1",           forKey: NotificationMasterPlugin.kEnabledKey)
    ud.synchronize()

    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: path)
    proc.arguments     = ["--url", url, "--interval", "\(interval)"]

    do {
      try proc.run()
      daemonProcess = proc
      result(true)
    } catch {
      result(FlutterError(code: "LAUNCH_FAILED",
                          message: "Failed to launch daemon: \(error.localizedDescription)",
                          details: nil))
    }
  }

  private func stopBackgroundDaemon(result: @escaping FlutterResult) {
    let ud = daemonDefaults()
    ud.set("0", forKey: NotificationMasterPlugin.kEnabledKey)
    ud.synchronize()

    daemonProcess?.terminate()
    daemonProcess = nil
    result(true)
  }

  private func isBackgroundDaemonRunning() -> Bool {
    guard let proc = daemonProcess else { return false }
    return proc.isRunning
  }

  // MARK: - In-Process HTTP Polling

  private func startPollingTimer(urlString: String, intervalMinutes: Int) {
    stopPollingTimer()
    isPollingActive = true
    let seconds = max(1.0, Double(intervalMinutes) * 60.0)
    // Fire once immediately, then repeat.
    performPoll(urlString: urlString)
    pollingTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: true) { [weak self] _ in
      guard let self = self, self.isPollingActive else { return }
      self.performPoll(urlString: urlString)
    }
  }

  private func stopPollingTimer() {
    pollingTimer?.invalidate()
    pollingTimer = nil
    isPollingActive = false
  }

  private func performPoll(urlString: String) {
    guard let url = URL(string: urlString) else { return }
    URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
      guard let self = self, let data = data, error == nil else { return }
      guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let notifs = json["notifications"] as? [[String: Any]] else {
        // Non-conforming endpoint — show a generic fallback notification.
        DispatchQueue.main.async {
          let content = UNMutableNotificationContent()
          content.title = "Notification"
          content.body = "New notification received"
          content.sound = .default
          let req = UNNotificationRequest(
            identifier: "nm_poll_\(Date().timeIntervalSince1970)",
            content: content, trigger: nil)
          UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
        }
        return
      }
      DispatchQueue.main.async {
        for n in notifs {
          let title = n["title"] as? String ?? "Notification"
          let body  = (n["bigText"] as? String) ?? (n["message"] as? String) ?? ""
          let content = UNMutableNotificationContent()
          content.title = title
          content.body = body
          content.sound = .default
          if let ts = n["targetScreen"] as? String { content.userInfo["targetScreen"] = ts }
          let req = UNNotificationRequest(
            identifier: "nm_poll_\(Date().timeIntervalSince1970)_\(title.hashValue)",
            content: content, trigger: nil)
          UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
        }
      }
    }.resume()
  }

  // MARK: - Remote Service Management

  private func startNotificationPolling(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let urlString = args["pollingUrl"] as? String, !urlString.isEmpty else {
      result(FlutterError(code: "INVALID_URL", message: "pollingUrl required", details: nil))
      return
    }
    let interval = args["intervalMinutes"] as? Int ?? Self.defaultIntervalMinutes
    UserDefaults.standard.set(urlString, forKey: Self.prefsPollingUrl)
    UserDefaults.standard.set(interval, forKey: Self.prefsPollingInterval)
    setActiveServiceValue(.polling)
    startPollingTimer(urlString: urlString, intervalMinutes: interval)
    result(true)
  }

  private func stopNotificationPolling(result: @escaping FlutterResult) {
    stopPollingTimer()
    UserDefaults.standard.removeObject(forKey: Self.prefsPollingUrl)
    setActiveServiceValue(.none)
    result(true)
  }

  private func startForegroundService(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let urlString = args["pollingUrl"] as? String, !urlString.isEmpty else {
      result(FlutterError(code: "INVALID_URL", message: "pollingUrl required", details: nil))
      return
    }
    let interval = args["intervalMinutes"] as? Int ?? Self.defaultIntervalMinutes
    UserDefaults.standard.set(urlString, forKey: Self.prefsPollingUrl)
    UserDefaults.standard.set(interval, forKey: Self.prefsPollingInterval)
    setActiveServiceValue(.foreground)
    startPollingTimer(urlString: urlString, intervalMinutes: interval)
    result(true)
  }

  private func stopForegroundService(result: @escaping FlutterResult) {
    stopPollingTimer()
    setActiveServiceValue(.none)
    result(true)
  }

  private func setFirebaseAsActiveService(result: @escaping FlutterResult) {
    stopPollingTimer()
    setActiveServiceValue(.firebase)
    result(true)
  }

  private func getActiveNotificationService(result: @escaping FlutterResult) {
    let v = UserDefaults.standard.string(forKey: Self.prefsActiveService) ?? ServiceType.none.rawValue
    result(v)
  }

  private func setActiveServiceValue(_ type: ServiceType) {
    UserDefaults.standard.set(type.rawValue, forKey: Self.prefsActiveService)
  }

  // MARK: - Device Token & Topic Management

  private func postConfirmationNotification(title: String, body: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    let req = UNNotificationRequest(
      identifier: "nm_confirm_\(UUID().uuidString)",
      content: content, trigger: nil)
    UNUserNotificationCenter.current().add(req) { err in
      if let err = err { print("[NotificationMaster] Confirmation error: \(err)") }
    }
  }

  private func getDeviceToken(result: @escaping FlutterResult) {
    // macOS has no push-token without APNs entitlement; use hostname as stable ID.
    let token = ProcessInfo.processInfo.hostName
    postConfirmationNotification(
      title: "Device Token (macOS)",
      body: "Token: \(String(token.prefix(32)))…")
    result(token.isEmpty ? nil : token)
  }

  private func subscribeToTopic(_ topic: String, result: @escaping FlutterResult) {
    var topics = UserDefaults.standard.stringArray(forKey: "subscribed_topics") ?? []
    if !topics.contains(topic) { topics.append(topic) }
    UserDefaults.standard.set(topics, forKey: "subscribed_topics")
    postConfirmationNotification(title: "Subscribed", body: "Subscribed to: \(topic)")
    result(true)
  }

  private func unsubscribeFromTopic(_ topic: String, result: @escaping FlutterResult) {
    var topics = UserDefaults.standard.stringArray(forKey: "subscribed_topics") ?? []
    topics.removeAll { $0 == topic }
    UserDefaults.standard.set(topics, forKey: "subscribed_topics")
    postConfirmationNotification(title: "Unsubscribed", body: "Unsubscribed from: \(topic)")
    result(true)
  }

  private func getSubscribedTopics(result: @escaping FlutterResult) {
    result(UserDefaults.standard.stringArray(forKey: "subscribed_topics") ?? [])
  }

  // MARK: - Scheduled Notifications

  private func scheduledIdentifier(id: Int) -> String {
    NotificationMasterPlugin.scheduledPrefix + String(id)
  }

  private func scheduleNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let id = args["id"] as? Int,
          let title = args["title"] as? String,
          let message = args["message"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "id, title, message required", details: nil))
      return
    }
    let alarmSound = args["alarmSound"] as? Bool ?? false
    let scheduledEpochMillis = args["scheduledEpochMillis"] as? Int ?? 0

    let content = UNMutableNotificationContent()
    content.title = title
    content.body = message
    content.sound = alarmSound ? .defaultCritical : .default

    var userInfo: [String: Any] = [:]
    if let ts = args["targetScreen"] as? String { userInfo["targetScreen"] = ts }
    if let ed = args["extraData"] as? [String: Any] { userInfo["extraData"] = ed }
    content.userInfo = userInfo

    let nowMillis = Int64(Date().timeIntervalSince1970 * 1000)
    let delay = max(0.1, Double(scheduledEpochMillis - Int(nowMillis)) / 1000.0)
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)

    let req = UNNotificationRequest(identifier: scheduledIdentifier(id: id),
                                    content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(req) { err in
      DispatchQueue.main.async { result(err == nil) }
    }
  }

  private func cancelScheduledNotification(id: Int) {
    UNUserNotificationCenter.current()
      .removePendingNotificationRequests(withIdentifiers: [scheduledIdentifier(id: id)])
  }

  private func cancelAllScheduledNotifications() {
    let center = UNUserNotificationCenter.current()
    center.getPendingNotificationRequests { requests in
      let ids = requests
        .filter { $0.identifier.hasPrefix(NotificationMasterPlugin.scheduledPrefix) }
        .map { $0.identifier }
      center.removePendingNotificationRequests(withIdentifiers: ids)
    }
  }

  private func getPendingScheduledNotifications(completion: @escaping ([Int]) -> Void) {
    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
      let prefix = NotificationMasterPlugin.scheduledPrefix
      let ids = requests.compactMap { r -> Int? in
        guard r.identifier.hasPrefix(prefix) else { return nil }
        return Int(r.identifier.dropFirst(prefix.count))
      }
      completion(ids)
    }
  }

  // MARK: - UNUserNotificationCenterDelegate

  /// Show notifications as banners even when the app is in the foreground.
  public func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(macOS 12.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  /// Forward notification taps and action taps back to Dart via the channel.
  public func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let actionId = response.actionIdentifier
    let userInfo = response.notification.request.content.userInfo
    let targetScreen = userInfo["targetScreen"] as? String
    let extraData = userInfo["extraData"] as? [String: Any]

    if actionId.hasPrefix("ACTION_") {
      let parts = actionId.components(separatedBy: "_")
      if parts.count >= 3 {
        let route = parts.dropFirst(2).joined(separator: "_")
        var args: [String: Any] = ["route": route]
        if let ts = targetScreen { args["targetScreen"] = ts }
        if let ed = extraData { args["extraData"] = ed }
        channel?.invokeMethod("onActionTap", arguments: args)
      }
    } else if actionId == UNNotificationDefaultActionIdentifier {
      var args: [String: Any] = [:]
      if let ts = targetScreen { args["targetScreen"] = ts }
      if let ed = extraData { args["extraData"] = ed }
      channel?.invokeMethod("onNotificationTap", arguments: args)
    }
    completionHandler()
  }
}
