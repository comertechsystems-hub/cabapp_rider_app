import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../viewmodels/active_ride_viewmodel.dart';
import '../viewmodels/ride_viewmodel.dart';
import '../viewmodels/support_viewmodel.dart';

/// 14. Active Trip Screen
class ActiveTripScreen extends StatefulWidget {
  const ActiveTripScreen({super.key});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  Timer? _pollingTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        context.read<ActiveRideViewModel>().refreshActiveRide();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _checkTripCompleted(ActiveRideViewModel activeVm) {
    if (_hasNavigated || !mounted) return;

    final ride = activeVm.currentRide;
    if (ride != null && (activeVm.isCompleted || ride.isPaymentPending || ride.status == 'TRIP_COMPLETED')) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.payment,
            arguments: {
              'rideId': ride.id,
              'amount': ride.displayFare,
              'driverName': ride.driverDetails?.name ?? 'Driver',
            },
          );
        }
      });
    }
  }

  void _triggerSos(BuildContext context, String? rideId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trigger Emergency SOS?', style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.bold)),
        content: const Text(
          'This will immediately alert our 24/7 Operations Desk and notify your designated emergency contacts with your live GPS coordinates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () async {
              Navigator.pop(ctx);
              final supportVm = context.read<SupportViewModel>();
              await supportVm.triggerEmergencySos(rideId: rideId ?? 'EMERGENCY');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.coral,
                    content: Text('🚨 Emergency SOS alert sent! Operations team notified.'),
                  ),
                );
              }
            },
            child: const Text('SEND SOS NOW', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeVm = context.watch<ActiveRideViewModel>();
    final legacyVm = context.watch<RideViewModel>();
    final ride = activeVm.currentRide ?? legacyVm.currentRide;
    final driver = ride?.driverDetails;

    _checkTripCompleted(activeVm);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Trip In Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.navy),
            tooltip: 'Share Trip',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Trip tracking link copied to clipboard!')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status Alert Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.navy,
              child: const Row(
                children: [
                  Icon(Icons.navigation, color: AppColors.gold, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'En route to destination • Drive safe',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            // Live Navigation Map Mockup with Floating SOS
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFE5E9E0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: const Icon(Icons.directions_car, size: 52, color: AppColors.navy),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Heading towards Destination',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navy),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ride?.destinationAddress ?? 'Destination',
                            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (activeVm.driverLocation != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Live GPS: ${activeVm.driverLocation!.latitude.toStringAsFixed(4)}, ${activeVm.driverLocation!.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Floating Emergency SOS Button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: FloatingActionButton.extended(
                      heroTag: 'trip_sos_btn',
                      backgroundColor: AppColors.coral,
                      icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
                      label: const Text(
                        'EMERGENCY SOS',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: () => _triggerSos(context, ride?.id),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Trip Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Driver details
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.navySoft,
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
                              driver?.name ?? 'Driver',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              '${driver?.vehicleDescription ?? "Vehicle"} • ${driver?.licensePlate ?? "Plate"}',
                              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₦${(ride?.displayFare ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.line),

                  // Destination address info
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.coral, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DROPOFF LOCATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.inkSoft)),
                            const SizedBox(height: 2),
                            Text(
                              ride?.destinationAddress ?? 'Destination',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Proceed to Payment CTA (also triggers automatically upon trip completion)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.payment,
                          arguments: {
                            'rideId': ride?.id,
                            'amount': ride?.displayFare,
                            'driverName': driver?.name ?? 'Driver',
                          },
                        );
                      },
                      child: const Text('Arrived? Proceed to Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
}
