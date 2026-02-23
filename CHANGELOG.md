

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
