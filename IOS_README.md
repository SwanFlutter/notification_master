# iOS Implementation Guide - Notification Master

This document provides detailed information about the iOS implementation of the Notification Master plugin.

## Overview

The iOS implementation is built using Swift and provides native iOS notification features including APNS integration, background app refresh, and various notification types optimized for iOS devices.

## Architecture

### Main Plugin Class
- **Location**: `ios/Classes/NotificationMasterPlugin.swift`
- **Language**: Swift
- **Key Features**:
  - Flutter plugin integration
  - UNUserNotificationCenter delegate
  - Background task scheduling (iOS 13+)
  - APNS integration support

### Core Components

#### 1. Notification Center Management
Manages iOS notification system with support for:
- Authorization requests
- Notification categories and actions
- Foreground notification handling
- Notification delegates

#### 2. Background Task Scheduling
- **BGTaskScheduler**: For iOS 13+ background app refresh
- **Polling Service**: Simulated background notification polling
- **APNS Integration**: Apple Push Notification Service support

#### 3. Permission Management
- Notification authorization requests
- Background refresh permissions
- Provisional notification support (iOS 12+)

## Platform-Specific Features

### iOS 10+ (UNUserNotificationCenter)
- **Authorization**: Request notification permissions
- **Categories**: Group notifications with custom actions
- **Content Extensions**: Rich notification support
- **Service Extensions**: Modify notifications before display

### iOS 12+ 
- **Provisional Authorization**: Quiet notifications without explicit permission
- **Critical Alerts**: Override Do Not Disturb (special entitlement required)
- **Grouped Notifications**: Automatic grouping by thread identifier

### iOS 13+
- **BGTaskScheduler**: Modern background task scheduling
- **Background App Refresh**: Configurable refresh intervals
- **Notification Management**: In-app notification management UI

### iOS 15+
- **Focus Modes**: Respect focus mode settings
- **Time Sensitive Notifications**: Special interruption levels
- **Notification Summary**: Part of notification digest

## Configuration

### Info.plist Requirements
```xml
<!-- Required for notifications -->
<key>NSUserNotificationUsageDescription</key>
<string>This app needs to send you notifications</string>

<!-- For background app refresh (iOS 13+) -->
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.example.notification_master.polling</string>
</array>

<!-- Background modes -->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>

<!-- Optional: For critical alerts (requires special entitlement) -->
<key>NSUserNotificationUsageDescription</key>
<string>This app needs to send critical alerts</string>
```

### Podfile Dependencies
```ruby
platform :ios, '11.0'

# Required for background tasks
pod 'BackgroundTasks', '~> 0.1.0'

# Optional: For advanced networking
pod 'Alamofire', '~> 5.6'
```

### AppDelegate.swift Setup
```swift
import UIKit
import Flutter
import UserNotifications
import BackgroundTasks

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register background tasks
    if #available(iOS 13.0, *) {
      BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.example.notification_master.polling", using: nil) { task in
        // Handle background refresh
        self.handleAppRefresh(task: task as! BGAppRefreshTask)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  @available(iOS 13.0, *)
  func handleAppRefresh(task: BGAppRefreshTask) {
    // Schedule next refresh
    scheduleAppRefresh()
    
    // Complete the task
    task.setTaskCompleted(success: true)
  }
  
  @available(iOS 13.0, *)
  func scheduleAppRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "com.example.notification_master.polling")
    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
    
    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      print("Unable to submit background task: \(error)")
    }
  }
}
```

## Notification Types

### 1. Simple Notifications
Basic notifications with title, message, and optional actions.

### 2. Rich Notifications
- **Big Text**: Expanded text content
- **Images**: Attachments from URLs
- **Custom UI**: Content extensions for rich media

### 3. Actionable Notifications
Interactive notifications with custom action buttons.

### 4. Grouped Notifications
Automatic grouping by thread identifier or category.

## Background Services

