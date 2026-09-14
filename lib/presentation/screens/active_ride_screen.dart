import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../viewmodels/active_ride_viewmodel.dart';
import '../viewmodels/payment_status_viewmodel.dart';
import '../viewmodels/rating_viewmodel.dart';
import '../viewmodels/ride_viewmodel.dart';
import '../viewmodels/support_viewmodel.dart';
import 'payment_status_dialog.dart';
import 'rating_dialog.dart';

class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({super.key});

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final activeVm = context.read<ActiveRideViewModel>();
      if (activeVm.hasActiveRide) {
        activeVm.refreshActiveRide();
      } else {
        context.read<RideViewModel>().refreshActiveRide();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeVm = context.watch<ActiveRideViewModel>();
    final legacyRideVm = context.watch<RideViewModel>();

    // Support both activeVm and legacy rideVm
    final ride = activeVm.currentRide ?? legacyRideVm.currentRide;

    if (ride == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 64, color: AppColors.green),
              const SizedBox(height: 16),
              const Text('No Active Ride', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  activeVm.reset();
                  legacyRideVm.reset();
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    final driver = ride.driverDetails;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ride.isCompleted
              ? 'Trip Completed'
              : (ride.isSearching ? 'Searching for Driver' : 'Ride ${ride.id}'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          if (ride.canCancel)
            TextButton(
              onPressed: () => _showCancelDialog(context, activeVm, legacyRideVm),
              child: const Text('Cancel', style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            color: ride.isCompleted
                ? AppColors.greenSoft
                : (ride.isInProgress ? AppColors.navySoft : AppColors.navy),
            child: Row(
              children: [
                Icon(
                  ride.isCompleted
                      ? Icons.check_circle
                      : (ride.isInProgress ? Icons.navigation : Icons.access_time),
                  color: ride.isCompleted ? AppColors.green : Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusTitle(ride.status),
                        style: TextStyle(
                          color: ride.isCompleted ? AppColors.green : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        _getStatusSubtitle(ride.status),
                        style: TextStyle(
                          color: ride.isCompleted ? AppColors.ink : Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (ride.isSearching)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${activeVm.searchSecondsElapsed}s',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          // Live Map Area
          Expanded(
            child: Container(
              color: const Color(0xFFE5E9E0),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                          ),
                          child: Icon(
                            ride.isCompleted
                                ? Icons.done_all
                                : (ride.isInProgress
                                    ? Icons.directions_car
                                    : (ride.isSearching ? Icons.radar : Icons.local_taxi)),
                            size: 48,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ride.status.replaceAll('_', ' '),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navy),
                        ),
                        if (activeVm.driverLocation != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Driver GPS: ${activeVm.driverLocation!.latitude.toStringAsFixed(4)}, ${activeVm.driverLocation!.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Emergency SOS Button (visible during active trip)
                  if (ride.isInProgress)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: FloatingActionButton.extended(
                        backgroundColor: AppColors.coral,
                        icon: const Icon(Icons.warning, color: Colors.white),
                        label: const Text('EMERGENCY SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () => _triggerSos(context, ride.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Bottom Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.paperRaised,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 4-Digit Start OTP PIN Box (Crucial for Rider & Driver)
                if (ride.startOtp != null && !ride.isInProgress && !ride.isCompleted) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.coralSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TRIP START PIN',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.coral),
                            ),
                            Text(
                              'Share with driver upon entering vehicle',
                              style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                            ),
                          ],
                        ),
                        Text(
                          ride.startOtp!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4.0,
                            color: AppColors.coral,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Assigned Driver Card
                if (driver != null || ride.hasDriver) ...[
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.line),
                        ),
                        child: const Icon(Icons.person, color: AppColors.navy),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver?.name ?? (ride.driverDetails?.name ?? 'Assigned Driver'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              '${driver?.vehicleDescription ?? "Vehicle"} • ${driver?.licensePlate ?? "Verified"}',
                              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (driver != null && driver.rating > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.goldSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: AppColors.gold, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                driver.rating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.goldInk),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.line),
                ],
                // Addresses Summary
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride.pickupAddress,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ride.destinationAddress,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.inkSoft),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₦${ride.displayFare.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action Buttons
                if (ride.isCompleted) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _openRatingDialog(context, ride.id, driver?.name ?? 'Driver'),
                          child: const Text('Rate Driver'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _openPaymentDialog(context, ride.id, ride.displayFare),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                          child: const Text('Payment Status'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () {
                        activeVm.reset();
                        legacyRideVm.reset();
                      },
                      child: const Text('Back to Home'),
                    ),
                  ),
                ] else if (ride.isPaymentPending) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _openPaymentDialog(context, ride.id, ride.displayFare),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                      child: const Text('Confirm Payment Made'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'SEARCHING':
        return 'Searching for Drivers...';
      case 'DRIVER_ASSIGNED':
        return 'Driver Found!';
      case 'DRIVER_ACCEPTED':
      case 'DRIVER_EN_ROUTE':
        return 'Driver En Route to Pickup';
      case 'DRIVER_ARRIVED':
        return 'Driver Has Arrived!';
      case 'TRIP_STARTED':
        return 'Trip In Progress';
      case 'TRIP_COMPLETED':
        return 'Arrived at Destination';
      case 'PAYMENT_PENDING':
        return 'Direct Payment Due';
      case 'PAYMENT_CONFIRMED':
        return 'Payment Confirmed';
      case 'CANCELLED':
        return 'Trip Cancelled';
      default:
        return status;
    }
  }

  String _getStatusSubtitle(String status) {
    switch (status) {
      case 'SEARCHING':
        return 'Broadcasting to nearby verified drivers';
      case 'DRIVER_ARRIVED':
        return 'Please meet driver with your 4-digit PIN';
      case 'TRIP_STARTED':
        return 'Heading to destination safely';
      case 'TRIP_COMPLETED':
      case 'PAYMENT_PENDING':
        return 'Direct Cash, Bank Transfer, or POS settlement';
      default:
        return 'Realtime live updates';
    }
  }

  void _showCancelDialog(BuildContext context, ActiveRideViewModel activeVm, RideViewModel legacyVm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Ride?'),
        content: const Text('Are you sure you want to cancel this ride request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Ride')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () async {
              Navigator.pop(ctx);
              await activeVm.cancelRide('Cancelled by rider');
              await legacyVm.cancelRide('Cancelled by rider');
            },
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }

  void _triggerSos(BuildContext context, String rideId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trigger Emergency SOS?', style: TextStyle(color: AppColors.coral)),
        content: const Text(
          'This will immediately alert our 24/7 Operations Desk and notify your emergency contacts with your live GPS location.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () async {
              Navigator.pop(ctx);
              final supportVm = context.read<SupportViewModel>();
              await supportVm.triggerEmergencySos(rideId: rideId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.coral,
                    content: Text('Emergency SOS alert sent! Operations team notified.'),
                  ),
                );
              }
            },
            child: const Text('SEND SOS NOW'),
          ),
        ],
      ),
    );
  }

  void _openPaymentDialog(BuildContext context, String rideId, double amount) {
    final paymentVm = context.read<PaymentStatusViewModel>();
    showDialog(
      context: context,
      builder: (_) => PaymentStatusDialog(
        rideId: rideId,
        amount: amount,
        paymentVm: paymentVm,
        onConfirmed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment confirmed recorded!')),
          );
        },
      ),
    );
  }

  void _openRatingDialog(BuildContext context, String rideId, String driverName) {
    final ratingVm = context.read<RatingViewModel>();
    showDialog(
      context: context,
      builder: (_) => RatingDialog(
        rideId: rideId,
        driverName: driverName,
        ratingVm: ratingVm,
        onSubmitted: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thank you for your rating!')),
          );
        },
      ),
    );
  }
}
