import 'dart:async';
import '../models/app_notification.dart';
import '../models/notification_channel.dart';
import '../models/notification_event.dart';

/// Abstract Notification Service contract decoupling mobile presentation and business
/// logic from Firebase Cloud Messaging SDK and Frappe Realtime transport.
abstract class INotificationService {
  /// Stream emitting every incoming notification across FCM and In-App Realtime
  Stream<AppNotification> get notificationStream;

  /// Stream emitting typed domain events for state machines to react without parsing raw payloads
  Stream<NotificationEvent> get eventStream;

  /// In-memory historical cache of notifications received during current app session
  List<AppNotification> get notifications;

  /// Active FCM device token if registered
  String? get activeDeviceToken;

  /// Initialize notification channel listeners and permissions
  Future<void> initialize();

  /// Register or refresh FCM device token with the backend
  Future<void> registerDeviceToken(String token);

  /// Unregister device token on user logout
  Future<void> unregisterDeviceToken();

  /// Ingest raw payload from either FCM push or In-App Realtime bus
  void handleIncomingPayload(Map<String, dynamic> rawPayload, NotificationChannel channel);

  /// Mark specific notification as read
  void markAsRead(String id);

  /// Clear all notification history
  void clearAll();

  /// Clean up streams and controllers
  void dispose();
}
