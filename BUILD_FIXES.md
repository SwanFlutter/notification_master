# Build Fixes for macOS and iOS

## Issues Fixed

### 1. macOS Build Error: `BGAppRefreshTask` unavailable
**Error:**
```
error: 'BGAppRefreshTask' is unavailable in macOS
```

**Fix:**
Added `#if os(iOS)` compiler directives to wrap iOS-specific background task code in `NotificationMasterPlugin.swift`. Background task scheduling is now only compiled for iOS, not macOS.

**Files Changed:**
- `macos/notification_master/Sources/notification_master/NotificationMasterPlugin.swift`

### 2. iOS Build Error: Minimum deployment target
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
