import 'dart:async';
import '../models/app_notification.dart';
import '../models/notification_channel.dart';
import 'i_notification_channel_handler.dart';

/// Decoupled FCM Channel Handler.
///
/// Encapsulates all Firebase Cloud Messaging interactions.
/// Business logic and UI never talk to FirebaseMessaging directly.
class FCMChannelHandler implements INotificationChannelHandler {
  void Function(AppNotification notification)? _listener;
  String? _currentToken;

  @override
  NotificationChannel get channel => NotificationChannel.fcm;

  String? get currentToken => _currentToken;

  @override
  void setNotificationListener(void Function(AppNotification notification) listener) {
    _listener = listener;
  }

  @override
  Future<void> initialize() async {
    // In live production, initialize FirebaseMessaging.instance, request permissions,
    // listen to onMessage and onMessageOpenedApp.
    // In this abstracted layer, initialization is zero-cost and testable.
  }

  /// Simulate or ingest an incoming push notification payload from FCM
  void simulateIncomingPush(Map<String, dynamic> rawPayload) {
    final notif = AppNotification.fromFcmPayload(rawPayload);
    _listener?.call(notif);
  }

  void updateToken(String token) {
    _currentToken = token;
  }

  @override
  void dispose() {
    _listener = null;
  }
}
