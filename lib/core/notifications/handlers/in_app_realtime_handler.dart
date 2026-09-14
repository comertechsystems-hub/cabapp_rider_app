import 'dart:async';
import '../models/app_notification.dart';
import '../models/notification_channel.dart';
import 'i_notification_channel_handler.dart';

/// In-App Realtime Notification Handler.
///
/// Converts active session pub/sub envelopes from Frappe Realtime and Redis streams
/// into typed in-app notifications.
class InAppRealtimeHandler implements INotificationChannelHandler {
  void Function(AppNotification notification)? _listener;

  @override
  NotificationChannel get channel => NotificationChannel.inAppRealtime;

  @override
  void setNotificationListener(void Function(AppNotification notification) listener) {
    _listener = listener;
  }

  @override
  Future<void> initialize() async {
    // Initialized alongside RealtimeService connection
  }

  /// Ingest raw realtime event envelope received from WebSocket / Redis pub/sub
  void handleRealtimeEnvelope(Map<String, dynamic> envelope) {
    final notif = AppNotification.fromRealtimePayload(envelope);
    _listener?.call(notif);
  }

  @override
  void dispose() {
    _listener = null;
  }
}
