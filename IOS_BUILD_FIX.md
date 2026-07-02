# iOS Build Fix Guide

## Problem Fixed

✅ **Fixed typo in Swift code**: `FlurError` → `FlutterError`
✅ **Added version to example app**: `version: 1.0.0+1`

---

## Quick Fix

Run these commands in the `example` directory:

```bash
# Clean everything
flutter clean
rm -rf ios/Pods ios/Podfile.lock

# Reinstall
flutter pub get
cd ios
pod install
cd ..

# Build
flutter run
```

---

## Or Use the Script

```bash
chmod +x ios_build_fix.sh
./ios_build_fix.sh
```

---

## Manual Steps

### 1. Clean Flutter Build

```bash
cd example
flutter clean
```

### 2. Remove iOS Pods

```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
```

### 3. Reinstall Dependencies

```bash
pod install
cd ..
flutter pub get
```

### 4. Build

```bash
flutter run
```

---

## If Still Having Issues

### Issue: CocoaPods Configuration Warning

If you see:
> CocoaPods did not set the base configuration of your project

**Solution:**

1. Open `example/ios/Runner.xcworkspace` in Xcode
2. Select Runner project in left panel
3. Select Runner target
4. Go to "Build Settings" tab
5. Search for "Base Configuration"
6. For each configuration (Debug, Release, Profile):
   - Set to: `Pods-Runner.debug.xcconfig` (or respective config)

### Issue: Deployment Target Mismatch

If you see deployment target errors:

**Solution:**

1. Open `example/ios/Podfile`
2. Make sure this is in `post_install`:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
```

3. Run:
```bash
cd ios
pod install
cd ..
```

### Issue: Swift Compiler Errors

If you see Swift compilation errors:

**Solution:**

1. Make sure you're using Xcode 13.0 or higher
2. Check Swift version:
```bash
swift --version
```

3. Clean derived data:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

4. Rebuild:
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

---

## Verification

After fixing, you should see:

```
✓ Built build/ios/iphoneos/Runner.app
Launching lib/main.dart on iPhone in debug mode...
```

---

## Common Errors and Solutions

### Error: "Cannot find 'FlutterError' in scope"

**Fixed!** This was a typo in the code. Already corrected.

### Error: "Missing build name (CFBundleShortVersionString)"

**Fixed!** Added `version: 1.0.0+1` to `example/pubspec.yaml`

### Error: "Module 'notification_master' not found"

**Solution:**
```bash
cd example/ios
pod deintegrate
pod install
cd ../..
flutter clean
flutter pub get
cd example
flutter run
```

---

## Need More Help?

See:
- [IOS_SETUP.md](IOS_SETUP.md) - Complete iOS setup guide
- [IOS_SETUP_FA.md](IOS_SETUP_FA.md) - راهنمای فارسی

---

## License

MIT License
