

---

## 0.0.6

* **Android**: Removed permissions from plugin's `AndroidManifest.xml` — permissions must now be declared by the app developer (see README). Added proper component declarations: `NotificationForegroundService` (with `foregroundServiceType="dataSync"`), `BootCompletedReceiver` (with `BOOT_COMPLETED` + `MY_PACKAGE_REPLACED`), and `NotificationReceiver`.
* **Android**: Migrated `android/build.gradle.kts` to built-in Kotlin — removed `kotlin-android` plugin and `kotlinOptions` block; added `kotlin { compilerOptions {} }` DSL block as required by Flutter 3.44+.
* **Web/WASM**: Fixed `dart:io` import in `unified_notification_service.dart` and `notification_master_desktop.dart` by introducing conditional imports (`platform_utils.dart`). Package is now Web and WASM compatible.
* **Windows**: Added three new notification types: `showStyledNotification()` (with attribution text), `showHeadsUpNotification()` (Alarm scenario), and `showFullScreenNotification()` (IncomingCall scenario). Enhanced Windows support with multiple notification scenarios, custom audio (Alarm, Call, SMS, etc.), and long duration support.
* **Windows**: Upgraded googletest from v1.11.0 to v1.14.0 in `windows/CMakeLists.txt` and `linux/CMakeLists.txt` to fix CMake 3.31+ compatibility.
* **Windows**: Fixed namespace inconsistency — changed from `notification_master_windows::NotificationMasterWindowsPlugin` to `notification_master::NotificationMasterPlugin` for consistency with C API and tests.
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
