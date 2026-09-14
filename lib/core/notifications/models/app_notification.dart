import 'notification_channel.dart';
import 'notification_event.dart';

/// Normalized domain model for an incoming or stored notification
class AppNotification {
  final String id;
  final NotificationEvent event;
  final NotificationChannel channel;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  bool isRead;
  final String? sound;
  final String? priority;

  AppNotification({
    required this.id,
    required this.event,
    required this.channel,
    required this.title,
    required this.body,
    this.data = const {},
    DateTime? timestamp,
    this.isRead = false,
    this.sound,
    this.priority,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AppNotification.fromFcmPayload(Map<String, dynamic> raw) {
    // FCM payloads typically contain "notification" and/or "data"
    final notificationPart = raw['notification'] is Map ? raw['notification'] as Map<String, dynamic> : <String, dynamic>{};
    final dataPart = raw['data'] is Map ? Map<String, dynamic>.from(raw['data'] as Map) : <String, dynamic>{};

    final title = notificationPart['title']?.toString() ??
        dataPart['title']?.toString() ??
        'CabApp Alert';

    final body = notificationPart['body']?.toString() ??
        dataPart['body']?.toString() ??
        '';

    final eventRaw = dataPart['event']?.toString() ??
        dataPart['type']?.toString() ??
        raw['event']?.toString();

    final id = dataPart['event_id']?.toString() ??
        raw['message_id']?.toString() ??
        'fcm_${DateTime.now().millisecondsSinceEpoch}';

    return AppNotification(
      id: id,
      event: NotificationEvent.fromString(eventRaw),
      channel: NotificationChannel.fcm,
      title: title,
      body: body,
      data: dataPart,
      sound: raw['sound']?.toString() ?? dataPart['sound']?.toString(),
      priority: raw['priority']?.toString() ?? dataPart['priority']?.toString() ?? 'high',
    );
  }

  factory AppNotification.fromRealtimePayload(Map<String, dynamic> raw) {
    // Realtime envelope from Frappe pub/sub or Redis stream
    final notifBlock = raw['notification'] is Map ? raw['notification'] as Map<String, dynamic> : <String, dynamic>{};
    final payloadBlock = raw['payload'] is Map ? Map<String, dynamic>.from(raw['payload'] as Map) : <String, dynamic>{};
    final dataBlock = raw['data'] is Map ? Map<String, dynamic>.from(raw['data'] as Map) : <String, dynamic>{};

    final eventName = raw['notification_event']?.toString() ??
        raw['event_name']?.toString() ??
        raw['event']?.toString() ??
        payloadBlock['event']?.toString() ??
        dataBlock['event']?.toString();

    final title = notifBlock['title']?.toString() ??
        raw['title']?.toString() ??
        payloadBlock['title']?.toString() ??
        dataBlock['title']?.toString() ??
        'Realtime Update';

    final body = notifBlock['body']?.toString() ??
        raw['body']?.toString() ??
        payloadBlock['body']?.toString() ??
        dataBlock['body']?.toString() ??
        '';

    final id = raw['event_id']?.toString() ??
        payloadBlock['event_id']?.toString() ??
        dataBlock['event_id']?.toString() ??
        raw['message_id']?.toString() ??
        'rt_${DateTime.now().millisecondsSinceEpoch}';

    final mergedData = {...dataBlock, ...payloadBlock};

    return AppNotification(
      id: id,
      event: NotificationEvent.fromString(eventName),
      channel: NotificationChannel.inAppRealtime,
      title: title,
      body: body,
      data: mergedData,
      sound: notifBlock['sound']?.toString(),
      priority: notifBlock['priority']?.toString() ?? 'normal',
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      event: NotificationEvent.fromString(json['event']?.toString()),
      channel: NotificationChannel.fromString(json['channel']?.toString()),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : {},
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['is_read'] == true || json['is_read'] == 1,
      sound: json['sound']?.toString(),
      priority: json['priority']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event': event.toWireName(),
      'channel': channel == NotificationChannel.fcm ? 'fcm' : 'in_app_realtime',
      'title': title,
      'body': body,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'sound': sound,
      'priority': priority,
    };
  }
}
