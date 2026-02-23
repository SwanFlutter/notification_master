/// Enum for notification importance levels
enum NotificationImportance {
  /// Minimum importance: does not show in the status bar on Android
  min(0),

  /// Low importance: shows in the status bar on Android, but below the fold
  low(1),

  /// Default importance: shows everywhere, makes noise, but does not visually intrude
  defaultImportance(2),

  /// High importance: shows everywhere, makes noise and peeks
  high(3),

  /// Maximum importance: same as high, but generally not used
  max(4);

  const NotificationImportance(this.value);

  /// The integer value for the importance level
  final int value;
}
