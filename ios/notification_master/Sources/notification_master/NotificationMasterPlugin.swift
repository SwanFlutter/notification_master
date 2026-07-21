import Flutter
import UIKit
import UserNotifications
import BackgroundTasks

public class NotificationMasterPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
  private static let taskIdentifier = "com.example.notification_master.polling"
  private var pollingUrl: String?
  private var intervalMinutes: Int = 15
  private var isPollingActive = false
  private var channel: FlutterMethodChannel?

  /// In-process timer that fires HTTP polls while the app is open.
  /// BGTaskScheduler only fires when the app is in the background and iOS
  /// decides to grant CPU time, so a foreground Timer is needed for the
  /// "polling" / "foreground" modes to work reliably during app use.
  private var pollingTimer: Timer?

  // Service types — "firebase" is the canonical Dart-side name for APNS/FCM.
  private enum NotificationServiceType: String {
    case none = "none"
    case polling = "polling"
    case foreground = "foreground"
    case firebase = "firebase"  // covers APNS / FCM
  }

  // UserDefaults keys
  private static let serviceTypeKey = "active_notification_service"
  private static let pollingUrlKey = "polling_url"
  private static let intervalMinutesKey = "interval_minutes"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "notification_master", binaryMessenger: registrar.messenger())
    let instance = NotificationMasterPlugin()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)

    // Register for background tasks (iOS 13+)
    if #available(iOS 13.0, *) {
      BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
        instance.handleAppRefresh(task: task as! BGAppRefreshTask)
      }
    }

    // Set notification delegate
    UNUserNotificationCenter.current().delegate = instance
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)

    // Permission handling
    case "checkNotificationPermission":
      checkNotificationPermission { hasPermission in
        result(hasPermission)
      }
    case "requestNotificationPermission":
      requestNotificationPermission { granted in
        result(granted)
      }

    // Simple notifications
    case "showNotification":
      guard let args = call.arguments as? [String: Any],
            let title = args["title"] as? String,
            let message = args["message"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        return
      }

      let channelId = args["channelId"] as? String
      let priority = args["priority"] as? Int ?? 0
      let autoCancel = args["autoCancel"] as? Bool ?? true
      let id = args["id"] as? Int
      let targetScreen = args["targetScreen"] as? String
      let extraData = args["extraData"] as? [String: Any]

      let notificationId = showNotification(title: title, message: message, channelId: channelId, priority: priority, autoCancel: autoCancel, id: id, targetScreen: targetScreen, extraData: extraData)
      result(notificationId)

    // Big text notifications
    case "showBigTextNotification":
      guard let args = call.arguments as? [String: Any],
            let title = args["title"] as? String,
            let message = args["message"] as? String,
            let bigText = args["bigText"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        return
      }

      let channelId = args["channelId"] as? String
      let priority = args["priority"] as? Int ?? 0
      let autoCancel = args["autoCancel"] as? Bool ?? true
      let targetScreen = args["targetScreen"] as? String
      let extraData = args["extraData"] as? [String: Any]

      let notificationId = showBigTextNotification(title: title, message: message, bigText: bigText, channelId: channelId, priority: priority, autoCancel: autoCancel, targetScreen: targetScreen, extraData: extraData)
      result(notificationId)

    // Image notifications
    case "showImageNotification":
      guard let args = call.arguments as? [String: Any],
            let title = args["title"] as? String,
            let message = args["message"] as? String,
            let imageUrl = args["imageUrl"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        return
      }

      let channelId = args["channelId"] as? String
      let priority = args["priority"] as? Int ?? 0
      let autoCancel = args["autoCancel"] as? Bool ?? true
      let targetScreen = args["targetScreen"] as? String
      let extraData = args["extraData"] as? [String: Any]

      showImageNotification(title: title, message: message, imageUrl: imageUrl, channelId: channelId, priority: priority, autoCancel: autoCancel, targetScreen: targetScreen, extraData: extraData)
      result(Int.random(in: 1...1000000))

    // Notifications with actions
    case "showNotificationWithActions":
      guard let args = call.arguments as? [String: Any],
            let title = args["title"] as? String,
            let message = args["message"] as? String,
            let actions = args["actions"] as? [[String: String]] else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        return
      }

      let channelId = args["channelId"] as? String
      let priority = args["priority"] as? Int ?? 0
      let autoCancel = args["autoCancel"] as? Bool ?? true
      let targetScreen = args["targetScreen"] as? String
      let extraData = args["extraData"] as? [String: Any]

      let notificationId = showNotificationWithActions(title: title, message: message, actions: actions, channelId: channelId, priority: priority, autoCancel: autoCancel, targetScreen: targetScreen, extraData: extraData)
      result(notificationId)

    // Specialized notifications (Heads-up, Full Screen, Styled)
    case "showHeadsUpNotification":
      guard let args = call.arguments as? [String: Any],
            let title = args["title"] as? String,
            let message = args["message"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        return
      }
      let targetScreen = args["targetScreen"] as? String
      let extraData = args["extraData"] as? [String: Any]
      
      let notificationId = showNotification(title: title, message: message, channelId: nil, priority: 2, autoCancel: true, id: nil, targetScreen: targetScreen, extraData: extraData)
      result(notificationId)

    case "showFullScreenNotification":
      guard let args = call.arguments as? [String: Any],
            let title = args["title"] as? String,
            let message = args["message"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        return
      }
      let targetScreen = args["targetScreen"] as? String
      let extraData = args["extraData"] as? [String: Any]
      
      let notificationId = showNotification(title: title, message: message, channelId: nil, priority: 2, autoCancel: true, id: nil, targetScreen: targetScreen, extraData: extraData)
      result(notificationId)

    case "showStyledNotification":
      guard let args = call.arguments as? [String: Any],
            let title = args["title"] as? String,
            let message = args["message"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        return
      }
      let channelId = args["channelId"] as? String
      let targetScreen = args["targetScreen"] as? String
      let extraData = args["extraData"] as? [String: Any]
      
      let notificationId = showNotification(title: title, message: message, channelId: channelId, priority: 1, autoCancel: true, id: nil, targetScreen: targetScreen, extraData: extraData)
      result(notificationId)

    // Device token and topic management
    case "getDeviceToken":
      getDeviceToken { token in
        result(token)
      }

    case "subscribeToTopic":
      guard let args = call.arguments as? [String: Any],
            let topic = args["topic"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        return
      }
      subscribeToTopic(topic) { success in
        result(success)
      }

    case "unsubscribeFromTopic":
      guard let args = call.arguments as? [String: Any],
            let topic = args["topic"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        return
      }
      unsubscribeFromTopic(topic) { success in
        result(success)
      }

    case "getSubscribedTopics":
      result(getSubscribedTopics())

    // Notification channels
    case "createCustomChannel":
      // iOS doesn't have channels like Android, but we'll store the settings
      result(true)

    // HTTP/JSON notification polling
    case "startNotificationPolling":
      guard let args = call.arguments as? [String: Any],
            let pollingUrl = args["pollingUrl"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        return
      }

      let intervalMinutes = args["intervalMinutes"] as? Int ?? 15
      startNotificationPolling(pollingUrl: pollingUrl, intervalMinutes: intervalMinutes)
      result(true)

    case "stopNotificationPolling":
      stopNotificationPolling()
      result(true)

    // Foreground service (simulated in iOS)
    case "startForegroundService":
      guard let args = call.arguments as? [String: Any],
            let pollingUrl = args["pollingUrl"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        return
      }

      let intervalMinutes = args["intervalMinutes"] as? Int ?? 15
      startForegroundService(pollingUrl: pollingUrl, intervalMinutes: intervalMinutes)
      result(true)

    case "stopForegroundService":
      stopForegroundService()
      result(true)

    // Service management
    case "setFirebaseAsActiveService":
      setFirebaseAsActiveService()
      result(true)

    case "getActiveNotificationService":
      result(getActiveNotificationService())

    // Scheduled (background) notifications
    case "scheduleNotification":
      scheduleNotification(call: call, result: result)

    case "cancelScheduledNotification":
      guard let args = call.arguments as? [String: Any],
            let id = args["id"] as? Int else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        return
      }
      cancelScheduledNotification(id: id)
      result(true)

    case "cancelAllScheduledNotifications":
      cancelAllScheduledNotifications()
      result(true)

    case "getPendingScheduledNotifications":
      getPendingScheduledNotifications { ids in
        result(ids)
      }

    // These are Android-specific permission gates; always true / no-op on iOS.
    case "canScheduleExactAlarms":
      result(true)

    case "openExactAlarmSettings":
      result(false)

    case "openAppNotificationSettings":
      // Open the app's notification settings page in iOS Settings.
      if let url = URL(string: UIApplication.openSettingsURLString) {
        DispatchQueue.main.async {
          UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
      }
      result(true)

    // Background daemon is supported on Windows, Linux, and macOS only.
    // On iOS use startNotificationPolling() (BGTaskScheduler-based) instead.
    case "startBackgroundPollingService":
      result(FlutterError(
        code: "PLATFORM_NOT_SUPPORTED",
        message: "startBackgroundPollingService is only available on Windows, Linux, and macOS. Use startNotificationPolling() on iOS.",
        details: nil))

    case "stopBackgroundPollingService":
      result(FlutterError(
        code: "PLATFORM_NOT_SUPPORTED",
        message: "stopBackgroundPollingService is only available on Windows, Linux, and macOS. Use stopNotificationPolling() on iOS.",
        details: nil))

    case "isBackgroundPollingRunning":
      result(FlutterError(
        code: "PLATFORM_NOT_SUPPORTED",
        message: "isBackgroundPollingRunning is only available on Windows, Linux, and macOS.",
        details: nil))

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Permission Handling

  private func checkNotificationPermission(completion: @escaping (Bool) -> Void) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      DispatchQueue.main.async {
        completion(settings.authorizationStatus == .authorized)
      }
    }
  }

  private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      DispatchQueue.main.async {
        completion(granted)
      }
    }
  }

  // MARK: - Notification Display

  private func showNotification(title: String, message: String, channelId: String?, priority: Int, autoCancel: Bool, id: Int?, targetScreen: String?, extraData: [String: Any]?) -> Int {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = message
    
    // Add target screen and extra data to userInfo
    var userInfo: [String: Any] = [:]
    if let targetScreen = targetScreen {
      userInfo["targetScreen"] = targetScreen
    }
    if let extraData = extraData {
      userInfo["extraData"] = extraData
    }
    content.userInfo = userInfo

    // Set sound based on priority (0: min, 1: low, 2: default, 3: high, 4: max)
    if priority >= 2 {
      content.sound = UNNotificationSound.default
    }

    // Create identifier - use provided id or generate a numeric one for the return value
    let notificationId = id ?? Int.random(in: 1...1000000)
    let identifier = String(notificationId)

    // Create the request
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

    // Add the request to the notification center
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("Error showing notification: \(error)")
      }
    }
    
    return notificationId
  }

  private func showBigTextNotification(title: String, message: String, bigText: String, channelId: String?, priority: Int, autoCancel: Bool, targetScreen: String?, extraData: [String: Any]?) -> Int {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = message
    content.subtitle = bigText
    
    // Add target screen and extra data to userInfo
    var userInfo: [String: Any] = [:]
    if let targetScreen = targetScreen {
      userInfo["targetScreen"] = targetScreen
    }
    if let extraData = extraData {
      userInfo["extraData"] = extraData
    }
    content.userInfo = userInfo

    // Set sound based on priority
    if priority >= 2 {
      content.sound = UNNotificationSound.default
    }

    // Create a unique identifier
    let notificationId = Int.random(in: 1...1000000)
    let identifier = String(notificationId)

    // Create the request
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

    // Add the request to the notification center
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("Error showing big text notification: \(error)")
      }
    }
    
    return notificationId
  }

  private func showImageNotification(title: String, message: String, imageUrl: String, channelId: String?, priority: Int, autoCancel: Bool, targetScreen: String?, extraData: [String: Any]?) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = message
    
    // Add target screen and extra data to userInfo
    var userInfo: [String: Any] = [:]
    if let targetScreen = targetScreen {
      userInfo["targetScreen"] = targetScreen
    }
    if let extraData = extraData {
      userInfo["extraData"] = extraData
    }
    content.userInfo = userInfo

    // Set sound based on priority
    if priority >= 2 {
      content.sound = UNNotificationSound.default
    }

    // Download the image and create an attachment
    if let url = URL(string: imageUrl) {
      downloadImage(from: url) { localUrl in
        if let localUrl = localUrl {
          do {
            let attachment = try UNNotificationAttachment(identifier: UUID().uuidString, url: localUrl, options: nil)
            content.attachments = [attachment]

            // Create the request
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

            // Add the request to the notification center
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
          } catch {
            print("Error creating attachment: \(error)")
          }
        }
      }
    }
  }

  private func showNotificationWithActions(title: String, message: String, actions: [[String: String]], channelId: String?, priority: Int, autoCancel: Bool, targetScreen: String?, extraData: [String: Any]?) -> Int {
    // Set up notification actions dynamically
    let categoryIdentifier = "DYNAMIC_ACTION_CATEGORY_" + UUID().uuidString
    setupDynamicNotificationActions(categoryIdentifier: categoryIdentifier, actions: actions)

    let content = UNMutableNotificationContent()
    content.title = title
    content.body = message
    content.categoryIdentifier = categoryIdentifier
    
    // Add target screen and extra data to userInfo
    var userInfo: [String: Any] = [:]
    if let targetScreen = targetScreen {
      userInfo["targetScreen"] = targetScreen
    }
    if let extraData = extraData {
      userInfo["extraData"] = extraData
    }
    content.userInfo = userInfo

    // Set sound based on priority
    if priority >= 2 {
      content.sound = UNNotificationSound.default
    }

    // Create identifier
    let notificationId = Int.random(in: 1...1000000)
    let identifier = String(notificationId)

    // Create the request
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

    // Add the request to the notification center
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    
    return notificationId
  }

  private func setupDynamicNotificationActions(categoryIdentifier: String, actions: [[String: String]]) {
    var unActions: [UNNotificationAction] = []
    
    for (index, action) in actions.enumerated() {
      if let title = action["title"] {
        let route = action["route"] ?? ""
        // Store the route in the action identifier so we can retrieve it later
        let identifier = "ACTION_\(index)_\(route)"
        let unAction = UNNotificationAction(
          identifier: identifier,
          title: title,
          options: .foreground
        )
        unActions.append(unAction)
      }
    }

    // Define the category
    let actionCategory = UNNotificationCategory(
      identifier: categoryIdentifier,
      actions: unActions,
      intentIdentifiers: [],
      options: []
    )

    // Register the category (this adds to existing ones)
    UNUserNotificationCenter.current().getNotificationCategories { categories in
      var newCategories = categories
      newCategories.insert(actionCategory)
      UNUserNotificationCenter.current().setNotificationCategories(newCategories)
    }
  }

  private func downloadImage(from url: URL, completion: @escaping (URL?) -> Void) {
    let task = URLSession.shared.downloadTask(with: url) { localUrl, response, error in
      guard let localUrl = localUrl else {
        completion(nil)
        return
      }

      // Create a temporary file URL to store the image
      let tempDirectoryURL = FileManager.default.temporaryDirectory
      let tempFileURL = tempDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")

      do {
        try FileManager.default.moveItem(at: localUrl, to: tempFileURL)
        completion(tempFileURL)
      } catch {
        print("Error moving downloaded file: \(error)")
        completion(nil)
      }
    }
    task.resume()
  }

  // MARK: - Device Token & Topic Management

  /// Post a local UNUserNotification as confirmation of token/topic operations.
  private func postConfirmationNotification(title: String, body: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    let request = UNNotificationRequest(
      identifier: "nm_confirm_\(UUID().uuidString)",
      content: content,
      trigger: nil          // deliver immediately
    )
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("[NotificationMaster] Confirmation notification error: \(error)")
      }
    }
  }

  private func getDeviceToken(completion: @escaping (String?) -> Void) {
    // Try APNS token stored by the app (set via setAPNSToken from AppDelegate)
    if let apnsData = UserDefaults.standard.data(forKey: "apns_token") {
      let tokenString = apnsData.map { String(format: "%02.2hhx", $0) }.joined()
      postConfirmationNotification(
        title: "Device Token (APNS)",
        body: "Token: \(String(tokenString.prefix(24)))…"
      )
      completion(tokenString)
      return
    }

    // Fallback: identifierForVendor
    let deviceId = UIDevice.current.identifierForVendor?.uuidString
    postConfirmationNotification(
      title: "Device Token (Vendor ID)",
      body: "Token: \(String((deviceId ?? "").prefix(24)))…"
    )
    completion(deviceId)
  }

  private func subscribeToTopic(_ topic: String, completion: @escaping (Bool) -> Void) {
    var topics = UserDefaults.standard.stringArray(forKey: "subscribed_topics") ?? []
    if !topics.contains(topic) {
      topics.append(topic)
      UserDefaults.standard.set(topics, forKey: "subscribed_topics")
    }
    postConfirmationNotification(
      title: "Subscribed",
      body: "You are now subscribed to topic: \(topic)"
    )
    print("[NotificationMaster] Subscribed to topic: \(topic)")
    completion(true)
  }

  private func unsubscribeFromTopic(_ topic: String, completion: @escaping (Bool) -> Void) {
    var topics = UserDefaults.standard.stringArray(forKey: "subscribed_topics") ?? []
    topics.removeAll { $0 == topic }
    UserDefaults.standard.set(topics, forKey: "subscribed_topics")
    postConfirmationNotification(
      title: "Unsubscribed",
      body: "You have unsubscribed from topic: \(topic)"
    )
    print("[NotificationMaster] Unsubscribed from topic: \(topic)")
    completion(true)
  }

  private func getSubscribedTopics() -> [String] {
    return UserDefaults.standard.stringArray(forKey: "subscribed_topics") ?? []
  }

  // MARK: - Notification Polling

  private func startNotificationPolling(pollingUrl: String, intervalMinutes: Int) {
    self.pollingUrl = pollingUrl
    self.intervalMinutes = intervalMinutes
    self.isPollingActive = true

    // Save settings to UserDefaults
    UserDefaults.standard.set(pollingUrl, forKey: NotificationMasterPlugin.pollingUrlKey)
    UserDefaults.standard.set(intervalMinutes, forKey: NotificationMasterPlugin.intervalMinutesKey)

    // Set active service
    setActiveService(.polling)

    // Start in-process timer for foreground polling.
    startPollingTimer()

    // Also schedule BGTask so polling continues in the background.
    if #available(iOS 13.0, *) {
      scheduleBackgroundTask()
    } else {
      UIApplication.shared.setMinimumBackgroundFetchInterval(Double(intervalMinutes * 60))
    }
  }

  private func stopNotificationPolling() {
    self.isPollingActive = false
    stopPollingTimer()
    setActiveService(.none)

    if #available(iOS 13.0, *) {
      BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: NotificationMasterPlugin.taskIdentifier)
    } else {
      UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
    }
  }

  // MARK: - In-Process Polling Timer

  private func startPollingTimer() {
    stopPollingTimer()
    guard let urlString = pollingUrl, !urlString.isEmpty else { return }
    let seconds = max(1.0, Double(intervalMinutes) * 60.0)
    // Fire once immediately, then repeat on the interval.
    performPoll(urlString: urlString)
    pollingTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: true) { [weak self] _ in
      guard let self = self, self.isPollingActive else { return }
      self.performPoll(urlString: urlString)
    }
  }

  private func stopPollingTimer() {
    pollingTimer?.invalidate()
    pollingTimer = nil
  }

  private func performPoll(urlString: String) {
    guard let url = URL(string: urlString) else { return }
    URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
      guard let self = self, let data = data, error == nil else { return }
      guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let notifs = json["notifications"] as? [[String: Any]] else {
        // Non-conforming URL (e.g. test endpoint) — show a fallback notification.
        DispatchQueue.main.async {
          _ = self.showNotification(
            title: "Notification",
            message: "New notification received",
            channelId: nil, priority: 2, autoCancel: true,
            id: nil, targetScreen: nil, extraData: nil
          )
        }
        return
      }
      DispatchQueue.main.async {
        for n in notifs {
          let title = n["title"] as? String ?? "Notification"
          let message = (n["bigText"] as? String) ?? (n["message"] as? String) ?? ""
          _ = self.showNotification(
            title: title, message: message,
            channelId: n["channelId"] as? String,
            priority: 2, autoCancel: true, id: nil,
            targetScreen: n["targetScreen"] as? String,
            extraData: n["extraData"] as? [String: Any]
          )
        }
      }
    }.resume()
  }

  @available(iOS 13.0, *)
  private func scheduleBackgroundTask() {
    let request = BGAppRefreshTaskRequest(identifier: NotificationMasterPlugin.taskIdentifier)
    request.earliestBeginDate = Date(timeIntervalSinceNow: Double(intervalMinutes * 60))

    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      print("Could not schedule background task: \(error)")
    }
  }

  @available(iOS 13.0, *)
  private func handleAppRefresh(task: BGAppRefreshTask) {
    // Schedule the next background task
    scheduleBackgroundTask()

    // Check if polling is active
    guard isPollingActive, let pollingUrl = self.pollingUrl, let url = URL(string: pollingUrl) else {
      task.setTaskCompleted(success: false)
      return
    }

    // Create a task to fetch notifications
    let fetchTask = Task {
      do {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
          return
        }

        // Parse the JSON response
        if let notificationResponse = try? JSONDecoder().decode(NotificationResponse.self, from: data) {
          // Show notifications
          for notification in notificationResponse.notifications {
            _ = self.showNotification(
              title: notification.title,
              message: notification.message,
              channelId: notification.channelId,
              priority: 2, // Default importance
              autoCancel: true,
              id: nil,
              targetScreen: notification.targetScreen,
              extraData: notification.extraData
            )
          }
        }
      } catch {
        print("Error fetching notifications: \(error)")
      }
    }

    // Set up a task expiration handler
    task.expirationHandler = {
      fetchTask.cancel()
    }

    // Inform the system when the task is complete
    Task {
      await fetchTask.value
      task.setTaskCompleted(success: true)
    }
  }

  // MARK: - Foreground Service (Simulated)

  private func startForegroundService(pollingUrl: String, intervalMinutes: Int) {
    self.pollingUrl = pollingUrl
    self.intervalMinutes = intervalMinutes
    self.isPollingActive = true

    UserDefaults.standard.set(pollingUrl, forKey: NotificationMasterPlugin.pollingUrlKey)
    UserDefaults.standard.set(intervalMinutes, forKey: NotificationMasterPlugin.intervalMinutesKey)

    setActiveService(.foreground)

    // Show a persistent status notification.
    let content = UNMutableNotificationContent()
    content.title = "Notification Service"
    content.body = "Checking for notifications every \(intervalMinutes) minutes"
    content.sound = nil
    let request = UNNotificationRequest(identifier: "foreground_service", content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)

    // In-process timer + BGTask.
    startPollingTimer()
    if #available(iOS 13.0, *) {
      scheduleBackgroundTask()
    } else {
      UIApplication.shared.setMinimumBackgroundFetchInterval(Double(intervalMinutes * 60))
    }
  }

  private func stopForegroundService() {
    self.isPollingActive = false
    stopPollingTimer()
    setActiveService(.none)

    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["foreground_service"])

    if #available(iOS 13.0, *) {
      BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: NotificationMasterPlugin.taskIdentifier)
    } else {
      UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
    }
  }

  // MARK: - Service Management

  private func setActiveService(_ serviceType: NotificationServiceType) {
    let currentService = getActiveServiceType()
    if currentService == serviceType { return }

    // Tear down old service.
    switch currentService {
    case .polling, .foreground:
      stopPollingTimer()
      if #available(iOS 13.0, *) {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: NotificationMasterPlugin.taskIdentifier)
      } else {
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
      }
      if currentService == .foreground {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["foreground_service"])
      }
    case .firebase, .none:
      break
    }

    UserDefaults.standard.set(serviceType.rawValue, forKey: NotificationMasterPlugin.serviceTypeKey)
  }

  private func setFirebaseAsActiveService() {
    setActiveService(.firebase)
  }

  private func getActiveServiceType() -> NotificationServiceType {
    if let s = UserDefaults.standard.string(forKey: NotificationMasterPlugin.serviceTypeKey),
       let svc = NotificationServiceType(rawValue: s) {
      return svc
    }
    return .none
  }

  private func getActiveNotificationService() -> String {
    return getActiveServiceType().rawValue
  }

  // MARK: - Scheduled (Background) Notifications

  /// Prefix used to identify notifications scheduled through `scheduleNotification`
  /// so they can be queried/cancelled independently of other notifications.
  private static let scheduledPrefix = "nm_sched_"

  private func scheduledIdentifier(id: Int) -> String {
    return NotificationMasterPlugin.scheduledPrefix + String(id)
  }

  private func scheduleNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let id = args["id"] as? Int,
          let title = args["title"] as? String,
          let message = args["message"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }

    let channelId = args["channelId"] as? String
    let priority = args["priority"] as? Int ?? 2
    let alarmSound = args["alarmSound"] as? Bool ?? false
    let targetScreen = args["targetScreen"] as? String
    let extraData = args["extraData"] as? [String: Any]
    let scheduledEpochMillis = Int64(args["scheduledEpochMillis"] as? Int ?? 0)

    let content = UNMutableNotificationContent()
    content.title = title
    content.body = message

    var userInfo: [String: Any] = [:]
    if let targetScreen = targetScreen { userInfo["targetScreen"] = targetScreen }
    if let extraData = extraData { userInfo["extraData"] = extraData }
    content.userInfo = userInfo

    // Alarm sound is louder (critical) if requested and available.
    if priority >= 2 || alarmSound {
      if #available(iOS 12.0, *), alarmSound {
        content.sound = UNNotificationSound.criticalSoundNamed(UNNotificationSoundName.default)
      } else {
        content.sound = UNNotificationSound.default
      }
    }

    let identifier = scheduledIdentifier(id: id)
    let center = UNUserNotificationCenter.current()

    // Build a trigger from the epoch time. iOS uses a time interval from now,
    // so convert the absolute time to a relative interval.
    let nowMillis = Int64(Date().timeIntervalSince1970 * 1000)
    let delaySeconds = max(0.1, Double(scheduledEpochMillis - nowMillis) / 1000.0)

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delaySeconds, repeats: false)

    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    center.add(request) { error in
      if let error = error {
        print("[NotificationMaster] Error scheduling notification: \(error)")
        result(false)
      } else {
        result(true)
      }
    }
  }

  private func cancelScheduledNotification(id: Int) {
    UNUserNotificationCenter.current().removePendingNotificationRequests(
      withIdentifiers: [scheduledIdentifier(id: id)]
    )
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
      let ids = requests.compactMap { request -> Int? in
        guard request.identifier.hasPrefix(prefix) else { return nil }
        let numeric = request.identifier.dropFirst(prefix.count)
        return Int(numeric)
      }
      completion(ids)
    }
  }

  // MARK: - UNUserNotificationCenterDelegate

  public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    // Show the notification even when the app is in the foreground
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    // Handle notification actions
    let actionIdentifier = response.actionIdentifier
    let userInfo = response.notification.request.content.userInfo
    
    // Extract target screen and extra data
    let targetScreen = userInfo["targetScreen"] as? String
    let extraData = userInfo["extraData"] as? [String: Any]

    // Handle custom actions
    if actionIdentifier.hasPrefix("ACTION_") {
      // Format: ACTION_index_route
      let components = actionIdentifier.components(separatedBy: "_")
      if components.count >= 3 {
        let route = components.dropFirst(2).joined(separator: "_")
        
        // Send action tap event to Dart
        var args: [String: Any] = ["route": route]
        if let targetScreen = targetScreen { args["targetScreen"] = targetScreen }
        if let extraData = extraData { args["extraData"] = extraData }
        
        channel?.invokeMethod("onActionTap", arguments: args)
      }
    } else if actionIdentifier == UNNotificationDefaultActionIdentifier {
      // Standard tap on notification
      var args: [String: Any] = [:]
      if let targetScreen = targetScreen { args["targetScreen"] = targetScreen }
      if let extraData = extraData { args["extraData"] = extraData }
      
      channel?.invokeMethod("onNotificationTap", arguments: args)
    }

    completionHandler()
  }
}

