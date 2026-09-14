/// Notification Delivery Channels supported by the mobility platform
enum NotificationChannel {
  fcm,
  inAppRealtime;

  static NotificationChannel fromString(String? val) {
    if (val == null) return NotificationChannel.fcm;
    final normalized = val.toLowerCase().trim();
    if (normalized.contains('realtime') || normalized.contains('in_app')) {
      return NotificationChannel.inAppRealtime;
    }
    return NotificationChannel.fcm;
  }
}
