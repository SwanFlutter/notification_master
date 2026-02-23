import Flutter
import UIKit
import UserNotifications
import BackgroundTasks

public class NotificationMasterPlugin: NSObject, FlutterPlugin {
  private static let channelName = "notification_master"
  private static let pollingTaskId = "com.example.notification_master.polling"
  private static let prefsPollingUrl = "polling_url"
  private static let prefsPollingInterval = "polling_interval_minutes"
  private static let prefsActiveService = "active_notification_service"
  private static let defaultIntervalMinutes = 15

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    let instance = NotificationMasterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "requestNotificationPermission":
      requestNotificationPermission(result: result)
    case "checkNotificationPermission":
      checkNotificationPermission(result: result)
    case "showNotification":
      showNotification(call: call, result: result)
    case "showBigTextNotification":
      showBigTextNotification(call: call, result: result)
    case "showImageNotification":
      showImageNotification(call: call, result: result)
    case "showNotificationWithActions":
      showNotificationWithActions(call: call, result: result)
    case "createCustomChannel":
      result(true)
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
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestNotificationPermission(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
      DispatchQueue.main.async {
        result(granted)
      }
    }
  }

  private func checkNotificationPermission(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      DispatchQueue.main.async {
        result(settings.authorizationStatus == .authorized)
      }
    }
  }

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
    let request = UNNotificationRequest(identifier: "\(id)", content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request) { err in
      DispatchQueue.main.async {
        if err != nil { result(-1); return }
        result(id)
      }
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
    content.body = bigText.isEmpty ? message : bigText
    content.sound = .default
    let request = UNNotificationRequest(identifier: "\(id)", content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request) { err in
      DispatchQueue.main.async {
        if err != nil { result(-1); return }
        result(id)
      }
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
    if let urlString = args["imageUrl"] as? String,
       let url = URL(string: urlString),
       let attachment = try? UNNotificationAttachment(identifier: "img", url: url, options: nil) {
      content.attachments = [attachment]
    }
    let request = UNNotificationRequest(identifier: "\(id)", content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request) { err in
      DispatchQueue.main.async {
        if err != nil { result(-1); return }
        result(id)
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
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = message
    content.sound = .default
    content.categoryIdentifier = "notification_master_actions"
    var unActions: [UNNotificationAction] = []
    for (idx, act) in actions.prefix(4).enumerated() {
      if let actionTitle = act["title"] {
        unActions.append(UNNotificationAction(identifier: "action_\(idx)", title: actionTitle, options: []))
      }
    }
    if !unActions.isEmpty {
      let category = UNNotificationCategory(identifier: "notification_master_actions", actions: unActions, intentIdentifiers: [], options: [])
      UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    let request = UNNotificationRequest(identifier: "\(id)", content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request) { err in
      DispatchQueue.main.async {
        if err != nil { result(-1); return }
        result(id)
      }
    }
  }

  private func startNotificationPolling(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let urlString = args["pollingUrl"] as? String, !urlString.isEmpty else {
      result(FlutterError(code: "INVALID_URL", message: "pollingUrl required", details: nil))
      return
    }
    let interval = args["intervalMinutes"] as? Int ?? Self.defaultIntervalMinutes
    UserDefaults.standard.set(urlString, forKey: Self.prefsPollingUrl)
    UserDefaults.standard.set(interval, forKey: Self.prefsPollingInterval)
    UserDefaults.standard.set(1, forKey: Self.prefsActiveService)
    scheduleBackgroundPolling(intervalMinutes: interval)
    result(true)
  }

  private func stopNotificationPolling(result: @escaping FlutterResult) {
    UserDefaults.standard.removeObject(forKey: Self.prefsPollingUrl)
    UserDefaults.standard.set(0, forKey: Self.prefsActiveService)
    BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.pollingTaskId)
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
    UserDefaults.standard.set(2, forKey: Self.prefsActiveService)
    scheduleBackgroundPolling(intervalMinutes: interval)
    result(true)
  }

  private func stopForegroundService(result: @escaping FlutterResult) {
    UserDefaults.standard.set(0, forKey: Self.prefsActiveService)
    BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.pollingTaskId)
    result(true)
  }

  private func setFirebaseAsActiveService(result: @escaping FlutterResult) {
    UserDefaults.standard.set(3, forKey: Self.prefsActiveService)
    BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.pollingTaskId)
    result(true)
  }

  private func getActiveNotificationService(result: @escaping FlutterResult) {
    let v = UserDefaults.standard.integer(forKey: Self.prefsActiveService)
    let s: String
    switch v {
    case 1: s = "polling"
    case 2: s = "foreground"
    case 3: s = "firebase"
    default: s = "none"
    }
    result(s)
  }

  private func scheduleBackgroundPolling(intervalMinutes: Int) {
    let request = BGAppRefreshTaskRequest(identifier: Self.pollingTaskId)
    request.earliestBeginDate = Date(timeIntervalSinceNow: Double(intervalMinutes * 60))
    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      // Task may already be scheduled
    }
  }

  public static func registerBackgroundTask() {
    BGTaskScheduler.shared.register(forTaskWithIdentifier: pollingTaskId, using: nil) { task in
      Self.handleBackgroundPolling(task: task as! BGAppRefreshTask)
    }
  }

  private static func handleBackgroundPolling(task: BGAppRefreshTask) {
    scheduleNextPolling()
    guard let urlString = UserDefaults.standard.string(forKey: prefsPollingUrl),
          let url = URL(string: urlString) else {
      task.setTaskCompleted(success: true)
      return
    }
    let taskId = pollingTaskId
    task.expirationHandler = {
      task.setTaskCompleted(success: false)
    }
    URLSession.shared.dataTask(with: url) { data, _, _ in
      defer { task.setTaskCompleted(success: true) }
      guard let data = data,
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let notifs = json["notifications"] as? [[String: Any]] else { return }
      let center = UNUserNotificationCenter.current()
      for (i, n) in notifs.enumerated() {
        let title = n["title"] as? String ?? "Notification"
        let message = n["message"] as? String ?? ""
        let bigText = n["bigText"] as? String ?? message
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = bigText.isEmpty ? message : bigText
        content.sound = .default
        let req = UNNotificationRequest(identifier: "bg_\(i)_\(Date().timeIntervalSince1970)", content: content, trigger: nil)
        center.add(req, withCompletionHandler: nil)
      }
    }.resume()
  }

  private static func scheduleNextPolling() {
    let urlString = UserDefaults.standard.string(forKey: prefsPollingUrl)
    let interval = UserDefaults.standard.integer(forKey: prefsPollingInterval)
    if urlString == nil || interval <= 0 { return }
    let mins = interval > 0 ? interval : defaultIntervalMinutes
    let request = BGAppRefreshTaskRequest(identifier: pollingTaskId)
    request.earliestBeginDate = Date(timeIntervalSinceNow: Double(mins * 60))
    try? BGTaskScheduler.shared.submit(request)
  }
}
