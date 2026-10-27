import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../viewmodels/active_ride_viewmodel.dart';
import '../viewmodels/payment_status_viewmodel.dart';
import '../viewmodels/rating_viewmodel.dart';
import '../viewmodels/ride_viewmodel.dart';
import '../viewmodels/support_viewmodel.dart';
import '../widgets/interactive_live_map.dart';
import 'payment_status_dialog.dart';
import 'rating_dialog.dart';

class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({super.key});

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  Timer? _pollingTimer;
  String? _lastNotifiedAcceptedRideId;
  String? _lastNotifiedOfferId;
  bool _showAcceptanceBanner = false;

  @override
  void initState() {
    super.initState();
    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        final activeVm = context.read<ActiveRideViewModel>();
        if (activeVm.hasActiveRide) {
          activeVm.refreshActiveRide();
        } else {
          context.read<RideViewModel>().refreshActiveRide();
        }
      });
    }
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
    final isAcceptedOrEnRoute = ride.isDriverAccepted || ride.isDriverEnRoute;

    // Detect driver acceptance transition and notify rider in-app
    if (isAcceptedOrEnRoute && _lastNotifiedAcceptedRideId != ride.id) {
      _lastNotifiedAcceptedRideId = ride.id;
      _showAcceptanceBanner = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.green,
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Driver Accepted! ${driver?.name ?? ride.driverName ?? "Your driver"} is on the way.',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }

    // Detect new driver counter-offer arrival and notify rider with haptics & chime
    if (activeVm.driverOffers.isNotEmpty) {
      final topOffer = activeVm.driverOffers.first;
      final topOfferId = topOffer['name']?.toString();
      if (topOfferId != null && topOfferId != _lastNotifiedOfferId) {
        _lastNotifiedOfferId = topOfferId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          HapticFeedback.heavyImpact();
          SystemSound.play(SystemSoundType.alert);
        });
      }
    }

    final chatMessages = ride.chatMessages;
    final driverMessages = chatMessages.where((m) => m['sender_role'] == 'DRIVER').toList();
    final lastDriverMessage = driverMessages.isNotEmpty ? driverMessages.last : null;
    final hasAssignedDriver = !ride.isSearching && !ride.isDriverAssigned && !ride.isCancelled;

    return Scaffold(
      appBar: AppBar(
        leading: (ride.isCancelled || ride.isCompleted)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  activeVm.reset();
                  legacyRideVm.reset();
                },
              )
            : null,
        title: Text(
          ride.isCompleted
              ? 'Trip Completed'
              : (ride.isCancelled
                  ? 'Trip Cancelled'
                  : ((ride.isSearching || ride.isDriverAssigned) ? 'Searching for Driver' : 'Ride ${ride.id}')),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          if (hasAssignedDriver && !ride.isCompleted)
            IconButton(
              tooltip: 'Chat with Driver',
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.chat_bubble_outline, color: AppColors.navy),
                  if (driverMessages.isNotEmpty)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.coral,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => _showChatModal(
                context,
                activeVm,
                legacyRideVm,
                ride.id,
                driver?.name ?? ride.driverName ?? 'Driver',
              ),
            ),
          if (ride.canCancel)
            TextButton(
              onPressed: () => _showCancelDialog(context, activeVm, legacyRideVm),
              child: const Text('Cancel', style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          children: [
            // Acceptance In-App Notification Banner
            if (_showAcceptanceBanner && isAcceptedOrEnRoute)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.green,
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ride Request Accepted',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            '${driver?.name ?? ride.driverName ?? "Driver"} accepted and is heading to your pickup.',
                            style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                      onPressed: () => setState(() => _showAcceptanceBanner = false),
                    ),
                  ],
                ),
              ),
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: ride.isCompleted
                  ? AppColors.greenSoft
                  : (ride.isInProgress ? const Color(0xFF1E3A8A) : AppColors.navy),
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
                            fontSize: 14.5,
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
                  if (ride.isSearching || ride.isDriverAssigned)
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
                    )
                  else if (isAcceptedOrEnRoute || ride.isInProgress)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: ride.isInProgress ? Colors.white24 : AppColors.green,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '~${(ride.driverEtaMins ?? (ride.isInProgress ? 12.0 : 3.0)).toStringAsFixed(0)} min · ${(ride.driverDistanceKm ?? (ride.isInProgress ? 4.5 : 0.7)).toStringAsFixed(1)} km',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                    ),
                ],
              ),
            ),
            // Live Map Area
            Expanded(
              child: Stack(
                children: [
                  InteractiveLiveMap(
                    pickupLat: ride.pickupLat,
                    pickupLng: ride.pickupLng,
                    pickupAddress: ride.pickupAddress,
                    destinationLat: ride.destinationLat,
                    destinationLng: ride.destinationLng,
                    destinationAddress: ride.destinationAddress,
                    driverLat: activeVm.driverLocation?.latitude ?? ride.driverLat,
                    driverLng: activeVm.driverLocation?.longitude ?? ride.driverLng,
                    isDriverEnRouteToPickup: isAcceptedOrEnRoute,
                    isTripStarted: ride.isInProgress,
                    driverEtaMins: ride.driverEtaMins,
                    driverDistanceKm: ride.driverDistanceKm,
                    driverName: driver?.name ?? ride.driverName,
                  ),
                  // Emergency SOS Button (docked at bottom-left so it never overlaps the top "Heading to Destination" pill)
                  if (ride.isInProgress)
                    Positioned(
                      bottom: 14,
                      left: 14,
                      child: Material(
                        color: Colors.transparent,
                        elevation: 5,
                        shadowColor: AppColors.coral.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(100),
                        child: InkWell(
                          onTap: () => _triggerSos(context, ride.id),
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD92D20), AppColors.coral],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.shield_outlined, color: Colors.white, size: 14),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'EMERGENCY SOS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Bottom Card (Scroll-safe for all Android screens)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.58,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: const BoxDecoration(
                  color: AppColors.paperRaised,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 4-Digit Start OTP PIN Box (Crucial for Rider & Driver)
                      if (ride.startOtp != null && !ride.isSearching && !ride.isDriverAssigned && !ride.isInProgress && !ride.isCompleted) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                    style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
                                  ),
                                ],
                              ),
                              Text(
                                ride.startOtp!,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4.0,
                                  color: AppColors.coral,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Connecting radar while searching or awaiting driver accept
                      if (ride.isSearching || ride.isDriverAssigned) ...[
                        // Live Incoming Driver Counter-Offers List (Prominently Placed at the Top)
                        if (activeVm.driverOffers.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.gold, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(Icons.local_offer, color: AppColors.gold, size: 16),
                                        SizedBox(width: 6),
                                        Text(
                                          'INCOMING DRIVER COUNTER-OFFERS',
                                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.ink),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.goldSoft,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${activeVm.driverOffers.length} available',
                                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.ink),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.goldSoft,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.local_gas_station, size: 14, color: AppColors.ink),
                                      const SizedBox(width: 6),
                                      Builder(
                                        builder: (ctx) {
                                          final fPrice = ride.fuelPriceApplied ?? 1400.0;
                                          final fCost = (ride.fuelCostEstimated != null && ride.fuelCostEstimated! > 0)
                                              ? ride.fuelCostEstimated!
                                              : (((ride.actualDistanceKm ?? 5.0) / 12.0) * fPrice);
                                          return Expanded(
                                            child: Text(
                                              '⛽ Fuel Benchmark: ~₦${fCost.clamp(300, 999999).toStringAsFixed(0)} (PMS ₦${fPrice.toStringAsFixed(0)}/L at 12 km/L) · 30s window',
                                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.ink),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...activeVm.driverOffers.map((offer) {
                                  final pFare = (offer['proposed_fare'] as num?)?.toDouble() ?? 0.0;
                                  final dName = offer['driver_name']?.toString() ?? 'Driver Partner';
                                  final vModel = offer['vehicle_model']?.toString() ?? 'Cab';
                                  final dRating = (offer['driver_rating'] as num?)?.toDouble() ?? 5.0;
                                  final eta = (offer['eta_mins'] as num?)?.toDouble() ?? 5.0;
                                  final note = offer['note']?.toString();
                                  final secLeft = (offer['seconds_remaining'] as num?)?.toInt() ?? 30;

                                  return Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.line),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(dName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                        decoration: BoxDecoration(
                                                          color: secLeft <= 5 ? AppColors.coralSoft : AppColors.goldSoft,
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          '⏳ ${secLeft}s left',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: secLeft <= 5 ? AppColors.coral : AppColors.ink,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '$vModel • ⭐ ${dRating.toStringAsFixed(1)} • ~${eta.toStringAsFixed(0)} mins away',
                                                    style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '₦${pFare.toStringAsFixed(0)}',
                                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.navy),
                                            ),
                                          ],
                                        ),
                                        if (note != null && note.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '"$note"',
                                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.inkSoft),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: SizedBox(
                                                height: 36,
                                                child: OutlinedButton(
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: AppColors.coral,
                                                    side: const BorderSide(color: AppColors.coral),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    padding: const EdgeInsets.symmetric(vertical: 0),
                                                  ),
                                                  onPressed: () async {
                                                    final offerId = offer['name']?.toString();
                                                    if (offerId != null) {
                                                      await activeVm.declineCounterOffer(offerId);
                                                    }
                                                  },
                                                  child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 2,
                                              child: SizedBox(
                                                height: 36,
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.navy,
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    padding: const EdgeInsets.symmetric(vertical: 0),
                                                  ),
                                                  onPressed: () async {
                                                    final offerId = offer['name']?.toString();
                                                    if (offerId != null) {
                                                      await activeVm.acceptCounterOffer(offerId);
                                                    }
                                                  },
                                                  child: Text(
                                                    'Agree & Accept (₦${pFare.toStringAsFixed(0)})',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.navy),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ride.isDriverAssigned
                                        ? 'Ride offered to nearby driver...'
                                        : 'Connecting with closest driver...',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink),
                                  ),
                                  Text(
                                    ride.isDriverAssigned
                                        ? 'Awaiting driver mobile confirmation'
                                        : 'Broadcasting offer across verified drivers',
                                    style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAECF3),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '● ${activeVm.searchSecondsElapsed}s',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navy),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Rider's Current Active Bid & Fast Raise Controls
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'YOUR CURRENT BID',
                                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.inkSoft),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₦${(ride.offeredFare ?? ride.totalFare).toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.navy),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.navy,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Bidding Open',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Drivers may accept or send counter-offers. Want faster pickup? Raise your offer:',
                                style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ActionChip(
                                    avatar: const Icon(Icons.arrow_upward, size: 12, color: AppColors.navy),
                                    label: const Text('+₦200', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () async {
                                      final ok = await activeVm.raiseOffer(200);
                                      if (ok && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Offer raised by ₦200! Broadcasters notified.'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  ActionChip(
                                    avatar: const Icon(Icons.arrow_upward, size: 12, color: AppColors.navy),
                                    label: const Text('+₦500', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () async {
                                      final ok = await activeVm.raiseOffer(500);
                                      if (ok && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Offer raised by ₦500! Broadcasters notified.'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  ActionChip(
                                    avatar: const Icon(Icons.arrow_upward, size: 12, color: AppColors.navy),
                                    label: const Text('+₦1,000', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () async {
                                      final ok = await activeVm.raiseOffer(1000);
                                      if (ok && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Offer raised by ₦1,000! Broadcasters notified.'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Assigned Driver Card + Call / Chat Actions (Displayed once driver ACCEPTS or is active)
                      if (hasAssignedDriver) ...[
                        if (lastDriverMessage != null) ...[
                          InkWell(
                            onTap: () => _showChatModal(
                              context,
                              activeVm,
                              legacyRideVm,
                              ride.id,
                              driver?.name ?? ride.driverName ?? 'Driver',
                            ),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.navySoft,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.navy.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.chat_bubble, size: 15, color: AppColors.navy),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${driver?.name ?? "Driver"}: "${lastDriverMessage['message'] ?? ''}"',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Text(
                                    'Reply',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
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
                                    driver?.name ?? (ride.driverName ?? 'Assigned Driver'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Text(
                                    '${driver?.vehicleDescription ?? "Vehicle"} • ${driver?.licensePlate ?? "Verified"}',
                                    style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
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
                        if (!ride.isCompleted) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    side: const BorderSide(color: AppColors.line),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.call, size: 17, color: AppColors.navy),
                                  label: const Text(
                                    'Call Driver',
                                    style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  onPressed: () async {
                                    final phone = driver?.phoneNumber ?? '+2348000000000';
                                    await Clipboard.setData(ClipboardData(text: phone));
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Driver phone ($phone) copied · Ready to call')),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.navy,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      const Icon(Icons.chat_bubble_outline, size: 17, color: Colors.white),
                                      if (driverMessages.isNotEmpty)
                                        Positioned(
                                          right: -4,
                                          top: -4,
                                          child: Container(
                                            width: 9,
                                            height: 9,
                                            decoration: const BoxDecoration(
                                              color: AppColors.coral,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  label: Text(
                                    chatMessages.isNotEmpty
                                        ? 'Chat (${chatMessages.length})'
                                        : 'Chat with Driver',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  onPressed: () => _showChatModal(
                                    context,
                                    activeVm,
                                    legacyRideVm,
                                    ride.id,
                                    driver?.name ?? ride.driverName ?? 'Driver',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const Divider(height: 20, color: AppColors.line),
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
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
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
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => _openPaymentDialog(context, ride.id, ride.displayFare),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                            child: const Text('Confirm Payment Made'),
                          ),
                        ),
                      ] else if (ride.isCancelled) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              activeVm.reset();
                              legacyRideVm.reset();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navy,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text(
                              'Back to Home / Book Again',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'SEARCHING':
        return 'Searching for Drivers...';
      case 'DRIVER_ASSIGNED':
        return 'Contacting Nearby Driver...';
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
      case 'DRIVER_ASSIGNED':
        return 'Ride offer sent, awaiting driver confirmation';
      case 'DRIVER_ACCEPTED':
      case 'DRIVER_EN_ROUTE':
        return 'Driver is heading to your pickup location';
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
              activeVm.reset();
              legacyVm.reset();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.coralSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield, color: AppColors.coral, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Trigger Emergency SOS?',
                style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will immediately alert our 24/7 Operations Desk and notify your emergency contacts with your live GPS location.',
              style: TextStyle(fontSize: 13.5, color: AppColors.ink),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () async {
                await Clipboard.setData(const ClipboardData(text: '112'));
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nigeria Emergency Number (112 / 767) copied to dialer')),
                  );
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.line),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.phone_in_talk, color: AppColors.coral, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('National Emergency Line: 112 / 767', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                          Text('Tap to copy emergency number', style: TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
            child: const Text('SEND SOS NOW', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _showChatModal(
    BuildContext context,
    ActiveRideViewModel activeVm,
    RideViewModel legacyVm,
    String rideId,
    String driverName,
  ) {
    final textController = TextEditingController();
    final presets = [
      "I'm waiting at the pickup spot.",
      "I'll be right out in 1 minute.",
      "Please call me when you arrive at the gate.",
      "What color is your vehicle?",
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paperRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Consumer2<ActiveRideViewModel, RideViewModel>(
              builder: (ctx, liveActiveVm, liveLegacyVm, _) {
                final liveRide = liveActiveVm.currentRide ?? liveLegacyVm.currentRide;
                final messages = liveRide?.chatMessages ?? const [];

                Future<void> sendMessage(String text) async {
                  final trimmed = text.trim();
                  if (trimmed.isEmpty) return;
                  textController.clear();
                  if (liveActiveVm.currentRide != null) {
                    await liveActiveVm.sendChatMessage(trimmed, overrideRideId: rideId);
                  } else {
                    await liveLegacyVm.sendChatMessage(trimmed);
                  }
                  if (ctx.mounted) {
                    setSheetState(() {});
                  }
                }

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  ),
                  child: SafeArea(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(ctx).size.height * 0.72,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.chat_bubble, color: AppColors.navy, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Chat with $driverName',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20, color: AppColors.inkSoft),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ],
                            ),
                            const Divider(height: 12, color: AppColors.line),
                            Flexible(
                              child: messages.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: Center(
                                        child: Text(
                                          'Send a message to $driverName or tap a quick reply below.',
                                          style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: messages.length,
                                      itemBuilder: (context, idx) {
                                        final m = messages[idx];
                                        final isRider = m['sender_role'] == 'RIDER';
                                        return Align(
                                          alignment: isRider ? Alignment.centerRight : Alignment.centerLeft,
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(vertical: 4),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            constraints: BoxConstraints(
                                              maxWidth: MediaQuery.of(ctx).size.width * 0.75,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isRider ? AppColors.navy : AppColors.paper,
                                              borderRadius: BorderRadius.circular(12),
                                              border: isRider ? null : Border.all(color: AppColors.line),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  isRider ? 'You' : (m['sender_name']?.toString() ?? driverName),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isRider ? Colors.white70 : AppColors.navy,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  m['message']?.toString() ?? '',
                                                  style: TextStyle(
                                                    fontSize: 13.5,
                                                    color: isRider ? Colors.white : AppColors.ink,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 34,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: presets.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 6),
                                itemBuilder: (context, i) {
                                  final msg = presets[i];
                                  return ActionChip(
                                    label: Text(msg, style: const TextStyle(fontSize: 11.5, color: AppColors.ink)),
                                    backgroundColor: AppColors.paper,
                                    onPressed: () => sendMessage(msg),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: textController,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: sendMessage,
                                    decoration: InputDecoration(
                                      hintText: 'Type message to $driverName...',
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: AppColors.line),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.navy,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => sendMessage(textController.text),
                                  child: const Icon(Icons.send, size: 18),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
