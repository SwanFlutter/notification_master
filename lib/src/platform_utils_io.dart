import 'dart:io';

/// Native (non-web) implementation using dart:io.
bool get isAndroid => Platform.isAndroid;
bool get isIOS => Platform.isIOS;
bool get isLinux => Platform.isLinux;
bool get isMacOS => Platform.isMacOS;
bool get isWindows => Platform.isWindows;

String getPlatformNameNative() {
  if (Platform.isAndroid) return 'Android';
  if (Platform.isIOS) return 'iOS';
  if (Platform.isLinux) return 'Linux';
  if (Platform.isMacOS) return 'macOS';
  if (Platform.isWindows) return 'Windows';
  return 'Unknown';
}