// MARK: - Data Models

struct NotificationResponse: Decodable {
  let notifications: [NotificationData]
}

struct NotificationData: Decodable {
  let title: String
  let message: String
  let bigText: String?
  let channelId: String?
  let targetScreen: String?
  let extraData: [String: Any]?

  enum CodingKeys: String, CodingKey {
    case title, message, bigText, channelId, targetScreen, extraData
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    title = try container.decode(String.self, forKey: .title)
    message = try container.decode(String.self, forKey: .message)
    bigText = try container.decodeIfPresent(String.self, forKey: .bigText)
    channelId = try container.decodeIfPresent(String.self, forKey: .channelId)
    targetScreen = try container.decodeIfPresent(String.self, forKey: .targetScreen)
    
    // extraData is tricky with Decodable if it's a generic [String: Any]
    if let data = try? container.decodeIfPresent([String: AnyDecodable].self, forKey: .extraData) {
      extraData = data.mapValues { $0.value }
    } else {
      extraData = nil
    }
  }
}

// Helper to decode [String: Any]
struct AnyDecodable: Decodable {
  let value: Any

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let string = try? container.decode(String.self) {
      value = string
    } else if let int = try? container.decode(Int.self) {
      value = int
    } else if let double = try? container.decode(Double.self) {
      value = double
    } else if let bool = try? container.decode(Bool.self) {
      value = bool
    } else if let array = try? container.decode([AnyDecodable].self) {
      value = array.map { $0.value }
    } else if let dictionary = try? container.decode([String: AnyDecodable].self) {
      value = dictionary.mapValues { $0.value }
    } else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyDecodable value not found")
    }
  }
}
