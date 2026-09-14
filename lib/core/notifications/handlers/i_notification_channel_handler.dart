import '../models/app_notification.dart';
import '../models/notification_channel.dart';

/// Abstract handler contract for an individual delivery channel
abstract class INotificationChannelHandler {
  NotificationChannel get channel;

  void setNotificationListener(void Function(AppNotification notification) listener);

  Future<void> initialize();

  void dispose();
}
