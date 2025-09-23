# Android Implementation Guide - Notification Master

This document provides detailed information about the Android implementation of the Notification Master plugin.

## Overview

The Android implementation is built using Kotlin and provides comprehensive notification features including custom channels, foreground services, background polling, and various notification types.

## Architecture

### Main Plugin Class
- **Location**: `android/src/main/kotlin/com/example/notification_master/NotificationMasterPlugin.kt`
- **Language**: Kotlin
- **Key Features**:
  - Flutter plugin integration
  - Activity lifecycle management
  - Permission handling
  - Background service management

### Core Components

#### 1. Notification Helper
Manages notification creation and display with support for:
- Custom notification channels (Android 8.0+)
- Various notification types (simple, big text, image)
- Action buttons
- Priority levels
- Auto-cancel behavior

#### 2. Background Services
- **Polling Service**: Uses WorkManager for periodic HTTP polling
- **Foreground Service**: Maintains persistent notifications with custom channels
- **Firebase Integration**: Optional Firebase Cloud Messaging support

#### 3. Permission Management
- Runtime permission requests for Android 13+ (API 33+)
- Notification permission handling
- Internet permission validation

## Platform-Specific Features

### Android 8.0+ (API 26+)
- **Notification Channels**: Required for all notifications
- **Channel Customization**: Name, description, importance, lights, vibration, sound
- **Channel Management**: Dynamic creation and configuration

### Android 13+ (API 33+)
- **Runtime Permissions**: POST_NOTIFICATIONS permission required
- **Permission Dialogs**: Native Android permission request UI

### Background Execution
- **WorkManager**: For reliable background task execution
- **Foreground Service**: For continuous operation with persistent notification
- **Battery Optimization**: Respects Android's battery optimization rules

## Configuration

### AndroidManifest.xml Requirements

**✅ No Manual Configuration Required!**

The `notification_master` plugin automatically includes all necessary permissions and service declarations in its own AndroidManifest.xml. When you add the plugin to your project, Flutter automatically merges these configurations with your app's manifest.

**Included by default:**
- All required permissions (INTERNET, POST_NOTIFICATIONS, FOREGROUND_SERVICE, etc.)
- Service declarations (NotificationForegroundService, NotificationReceiver, etc.)
- WorkManager initialization
- Network security configuration for HTTP requests

**You don't need to manually add anything to your AndroidManifest.xml!**

### Optional: Custom Network Security (for HTTP polling)
If you need to customize network security settings for your specific server endpoints, you can create your own `network_security_config.xml` in `android/app/src/main/res/xml/`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">your-server.com</domain>
        <domain includeSubdomains="true">api.yourapp.com</domain>
    </domain-config>
</network-security-config>
```

Then reference it in your app's AndroidManifest.xml:
```xml
<application
    android:networkSecurityConfig="@xml/network_security_config">
```

### build.gradle Dependencies
```gradle
dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
    implementation 'androidx.core:core-ktx:1.9.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.8.0'
    
    // Notification dependencies
    implementation 'androidx.work:work-runtime-ktx:2.8.1'
    implementation 'com.squareup.okhttp3:okhttp:4.10.0'
    implementation 'com.google.code.gson:gson:2.10.1'
    
    // Optional Firebase integration
    implementation 'com.google.firebase:firebase-messaging:23.1.2'
}
```

## Notification Types

### 1. Simple Notifications
Basic notifications with title, message, and optional actions.

### 2. Big Text Notifications
Expanded notifications for longer text content with collapse/expand functionality.

### 3. Image Notifications
Notifications with image attachments loaded from URLs.

### 4. Action Notifications
Interactive notifications with custom action buttons.

## Background Services

### HTTP Polling Service
- **Interval**: Configurable (default 15 minutes)
- **JSON Format**: Server responses must follow specific structure
- **Reliability**: Uses WorkManager for guaranteed execution
- **Battery Friendly**: Respects Doze mode and App Standby

### Foreground Service
- **Persistent Notification**: Required for Android 8.0+
- **Custom Channel**: Configurable notification channel
- **Service Types**: Data sync for Android 14+
- **Lifecycle**: Properly managed start/stop operations

## Error Handling

### Common Issues
1. **Permission Denied**: Proper error callbacks for permission failures
2. **Channel Creation**: Validation for channel parameters
3. **Image Loading**: Network error handling for image notifications
4. **Service Management**: Proper cleanup and error reporting

### Error Codes
- `INVALID_ARGS`: Invalid method arguments
- `PERMISSION_DENIED`: Missing required permissions
- `CHANNEL_ERROR`: Notification channel issues
- `SERVICE_ERROR`: Background service failures

## Performance Considerations

### Memory Management
- Efficient bitmap handling for image notifications
- Proper cleanup of background services
- Minimal memory footprint for polling operations

### Battery Optimization
- WorkManager respects battery optimization
- Configurable polling intervals
- Efficient network usage for HTTP requests

## Testing

### Unit Tests
- Located in `android/src/test/kotlin/`
- Covers core functionality and edge cases
- Mock implementations for Android dependencies

### Integration Tests
- Real device testing for notifications
- Background service validation
- Permission flow testing

## Debugging

### Log Tags
- `NotificationMasterPlugin`: Main plugin logs
- `NotificationHelper`: Notification creation logs
- `PollingWorker`: Background polling logs

### Debug Features
- Verbose logging in debug builds
- Error stack traces in callbacks
- Service status monitoring

## Security

### Network Security
- HTTPS enforcement for polling URLs
- Certificate validation
- Secure handling of notification data

### Permission Security
- Minimal permission requests
- Runtime permission best practices
- User consent management

## Compatibility

### Minimum SDK
- **API 21**: Android 5.0 (Lollipop)
- **Target SDK**: Latest Android version
- **Compile SDK**: Latest Android version

### Device Support
- Phones and tablets
- Android TV (limited notification support)
- Wear OS (basic notification support)

## Migration Guide

### From Legacy Implementations
1. Update AndroidManifest.xml with new permissions
2. Configure notification channels for Android 8.0+
3. Implement runtime permissions for Android 13+
4. Update background service implementation

### Version Compatibility
- Backward compatibility maintained
- Graceful degradation for older Android versions
- Feature detection and conditional implementation