import Flutter
import UIKit
import UserNotifications
import BackgroundTasks

public class NotificationMasterPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
  private static let taskIdentifier = "com.example.notification_master.polling"
  private var pollingUrl: String?
  private var intervalMinutes: Int = 15
  private var isPollingActive = false

  // Service types
  private enum NotificationServiceType: String {
    case none = "none"
    case polling = "polling"
    case foreground = "foreground" // Simulated foreground service
    case apns = "apns" // Apple Push Notification Service
  }

  // UserDefaults keys
  private static let serviceTypeKey = "active_notification_service"
  private static let pollingUrlKey = "polling_url"
  private static let intervalMinutesKey = "interval_minutes"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "notification_master", binaryMessenger: registrar.messenger())
    let instance = NotificationMasterPlugin()
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

      showNotification(title: title, message: message, channelId: channelId, priority: priority, autoCancel: autoCancel, id: id)
      result(true)

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

      showBigTextNotification(title: title, message: message, bigText: bigText, channelId: channelId, priority: priority, autoCancel: autoCancel)
      result(true)

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

      showImageNotification(title: title, message: message, imageUrl: imageUrl, channelId: channelId, priority: priority, autoCancel: autoCancel)
      result(true)

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

      showNotificationWithActions(title: title, message: message, actions: actions, channelId: channelId, priority: priority, autoCancel: autoCancel)
      result(true)

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

  private func showNotification(title: String, message: String, channelId: String?, priority: Int, autoCancel: Bool, id: Int?) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = message

    // Set sound based on priority
    if priority > 0 {
      content.sound = UNNotificationSound.default
    }

    // Create identifier - use provided id or generate unique one
    let identifier = id != nil ? String(id!) : UUID().uuidString

    // Create the request
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

    // Add the request to the notification center
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("Error showing notification: \(error)")
      }
    }
  }

  private func showBigTextNotification(title: String, message: String, bigText: String, channelId: String?, priority: Int, autoCancel: Bool) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = message
    content.subtitle = bigText

    // Set sound based on priority
    if priority > 0 {
      content.sound = UNNotificationSound.default
    }

    // Create a unique identifier
    let identifier = UUID().uuidString

    // Create the request
    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

    // Add the request to the notification center
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("Error showing big text notification: \(error)")
      }
    }
  }

  private func showImageNotification(title: String, message: String, imageUrl: String, channelId: String?, priority: Int, autoCancel: Bool) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = message

    // Set sound based on priority
    if priority > 0 {
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

  private func showNotificationWithActions(title: String, message: String, actions: [[String: String]], channelId: String?, priority: Int, autoCancel: Bool) {
    // Set up notification actions
    setupNotificationActions()

    let content = UNMutableNotificationContent()
    content.title = title
    content.body = message
    content.categoryIdentifier = "ACTION_CATEGORY"

    // Set sound based on priority
    if priority > 0 {
      content.sound = UNNotificationSound.default
    }

    // Create the request
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

    // Add the request to the notification center
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
  }

  private func setupNotificationActions() {
    // Define the actions
    let openSettingsAction = UNNotificationAction(
      identifier: "OPEN_SETTINGS",
      title: "Open Settings",
      options: .foreground
    )

    let viewProfileAction = UNNotificationAction(
      identifier: "VIEW_PROFILE",
      title: "View Profile",
      options: .foreground
    )

    // Define the category
    let actionCategory = UNNotificationCategory(
      identifier: "ACTION_CATEGORY",
      actions: [openSettingsAction, viewProfileAction],
      intentIdentifiers: [],
      options: []
    )

    // Register the category
    UNUserNotificationCenter.current().setNotificationCategories([actionCategory])
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

    // Schedule background task
    if #available(iOS 13.0, *) {
      scheduleBackgroundTask()
    } else {
      // For older iOS versions, use background fetch
      UIApplication.shared.setMinimumBackgroundFetchInterval(Double(intervalMinutes * 60))
    }
  }

  private func stopNotificationPolling() {
    self.isPollingActive = false

    // Set active service to none
    setActiveService(.none)

    // Cancel background tasks
    if #available(iOS 13.0, *) {
      BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: NotificationMasterPlugin.taskIdentifier)
    } else {
      // For older iOS versions
      UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
    }
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
            let content = UNMutableNotificationContent()
            content.title = notification.title
            content.body = notification.message

            if let bigText = notification.bigText {
              content.subtitle = bigText
            }

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
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
    // In iOS, we'll simulate a foreground service by using more frequent background tasks
    // and showing a persistent notification

    self.pollingUrl = pollingUrl
    self.intervalMinutes = intervalMinutes
    self.isPollingActive = true

    // Save settings to UserDefaults
    UserDefaults.standard.set(pollingUrl, forKey: NotificationMasterPlugin.pollingUrlKey)
    UserDefaults.standard.set(intervalMinutes, forKey: NotificationMasterPlugin.intervalMinutesKey)

    // Set active service
    setActiveService(.foreground)

    // Show a persistent notification
    let content = UNMutableNotificationContent()
    content.title = "Notification Service"
    content.body = "Checking for notifications every \(intervalMinutes) minutes"
    content.sound = nil

    // Make it persistent by not auto-canceling
    let request = UNNotificationRequest(identifier: "foreground_service", content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)

    // Schedule background task
    if #available(iOS 13.0, *) {
      scheduleBackgroundTask()
    } else {
      // For older iOS versions, use background fetch
      UIApplication.shared.setMinimumBackgroundFetchInterval(Double(intervalMinutes * 60))
    }
  }

  private func stopForegroundService() {
    self.isPollingActive = false

    // Set active service to none
    setActiveService(.none)

    // Remove the persistent notification
    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["foreground_service"])

    // Cancel background tasks
    if #available(iOS 13.0, *) {
      BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: NotificationMasterPlugin.taskIdentifier)
    } else {
      // For older iOS versions
      UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
    }
  }

  // MARK: - Service Management

  private func setActiveService(_ serviceType: NotificationServiceType) {
    // Get current active service
    let currentService = getActiveServiceType()

    // If the same service is already active, do nothing
    if currentService == serviceType {
      return
    }

    // Disable current active service
    switch currentService {
    case .polling:
      if #available(iOS 13.0, *) {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: NotificationMasterPlugin.taskIdentifier)
      } else {
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
      }
    case .foreground:
      // Remove the persistent notification
      UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["foreground_service"])
      if #available(iOS 13.0, *) {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: NotificationMasterPlugin.taskIdentifier)
      } else {
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
      }
    case .apns, .none:
      // Nothing to do
      break
    }

    // Save the new active service
    UserDefaults.standard.set(serviceType.rawValue, forKey: NotificationMasterPlugin.serviceTypeKey)
  }

  private func setFirebaseAsActiveService() {
    setActiveService(.apns)
  }

  private func getActiveServiceType() -> NotificationServiceType {
    if let serviceString = UserDefaults.standard.string(forKey: NotificationMasterPlugin.serviceTypeKey),
       let service = NotificationServiceType(rawValue: serviceString) {
      return service
    }
    return .none
  }

  private func getActiveNotificationService() -> String {
    return getActiveServiceType().rawValue
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

    // Handle custom actions
    switch actionIdentifier {
    case "OPEN_SETTINGS":
      if let url = URL(string: UIApplication.openSettingsURLString) {
        DispatchQueue.main.async {
          UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
      }
    case "VIEW_PROFILE":
      // Handle view profile action
      break
    default:
      break
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
}
