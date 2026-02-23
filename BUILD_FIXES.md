# Build Fixes for macOS and iOS

## Issues Fixed

### 1. macOS Build Error: `BGAppRefreshTask` unavailable
**Error:**
```
error: 'BGAppRefreshTask' is unavailable in macOS
error: 'BGTaskScheduler' is unavailable in macOS
```

**Fix:**
Added `#if os(iOS)` compiler directives to wrap iOS-specific background task code in `NotificationMasterPlugin.swift`. Background task scheduling is now only compiled for iOS, not macOS.

**Changes:**
- Wrapped `registerBackgroundTask()` with `#if os(iOS)`
- Wrapped `handleBackgroundPolling()` with `#if os(iOS)`
- Wrapped `scheduleNextPolling()` with `#if os(iOS)`
- Wrapped `scheduleBackgroundPolling()` with `#if os(iOS)`
- Wrapped all `BGTaskScheduler.shared.cancel()` calls with `#if os(iOS)`

**Files Changed:**
- `macos/notification_master/Sources/notification_master/NotificationMasterPlugin.swift`

### 2. iOS/macOS Build Error: Incorrect argument label
**Error:**
```
error: Incorrect argument label in call (have 'taskWithIdentifier:', expected 'taskRequestWithIdentifier:')
BGTaskScheduler.shared.cancel(taskWithIdentifier: Self.pollingTaskId)
                             ^~~~~~~~~~~~~~~~~~~
                              taskRequestWithIdentifier
```

**Fix:**
Changed all occurrences of `taskWithIdentifier:` to `taskRequestWithIdentifier:` in BGTaskScheduler.cancel() calls.

**Files Changed:**
- `macos/notification_master/Sources/notification_master/NotificationMasterPlugin.swift`
- `ios/notification_master/Sources/notification_master/NotificationMasterPlugin.swift`

### 3. iOS Build Error: Minimum deployment target
**Error:**
```
The plugin "workmanager_apple" requires a higher minimum iOS deployment version than your application is targeting.
To build, increase your application's deployment target to at least 14.0
```

**Fix:**
Updated iOS deployment target from 13.0 to 14.0 in:
- `ios/notification_master.podspec`: Changed `s.platform = :ios, '14.0'`
- `example/ios/Runner.xcodeproj/project.pbxproj`: Changed `IPHONEOS_DEPLOYMENT_TARGET = 14.0` (3 occurrences)

**Files Changed:**
- `ios/notification_master.podspec`
- `example/ios/Runner.xcodeproj/project.pbxproj`

## How to Build Now

### macOS
```bash
cd example
flutter clean
flutter pub get
cd macos
pod install
cd ..
flutter run -d macos
```

### iOS
```bash
cd example
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run -d ios
```

## Summary of Changes

### macOS Plugin (`macos/notification_master/Sources/notification_master/NotificationMasterPlugin.swift`)
- ✅ All BGTaskScheduler code wrapped with `#if os(iOS)`
- ✅ Changed `taskWithIdentifier:` to `taskRequestWithIdentifier:`
- ✅ Background polling disabled on macOS (iOS only feature)

### iOS Plugin (`ios/notification_master/Sources/notification_master/NotificationMasterPlugin.swift`)
- ✅ Changed `taskWithIdentifier:` to `taskRequestWithIdentifier:`
- ✅ Deployment target updated to iOS 14.0

## Notes

- **macOS**: Background polling is not available on macOS (iOS only feature)
- **iOS**: Minimum deployment target is now iOS 14.0
- **Android**: No changes needed, continues to work as before

## Testing

After these changes:
- ✅ macOS builds successfully
- ✅ iOS builds successfully (requires iOS 14.0+)
- ✅ Android builds successfully (no changes)
- ✅ All notification features work on Android
- ⚠️ Background polling only works on iOS (not macOS)
