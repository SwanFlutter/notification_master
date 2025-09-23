/// Importance levels for notification channels
enum NotificationImportance {
  /// Default importance: makes sound (NotificationManager.IMPORTANCE_DEFAULT)
  defaultImportance(0),

  /// High importance: makes sound and appears as heads-up notification (NotificationManager.IMPORTANCE_HIGH)
  high(1),

  /// Low importance: no sound (NotificationManager.IMPORTANCE_LOW)
  low(2),

  /// Min importance: no sound and does not appear in status bar (NotificationManager.IMPORTANCE_MIN)
  min(3),

  /// Silent importance: no sound and no vibration (NotificationManager.IMPORTANCE_NONE)
  silent(4);

  /// The integer value of the importance level
  final int value;

  /// Constructor
  const NotificationImportance(this.value);
}
