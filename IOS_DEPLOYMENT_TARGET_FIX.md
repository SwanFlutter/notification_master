# Fix: iOS Deployment Target Error

## Problem

When running `pod install`, you get this error:

```
CocoaPods could not find compatible versions for pod "notification_master":
Specs satisfying the dependency were found, but they required a higher minimum deployment target.
```

## Root Cause

The `notification_master` plugin requires **iOS 14.0 or higher**, but your Podfile is set to iOS 12.0.

---

## Solution

### Step 1: Update Podfile

Open `example/ios/Podfile` and change:

```ruby
# OLD (iOS 12.0)
platform :ios, '12.0'
```

To:

```ruby
# NEW (iOS 14.0 - Required by notification_master)
platform :ios, '14.0'
```

### Step 2: Update post_install

In the same Podfile, find the `post_install` section and change:

```ruby
# OLD
config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
```

To:

```ruby
# NEW
config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
```

### Step 3: Clean and Reinstall

Run these commands:

```bash
cd example/ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install
cd ../..
```

### Step 4: Clean Flutter Build

```bash
flutter clean
flutter pub get
```

### Step 5: Try Running Again

```bash
flutter run
```

---

## Complete Podfile Example

Here's what your `example/ios/Podfile` should look like:

```ruby
# Minimum iOS version required by notification_master plugin
platform :ios, '14.0'

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      # Set minimum iOS deployment target to 14.0 (required by notification_master)
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['SWIFT_VERSION'] = '5.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
```

---

## Verification

After following these steps, run:

```bash
cd example/ios
pod install
```

You should see:

```
Analyzing dependencies
Downloading dependencies
Installing notification_master
...
Pod installation complete!
```

---

## Still Having Issues?

### Issue: Flutter says "Updating minimum iOS deployment target to 13.0"

This is just a warning. Flutter automatically updates it to 14.0 when it detects the plugin requirement.

### Issue: Xcode build fails

1. Open `example/ios/Runner.xcworkspace` in Xcode
2. Select Runner target
3. Go to "Build Settings"
4. Search for "iOS Deployment Target"
5. Set it to "iOS 14.0"

---

## Why iOS 14.0?

The `notification_master` plugin uses iOS APIs that are only available in iOS 14.0 and later:
- UserNotifications framework features
- Background task improvements
- Modern notification handling

---

## Summary

✅ Change `platform :ios, '12.0'` to `platform :ios, '14.0'`  
✅ Update `IPHONEOS_DEPLOYMENT_TARGET` to `'14.0'` in post_install  
✅ Clean pods and reinstall  
✅ Clean Flutter build  

That's it! Your iOS setup should now work correctly.
