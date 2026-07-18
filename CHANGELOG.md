

---

## 0.0.8

* **All platforms**: Added native scheduled (background) notifications — no external plugin required.
  - `scheduleNotification({id, title, message, scheduledTime, channelId, importance, alarmSound, targetScreen, extraData})` — asks the OS to deliver the notification at a fixed time, even when the app is fully closed.
  - `cancelScheduledNotification(int id)` — cancels a single scheduled notification.
  - `cancelAllScheduledNotifications()` — cancels all scheduled notifications.
  - `getPendingScheduledNotifications()` — returns the ids of notifications that are scheduled but not yet delivered.
* **Android**: Scheduling uses `AlarmManager.setExactAndAllowWhileIdle` (exact, wake-up alarm) with a `BroadcastReceiver`; scheduled items are persisted in `SharedPreferences` and re-armed on device reboot (`BootCompletedReceiver`). Added `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`/`RECEIVE_BOOT_COMPLETED` permissions.
* **iOS / macOS**: Scheduling uses `UNUserNotificationCenter` `UNTimeIntervalNotificationTrigger` (computed from the absolute epoch time). `alarmSound` uses a critical sound when available.
* **Windows**: Scheduling uses WinRT `ScheduledToastNotification` with the same AppUserModelId WinToast registers, so toasts are delivered by the OS. `alarmSound` uses a looping alarm scenario.
* **Linux**: Scheduling spawns a fully detached `setsid sh -c "sleep N && notify-send ..."` process, which survives the app being closed.
* **Web**: Best-effort `Timer`-based scheduling (delivers only while the tab stays open).
* **Example**: `reminder_alarm_page.dart` now uses native `scheduleNotification` (with `alarmSound: true`) instead of a Dart timer, so reminders fire even when the app is closed.

## 0.0.7

* **All platforms**: Added three new methods for push notification identity management:
  - `getDeviceToken()` — returns FCM token (Android/iOS with Firebase), APNS token, or stable device ID fallback. After retrieval a local notification confirms the token source.
  - `subscribeToTopic(String topic)` — subscribes via FCM when Firebase is present; stores locally otherwise. Shows a local confirmation notification.
  - `unsubscribeFromTopic(String topic)` — unsubscribes via FCM or removes local record. Shows a local confirmation notification.
  - `getSubscribedTopics()` — returns the current topic list (mirrors FCM subscriptions + local cache).
* **Android**: `subscribeToTopic`/`unsubscribeFromTopic` no longer throw `FIREBASE_NOT_AVAILABLE`; they fall back to `SharedPreferences` storage when Firebase is absent.
* **Android**: Confirmation notifications shown via `NotificationHelper` after each token/topic operation.
* **iOS / macOS**: Confirmation notifications shown via `UNUserNotificationCenter` (immediate trigger) after each token/topic operation.
* **Windows**: Confirmation notifications shown via `WinToast` after each token/topic operation. Fixed debug log spam (shell link / AUMI messages) by calling `WinToastLib::setDebugOutputEnabled(false)` on init.
* **Linux**: Confirmation notifications shown via `show_notification` (libnotify) after each token/topic operation. Topic storage uses `GKeyFile` at `~/.config/notification_master/prefs.ini`.
* **Web**: Confirmation notifications shown via browser `Notification` API after each token/topic operation. Token and topics persisted in `localStorage`.
* **example**: `token_topic_page.dart` fully rewritten — fine-grained loading per section, source badge on token, collapsible server code snippet, topics loaded from `getSubscribedTopics()` on init.

---

## 0.0.6

