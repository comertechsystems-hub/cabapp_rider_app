import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../viewmodels/ride_viewmodel.dart';

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
    // Poll backend periodically for state sync (complements Socket.IO / Push notifications)
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      context.read<RideViewModel>().refreshActiveRide();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rideVm = context.watch<RideViewModel>();
    final ride = rideVm.currentRide;

    if (ride == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => rideVm.reset(),
            child: const Text('Back to Home'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ride.isCompleted ? 'Trip Completed' : 'Ride ${ride.id}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          if (!ride.isCompleted && !ride.isInProgress)
            TextButton(
              onPressed: () => _showCancelDialog(context, rideVm),
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
                : ride.isInProgress
                    ? AppColors.navySoft
                    : AppColors.navy,
            child: Row(
              children: [
                Icon(
                  ride.isCompleted
                      ? Icons.check_circle
                      : ride.isInProgress
                          ? Icons.navigation
                          : Icons.access_time,
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
              ],
            ),
          ),
          // Tracking Map Area
          Expanded(
            child: Container(
              color: const Color(0xFFE5E9E0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                      ),
                      child: Icon(
                        ride.isCompleted
                            ? Icons.done_all
                            : ride.isInProgress
                                ? Icons.directions_car
                                : Icons.radar,
                        size: 48,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ride.status.replaceAll('_', ' '),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navy),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Details Card
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
                // Start OTP Pin Box
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
                              'Share with driver upon pickup',
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
                // Driver & Vehicle Card
                if (ride.driver != null) ...[
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
                              ride.driverName ?? 'Driver Assigned',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              'Vehicle: ${ride.vehicle ?? "Verified"} • ${ride.vehicleCategory}',
                              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.line),
                ],
                // Fare & P2P Settlement
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Direct Fare (100% to Driver)', style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                        Text('Direct Cash or Bank Transfer', style: TextStyle(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(
                      '₦${(ride.finalFare ?? ride.totalFare).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action Buttons
                if (ride.isCompleted)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => rideVm.reset(),
                      child: const Text('Back to Home'),
                    ),
                  )
                else if (ride.status == 'PAYMENT_PENDING')
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => rideVm.confirmPayment(),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                      child: const Text('Confirm Payment Paid'),
                    ),
                  ),
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
        return 'Driver is on the way';
      case 'DRIVER_EN_ROUTE':
        return 'Driver en route to pickup';
      case 'DRIVER_ARRIVED':
        return 'Driver has arrived!';
      case 'TRIP_STARTED':
        return 'Trip In Progress';
      case 'TRIP_COMPLETED':
        return 'Arrived at Destination';
      case 'PAYMENT_CONFIRMED':
        return 'Payment Settled';
      default:
        return status;
    }
  }

  String _getStatusSubtitle(String status) {
    switch (status) {
      case 'SEARCHING':
        return 'Connecting with nearby vehicle partners';
      case 'DRIVER_ARRIVED':
        return 'Please meet your driver at the pickup location';
      case 'TRIP_STARTED':
        return 'Heading to destination safely';
      case 'TRIP_COMPLETED':
        return 'Please settle fare directly with driver';
      default:
        return 'Live updates enabled';
    }
  }

  void _showCancelDialog(BuildContext context, RideViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Ride?'),
        content: const Text('Are you sure you want to cancel this ride request? Cancellation fees may apply if driver is already en route.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Ride'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () {
              Navigator.pop(ctx);
              vm.cancelRide('Cancelled by rider from app');
            },
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }
}
