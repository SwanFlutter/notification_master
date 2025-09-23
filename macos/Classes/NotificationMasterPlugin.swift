import Cocoa
import FlutterMacOS
import UserNotifications

public class NotificationMasterPlugin: NSObject, FlutterPlugin {
    private static var notificationChannels: [String: String] = [:]
    private static var isPollingServiceActive = false
    private static var isForegroundServiceActive = false
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "notification_master", binaryMessenger: registrar.messenger)
        let instance = NotificationMasterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
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
            createCustomChannel(call: call, result: result)
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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification permission error: \(error)")
                    result(false)
                } else {
                    result(granted)
                }
            }
        }
    }
    
    private func checkNotificationPermission(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let granted = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
                result(granted)
            }
        }
    }
    
    private func showNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let title = args["title"] as? String,
              let message = args["message"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for showNotification", details: nil))
            return
        }
        
        let channelId = args["channelId"] as? String ?? "default"
        let id = args["id"] as? Int
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        // Use provided id or generate unique identifier
        let identifier = id != nil ? String(id!) : UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error showing notification: \(error)")
                    result(-1)
                } else {
                    result(id ?? 1) // Return the notification ID
                }
            }
        }
    }
    
    private func showBigTextNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let title = args["title"] as? String,
              let message = args["message"] as? String,
              let bigText = args["bigText"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for showBigTextNotification", details: nil))
            return
        }
        
        let channelId = args["channelId"] as? String ?? "default"
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.subtitle = bigText
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error showing big text notification: \(error)")
                    result(-1)
                } else {
                    result(1) // Return notification ID
                }
            }
        }
    }
    
    private func showImageNotification(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let title = args["title"] as? String,
              let message = args["message"] as? String,
              let imageUrl = args["imageUrl"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for showImageNotification", details: nil))
            return
        }
        
        let channelId = args["channelId"] as? String ?? "default"
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        // For simplicity, we'll just show a regular notification with the image URL in the message
        content.body = "\(message) Image: \(imageUrl)"
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error showing image notification: \(error)")
                    result(-1)
                } else {
                    result(1) // Return notification ID
                }
            }
        }
    }
    
    private func showNotificationWithActions(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let title = args["title"] as? String,
              let message = args["message"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for showNotificationWithActions", details: nil))
            return
        }
        
        let channelId = args["channelId"] as? String ?? "default"
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error showing notification with actions: \(error)")
                    result(-1)
                } else {
                    result(1) // Return notification ID
                }
            }
        }
    }
    
    private func createCustomChannel(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let channelId = args["channelId"] as? String,
              let channelName = args["channelName"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for createCustomChannel", details: nil))
            return
        }
        
        let channelDescription = args["channelDescription"] as? String ?? ""
        NotificationMasterPlugin.notificationChannels[channelId] = channelName
        result(true)
    }
    
    private func startNotificationPolling(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let pollingUrl = args["pollingUrl"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for startNotificationPolling", details: nil))
            return
        }
        
        let intervalMinutes = args["intervalMinutes"] as? Int ?? 15
        
        // In a real implementation, you would start a background task to poll the URL
        // For now, we'll just set the flag
        NotificationMasterPlugin.isPollingServiceActive = true
        result(true)
    }
    
    private func stopNotificationPolling(result: @escaping FlutterResult) {
        NotificationMasterPlugin.isPollingServiceActive = false
        result(true)
    }
    
    private func startForegroundService(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let pollingUrl = args["pollingUrl"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for startForegroundService", details: nil))
            return
        }
        
        let intervalMinutes = args["intervalMinutes"] as? Int ?? 15
        
        // macOS doesn't have foreground services in the same way as Android
        // We'll treat this as starting the polling service
        NotificationMasterPlugin.isForegroundServiceActive = true
        NotificationMasterPlugin.isPollingServiceActive = true
        result(true)
    }
    
    private func stopForegroundService(result: @escaping FlutterResult) {
        NotificationMasterPlugin.isForegroundServiceActive = false
        NotificationMasterPlugin.isPollingServiceActive = false
        result(true)
    }
    
    private func setFirebaseAsActiveService(result: @escaping FlutterResult) {
        // Not applicable on macOS
        result(false)
    }
    
    private func getActiveNotificationService(result: @escaping FlutterResult) {
        if NotificationMasterPlugin.isForegroundServiceActive {
            result("foreground")
        } else if NotificationMasterPlugin.isPollingServiceActive {
            result("polling")
        } else {
            result("none")
        }
    }
}