* **Android**: Removed permissions from plugin's `AndroidManifest.xml` — permissions must now be declared by the app developer (see README). Added proper component declarations: `NotificationForegroundService` (with `foregroundServiceType="dataSync"`), `BootCompletedReceiver` (with `BOOT_COMPLETED` + `MY_PACKAGE_REPLACED`), and `NotificationReceiver`.
* **Android**: Migrated `android/build.gradle.kts` to built-in Kotlin — removed `kotlin-android` plugin and `kotlinOptions` block; added `kotlin { compilerOptions {} }` DSL block as required by Flutter 3.44+.
* **Web/WASM**: Fixed `dart:io` import in `unified_notification_service.dart` and `notification_master_desktop.dart` by introducing conditional imports (`platform_utils.dart`). Package is now Web and WASM compatible.
* **Windows**: Added three new notification methods:
  - `showStyledNotification()`: Uses Text04 template with attribution text "Notification Master" at bottom, long duration (25 seconds), professional appearance
  - `showHeadsUpNotification()`: Uses Alarm scenario with looping alarm sound (AudioSystemFile::Alarm), long duration, high visibility for important alerts
  - `showFullScreenNotification()`: Uses IncomingCall scenario with looping call ringtone (AudioSystemFile::Call), most intrusive notification for urgent events
* **Windows**: Enhanced notification support:
  - 7 notification types total (Simple, Big Text, Image, Actions, Styled, Heads-Up, Full Screen)
  - Multiple scenarios: Default, Alarm, IncomingCall with appropriate audio
  - Audio options: Default, IM, Mail, SMS, Reminder, Alarm (looping), Call (looping)
  - Duration control: Short (5 seconds) and Long (25 seconds)
  - Attribution text support for branding
  - Image download and caching from HTTP/HTTPS URLs
  - Windows Action Center integration
  - Full WinRT Toast Notification API support
* **Windows**: Build and compatibility improvements:
  - Upgraded googletest from v1.11.0 to v1.14.0 in `windows/CMakeLists.txt` and `linux/CMakeLists.txt` to fix CMake 3.31+ compatibility issues
  - Fixed namespace inconsistency — changed from `notification_master_windows::NotificationMasterWindowsPlugin` to `notification_master::NotificationMasterPlugin` for consistency with C API and tests
  - Compatible with Windows 10/11
* **Windows**: Documentation added:
  - New `WINDOWS_NOTIFICATIONS_GUIDE.md` with complete examples for all 7 notification types
  - Platform comparison table (Windows vs Linux vs macOS vs Android vs iOS)
  - Best practices and when to use each notification type
  - Audio options guide
  - Troubleshooting section
* **Example**: Completely redesigned `windows_example.dart` with modern UI, gradient background, feature cards, and demos for all 7 notification types. Added `http` package to example dependencies.
* **Example**: Fixed import paths and deprecated API usage (`withOpacity` → `withValues`).
* **pubspec**: Updated minimum Flutter SDK to `>=3.44.0` and Dart SDK to `^3.12.0`.

---

## 0.0.5

* SDK and Flutter constraints updated.
* Platform-specific example screens (Android, iOS, Web, Windows, Linux, macOS).
* **Breaking / cleanup**: Removed redundant `lib/lib` and `lib/windowsww` folders; all API is in the main `lib` package.
* **macOS**: Full notification API and background polling (BGTaskScheduler) aligned with iOS; supports notifications, polling, and foreground service semantics.
* **Example app**: Simplified `main.dart`; app opens the platform-specific example (Android, iOS, Web, Windows, Linux, macOS) via `PlatformSelector`; removed duplicate `NotificationTest` widget.
* **Example macOS**: Registered background task in `AppDelegate` and added `BGTaskSchedulerPermittedIdentifiers` to `Info.plist` for polling.
* **Documentation**: README updated with web usage and example code.

---

## 0.0.4

* Fix bug.

---

## 0.0.3

* Add web support.
* Add macos support.
* Add windows support.
* Add linux support.
* Fix bugs.

---

## 0.0.2

* Fix bugs.

---

## 0.0.1

* Initial release with basic notification functionality.
* Added support for custom notification channels.
* Implemented HTTP/JSON notification polling.
* Added foreground service for reliable notification reception.
* Included permission management for Android 13 and above.
* Provided methods to check and request notification permission.
* Implemented swipe-to-dismiss capability for notifications.
* Added support for different importance levels in custom channels.
* Provided methods to manage and check the active notification service.