### Simulated Polling Service
- **BGTaskScheduler**: For iOS 13+ background app refresh
- **Interval**: Configurable (default 15 minutes)
- **JSON Format**: Server responses must follow specific structure
- **Reliability**: Subject to iOS background execution policies

### APNS Integration
- **Apple Push Notification Service**: Native iOS push notifications
- **Background Notifications**: Silent push for content updates
- **Device Tokens**: Proper token management and registration

## Permission Management

### Notification Authorization
- **Request Types**: Provisional, authorized, provisional+authorized
- **Authorization Status**: Not determined, denied, authorized, provisional
- **Critical Alerts**: Special entitlement required

### Background Permissions
- **Background App Refresh**: System-level permission
- **Background Fetch**: Traditional background execution
- **Push Notifications**: APNS registration

## Error Handling

### Common Issues
1. **Permission Denied**: Proper error callbacks for authorization failures
2. **Background Task Failures**: BGTaskScheduler error handling
3. **Network Errors**: URL loading and JSON parsing errors
4. **Service Management**: Proper cleanup and error reporting

### Error Codes
- `INVALID_ARGS`: Invalid method arguments
- `PERMISSION_DENIED`: Missing notification authorization
- `NETWORK_ERROR`: HTTP request failures
- `SERVICE_ERROR`: Background service failures

## Performance Considerations

### Memory Management
- Efficient image loading for rich notifications
- Proper cleanup of background tasks
- Minimal memory footprint for polling operations

### Battery Optimization
- BGTaskScheduler respects battery optimization
- Configurable polling intervals
- Efficient network usage for HTTP requests

### Background Execution
- iOS background execution time limits
- Proper task completion handling
- Background refresh policies

## Testing

### Unit Tests
- Located in iOS test targets
- Covers core functionality and edge cases
- Mock implementations for iOS dependencies

### Integration Tests
- Real device testing for notifications
- Background task validation
- Authorization flow testing

### TestFlight Testing
- Beta testing for notification delivery
- Background execution validation
- Production-like environment testing

## Debugging

### Console Logs
- `NotificationMasterPlugin`: Main plugin logs
- `BGTaskScheduler`: Background task logs
- `URLSession`: Network request logs

### Debug Features
- Verbose logging in debug builds
- Error stack traces in callbacks
- Service status monitoring

### Xcode Debugging
- Breakpoint debugging
- Console output monitoring
- Background task debugging

## Security

### Network Security
- HTTPS enforcement for polling URLs
- Certificate validation
- App Transport Security (ATS) compliance

### Data Protection
- Secure handling of notification data
- Keychain integration for sensitive data
- Privacy-preserving analytics

### Privacy
- Minimal data collection
- User consent management
- Privacy manifest compliance (iOS 17+)

## Compatibility

### Minimum iOS Version
- **iOS 11.0**: Minimum supported version
- **Target iOS**: Latest iOS version
- **Swift Version**: 5.0+

### Device Support
- iPhone and iPad
- Apple Watch (notification mirroring)
- CarPlay (basic notification support)

## Migration Guide

### From Legacy Implementations
1. Update Info.plist with new permissions
2. Implement BGTaskScheduler for iOS 13+
3. Update notification authorization handling
4. Configure background app refresh

### Version Compatibility
- Backward compatibility maintained
- Graceful degradation for older iOS versions
- Feature detection and conditional implementation

## App Store Considerations

### Review Guidelines
- Proper use of background execution
- Notification permission best practices
- Background app refresh justification

### Entitlements
- Critical alerts require special entitlement
- Background modes must be justified
- Push notification certificates required

## Advanced Features

### Content Extensions
- Custom notification UI
- Rich media support
- Interactive elements

### Service Extensions
- Modify notifications before display
- Decrypt encrypted notifications
- Add attachments dynamically

### Notification Management
- In-app notification settings
- Notification history management
- Category-based organization