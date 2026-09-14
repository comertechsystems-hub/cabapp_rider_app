import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../models/app_notification.dart';
import '../models/notification_event.dart';

/// Floating animated banner rendered for in-app foreground notification alerts
class InAppNotificationBanner extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const InAppNotificationBanner({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  IconData _getEventIcon(NotificationEvent event) {
    switch (event) {
      case NotificationEvent.rideRequest:
        return Icons.local_taxi_rounded;
      case NotificationEvent.driverAccepted:
        return Icons.directions_car_filled_rounded;
      case NotificationEvent.driverArriving:
        return Icons.pin_drop_rounded;
      case NotificationEvent.tripStarted:
        return Icons.navigation_rounded;
      case NotificationEvent.tripCompleted:
        return Icons.flag_circle_rounded;
      case NotificationEvent.paymentPending:
        return Icons.payment_rounded;
      case NotificationEvent.paymentConfirmed:
        return Icons.check_circle_rounded;
      case NotificationEvent.subscriptionExpiring:
        return Icons.alarm_rounded;
      case NotificationEvent.subscriptionExpired:
        return Icons.warning_amber_rounded;
      case NotificationEvent.supportUpdate:
        return Icons.support_agent_rounded;
      case NotificationEvent.unknown:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getEventColor(NotificationEvent event) {
    switch (event) {
      case NotificationEvent.rideRequest:
      case NotificationEvent.driverAccepted:
      case NotificationEvent.driverArriving:
      case NotificationEvent.tripStarted:
        return AppColors.green;
      case NotificationEvent.tripCompleted:
      case NotificationEvent.paymentConfirmed:
        return AppColors.green;
      case NotificationEvent.paymentPending:
      case NotificationEvent.subscriptionExpiring:
        return AppColors.gold;
      case NotificationEvent.subscriptionExpired:
        return AppColors.coral;
      case NotificationEvent.supportUpdate:
        return Colors.blueAccent;
      case NotificationEvent.unknown:
        return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventColor = _getEventColor(notification.event);
    final iconData = _getEventIcon(notification.event);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: eventColor.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 16.0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: eventColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: eventColor, size: 24.0),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3.0),
                        Text(
                          notification.body,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12.0,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (onDismiss != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 18.0),
                      onPressed: onDismiss,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
