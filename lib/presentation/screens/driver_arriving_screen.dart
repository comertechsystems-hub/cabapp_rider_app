import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../viewmodels/active_ride_viewmodel.dart';
import '../viewmodels/ride_viewmodel.dart';
import '../widgets/interactive_live_map.dart';

/// 13. Driver Arriving Screen
class DriverArrivingScreen extends StatefulWidget {
  const DriverArrivingScreen({super.key});

  @override
  State<DriverArrivingScreen> createState() => _DriverArrivingScreenState();
}

class _DriverArrivingScreenState extends State<DriverArrivingScreen> {
  Timer? _pollingTimer;
  bool _hasNavigated = false;
  bool _showAcceptedBanner = true;

  @override
  void initState() {
    super.initState();
    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (mounted) {
          context.read<ActiveRideViewModel>().refreshActiveRide();
        }
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _checkTripStarted(ActiveRideViewModel activeVm) {
    if (_hasNavigated || !mounted) return;

    final ride = activeVm.currentRide;
    if (ride != null && (activeVm.isInProgress || ride.status == 'TRIP_STARTED')) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.activeTrip);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeVm = context.watch<ActiveRideViewModel>();
    final legacyVm = context.watch<RideViewModel>();
    final ride = activeVm.currentRide ?? legacyVm.currentRide;
    final driver = ride?.driverDetails;

    _checkTripStarted(activeVm);

    final bool hasArrived = ride?.status == 'DRIVER_ARRIVED';

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text(
          hasArrived ? 'Driver Has Arrived!' : 'Driver En Route',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _confirmCancel(context, activeVm, legacyVm),
        ),
        actions: [
          TextButton(
            onPressed: () => _confirmCancel(context, activeVm, legacyVm),
            child: const Text('Cancel', style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Driver Acceptance Notification Banner
            if (_showAcceptedBanner || activeVm.justAcceptedRide != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.greenSoft,
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.green, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ride Request Accepted! ${driver?.name ?? ride?.driverName ?? "Your driver"} is on the way.',
                        style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.inkSoft, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _showAcceptedBanner = false;
                        });
                        activeVm.clearJustAcceptedRide();
                      },
                    ),
                  ],
                ),
              ),

            // Status Alert Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: hasArrived ? AppColors.green : AppColors.navy,
              child: Row(
                children: [
                  Icon(
                    hasArrived ? Icons.where_to_vote : Icons.directions_car,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasArrived
                          ? 'Your driver is waiting at the pickup spot!'
                          : 'Driver is heading towards your pickup location',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            // Live Map
            Expanded(
              child: InteractiveLiveMap(
                pickupLat: ride?.pickupLat ?? 6.4281,
                pickupLng: ride?.pickupLng ?? 3.4219,
                pickupAddress: ride?.pickupAddress ?? 'Pickup',
                destinationLat: ride?.destinationLat ?? 6.4474,
                destinationLng: ride?.destinationLng ?? 3.4723,
                destinationAddress: ride?.destinationAddress ?? 'Destination',
                driverLat: activeVm.driverLocation?.latitude ?? ride?.driverLat,
                driverLng: activeVm.driverLocation?.longitude ?? ride?.driverLng,
                isDriverEnRouteToPickup: true,
                driverEtaMins: ride?.driverEtaMins,
                driverDistanceKm: ride?.driverDistanceKm,
                driverName: driver?.name ?? ride?.driverName,
              ),
            ),

            // Bottom Panel
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prominent 4-digit Start OTP PIN
                  if (ride?.startOtp != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.coralSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.coral.withValues(alpha: 0.4)),
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
                                'Share with driver when boarding',
                                style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                              ),
                            ],
                          ),
                          Text(
                            ride!.startOtp!,
                            style: const TextStyle(
                              fontSize: 26,
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

                  // Driver Details Row
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.navySoft,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.line),
                        ),
                        child: const Icon(Icons.person, color: AppColors.navy, size: 30),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver?.name ?? 'Assigned Driver',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

                  // Call / Message Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.call, size: 18, color: AppColors.navy),
                          label: const Text('Call Driver', style: TextStyle(color: AppColors.navy)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Calling driver...')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.message, size: 18, color: AppColors.navy),
                          label: const Text('Message', style: TextStyle(color: AppColors.navy)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Opening chat with driver...')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Manual trip start transition shortcut if already in vehicle
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.activeTrip);
                      },
                      child: const Text('View Active Trip', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context, ActiveRideViewModel activeVm, RideViewModel legacyVm) {
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
              activeVm.reset();
              legacyVm.reset();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
              }
            },
            child: const Text('Cancel Ride', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
