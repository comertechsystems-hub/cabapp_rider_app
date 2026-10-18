import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../viewmodels/active_ride_viewmodel.dart';
import '../viewmodels/ride_viewmodel.dart';
import '../viewmodels/support_viewmodel.dart';
import '../widgets/interactive_live_map.dart';

/// 14. Active Trip Screen (r-trip from Cabapp UIUX mockup)
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

  void _confirmCancelTrip(BuildContext context, ActiveRideViewModel activeVm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Trip?'),
        content: const Text('Are you sure you want to cancel this trip? A cancellation fee may apply if the driver has arrived.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Trip'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () async {
              Navigator.pop(ctx);
              await activeVm.cancelRide('Rider cancelled from active trip');
              activeVm.reset();
              if (context.mounted) {
                context.read<RideViewModel>().reset();
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
              }
            },
            child: const Text('Cancel Trip', style: TextStyle(color: Colors.white)),
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

    final statusText = activeVm.isDriverArriving
        ? 'Arrived at pickup'
        : (activeVm.isInProgress ? 'Trip in progress' : 'En route to pickup');

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Trip In Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (activeVm.isCancelled || activeVm.isCompleted) {
              activeVm.reset();
              context.read<RideViewModel>().reset();
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
            } else {
              _confirmCancelTrip(context, activeVm);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.coral),
            tooltip: 'Cancel Trip',
            onPressed: () => _confirmCancelTrip(context, activeVm),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.navy),
            tooltip: 'Share Trip',
            onPressed: () async {
              final trackUrl = 'https://cabapp.com.ng/track?id=${ride?.id ?? ""}';
              final shareText =
                  'CabApp Live Trip: Riding with ${driver?.name ?? ride?.driverName ?? "Babatunde A."} (${driver?.vehicleDescription ?? "Toyota Corolla"} · ${driver?.licensePlate ?? "KJA 442 XL"}). Track live: $trackUrl';
              await Clipboard.setData(ClipboardData(text: shareText));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Live trip link copied: $trackUrl'),
                  backgroundColor: AppColors.navy,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Live Interactive Map Canvas
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    InteractiveLiveMap(
                      pickupLat: ride?.pickupLat ?? 6.4281,
                      pickupLng: ride?.pickupLng ?? 3.4219,
                      pickupAddress: ride?.pickupAddress ?? 'Pickup',
                      destinationLat: ride?.destinationLat ?? 6.4474,
                      destinationLng: ride?.destinationLng ?? 3.4723,
                      destinationAddress: ride?.destinationAddress ?? 'Destination',
                      driverLat: activeVm.driverLocation?.latitude ?? ride?.driverLat,
                      driverLng: activeVm.driverLocation?.longitude ?? ride?.driverLng,
                      isTripStarted: true,
                      driverEtaMins: ride?.driverEtaMins,
                      driverDistanceKm: ride?.driverDistanceKm,
                      driverName: driver?.name ?? ride?.driverName,
                    ),
                    // Floating SOS Button in top-right corner
                    Positioned(
                      top: 12,
                      right: 12,
                      child: ElevatedButton.icon(
                        onPressed: () => _triggerSos(context, ride?.id),
                        icon: const Icon(Icons.shield, size: 16, color: Colors.white),
                        label: const Text('EMERGENCY SOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Panel from r-trip mockup
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAECF3),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.navy,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Driver Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.paperRaised,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: const BoxDecoration(
                                color: AppColors.navy,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                (driver?.name.isNotEmpty == true ? driver!.name[0] : 'B').toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driver?.name ?? 'Babatunde A.',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.ink),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  driver?.vehicleDescription ?? 'Toyota Corolla · Silver · KJA 442 XL',
                                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '★ ${driver?.rating.toStringAsFixed(1) ?? "4.9"}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Side-by-side stats: Driver ETA & Fare locked
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: AppColors.paperRaised,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '3 min',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink),
                              ),
                              SizedBox(height: 2),
                              Text('Driver ETA', style: TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: AppColors.paperRaised,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₦${(ride?.totalFare ?? 5600).toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink),
                              ),
                              const SizedBox(height: 2),
                              const Text('Fare locked', style: TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons from r-trip
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () async {
                        final phone = driver?.phoneNumber ?? '+2348000000000';
                        await Clipboard.setData(ClipboardData(text: phone));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling driver: $phone')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.line, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      ),
                      child: const Text(
                        'Message driver',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.ink),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => _confirmCancelTrip(context, activeVm),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      ),
                      child: const Text(
                        'Cancel trip',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
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
                      child: const Text('Arrived? Proceed to Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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

class _MapCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final highwayPaint = Paint()
      ..color = const Color(0xFFFDE68A)
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke;

    // Horizontal roads
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.3), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.6), Offset(size.width, size.height * 0.6), highwayPaint);
    canvas.drawLine(Offset(0, size.height * 0.8), Offset(size.width, size.height * 0.8), roadPaint);

    // Vertical roads
    canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width * 0.25, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.75, size.height), roadPaint);

    // Route polyline matching SVG in r-trip: M20 170 Q100 90 180 100 T300 40
    final routePaint = Paint()
      ..color = AppColors.navy
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.4, size.width * 0.55, size.height * 0.45)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.5, size.width * 0.85, size.height * 0.18);

    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapPinBadge extends StatelessWidget {
  final bool isPickup;
  const _MapPinBadge({required this.isPickup});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isPickup ? AppColors.navy : AppColors.coral,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
