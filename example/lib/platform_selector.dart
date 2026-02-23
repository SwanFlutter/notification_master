// On web, dart:io is not available; use web-only selector.
// On VM (mobile/desktop), use full platform selector with dart:io.
export 'platform_selector_io.dart' if (dart.library.html) 'platform_selector_web.dart';
