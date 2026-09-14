/// 10 Platform Notification Events supported across FCM and In-App Realtime
enum NotificationEvent {
  rideRequest,
  driverAccepted,
  driverArriving,
  tripStarted,
  tripCompleted,
  paymentPending,
  paymentConfirmed,
  subscriptionExpiring,
  subscriptionExpired,
  supportUpdate,
  unknown;

  static NotificationEvent fromString(String? val) {
    if (val == null) return NotificationEvent.unknown;
    final normalized = val.toLowerCase().replaceAll('-', '_').trim();
    switch (normalized) {
      case 'ride_request':
      case 'ride_offered':
      case 'ride_requested':
        return NotificationEvent.rideRequest;
      case 'driver_accepted':
        return NotificationEvent.driverAccepted;
      case 'driver_arriving':
      case 'driver_arrived':
        return NotificationEvent.driverArriving;
      case 'trip_started':
        return NotificationEvent.tripStarted;
      case 'trip_completed':
        return NotificationEvent.tripCompleted;
      case 'payment_pending':
        return NotificationEvent.paymentPending;
      case 'payment_confirmed':
      case 'payment_settled':
        return NotificationEvent.paymentConfirmed;
      case 'subscription_expiring':
        return NotificationEvent.subscriptionExpiring;
      case 'subscription_expired':
        return NotificationEvent.subscriptionExpired;
      case 'support_update':
      case 'ticket_update':
        return NotificationEvent.supportUpdate;
      default:
        return NotificationEvent.unknown;
    }
  }

  String toWireName() {
    switch (this) {
      case NotificationEvent.rideRequest:
        return 'ride_request';
      case NotificationEvent.driverAccepted:
        return 'driver_accepted';
      case NotificationEvent.driverArriving:
        return 'driver_arriving';
      case NotificationEvent.tripStarted:
        return 'trip_started';
      case NotificationEvent.tripCompleted:
        return 'trip_completed';
      case NotificationEvent.paymentPending:
        return 'payment_pending';
      case NotificationEvent.paymentConfirmed:
        return 'payment_confirmed';
      case NotificationEvent.subscriptionExpiring:
        return 'subscription_expiring';
      case NotificationEvent.subscriptionExpired:
        return 'subscription_expired';
      case NotificationEvent.supportUpdate:
        return 'support_update';
      case NotificationEvent.unknown:
        return 'unknown';
    }
  }
}
