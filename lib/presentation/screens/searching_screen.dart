import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../viewmodels/active_ride_viewmodel.dart';
import '../viewmodels/ride_viewmodel.dart';

/// 11. Searching For Driver Screen
class SearchingScreen extends StatefulWidget {
  const SearchingScreen({super.key});

  @override
  State<SearchingScreen> createState() => _SearchingScreenState();
}

class _SearchingScreenState extends State<SearchingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _pollingTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (mounted) {
          context.read<ActiveRideViewModel>().refreshActiveRide();
        }
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _checkDriverAssigned(ActiveRideViewModel activeVm) {
    if (_hasNavigated || !mounted) return;

    final ride = activeVm.currentRide;
    if (ride != null) {
      if (ride.isDriverAccepted || ride.isDriverOnTheWay || activeVm.isDriverArriving) {
        _hasNavigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.driverArriving);
          }
        });
      }
    }
  }

  void _showCancelDialog(BuildContext context, ActiveRideViewModel activeVm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Search?'),
        content: const Text('Are you sure you want to cancel the driver search?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Searching'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () async {
              Navigator.pop(ctx);
              await activeVm.cancelRide('Cancelled by rider');
              activeVm.reset();
              if (context.mounted) {
                context.read<RideViewModel>().reset();
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
              }
            },
            child: const Text('Cancel Ride'),
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

    _checkDriverAssigned(activeVm);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Searching for Driver', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _showCancelDialog(context, activeVm),
        ),
        actions: [
          TextButton(
            onPressed: () => _showCancelDialog(context, activeVm),
            child: const Text('Cancel', style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Double Ring Matching Graphic from r-match
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer gold ring pulsing
                      Container(
                        width: 96 * _pulseAnimation.value,
                        height: 96 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.5),
                            width: 3,
                          ),
                        ),
                      ),
                      // Inner navy ring
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.navy,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          color: AppColors.navy,
                          size: 36,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              Text(
                (ride?.isDriverAssigned == true)
                    ? 'Driver Found · Awaiting Acceptance...'
                    : 'Connecting with Drivers...',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  (ride?.isDriverAssigned == true)
                      ? 'We have sent your ride request to a nearby driver. Waiting for driver confirmation...'
                      : 'Matching you with a verified driver nearby. This usually takes under a minute.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),

              // Elapsed time pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAECF3),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '● ${activeVm.searchSecondsElapsed}s elapsed',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.navy),
                ),
              ),
              const SizedBox(height: 14),

              // Current Offer & Fast Raise Chips
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'YOUR CURRENT OFFER',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.inkSoft),
                        ),
                        Text(
                          '₦${((ride?.offeredFare ?? ride?.totalFare) ?? 0.0).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.arrow_upward, size: 12, color: AppColors.navy),
                          label: const Text('+₦200', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final ok = await activeVm.raiseOffer(200);
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Offer raised by ₦200!'), duration: Duration(seconds: 2)),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.arrow_upward, size: 12, color: AppColors.navy),
                          label: const Text('+₦500', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final ok = await activeVm.raiseOffer(500);
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Offer raised by ₦500!'), duration: Duration(seconds: 2)),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.arrow_upward, size: 12, color: AppColors.navy),
                          label: const Text('+₦1,000', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final ok = await activeVm.raiseOffer(1000);
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Offer raised by ₦1,000!'), duration: Duration(seconds: 2)),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Driver Bids & Counter-Offers Section
              if (activeVm.driverOffers.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gold, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.local_offer, color: AppColors.gold, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'DRIVER COUNTER-OFFERS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.goldSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${activeVm.driverOffers.length} offer(s)',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ink),
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
                            const Icon(Icons.local_gas_station, size: 15, color: AppColors.ink),
                            const SizedBox(width: 6),
                            Builder(
                              builder: (ctx) {
                                final fPrice = ride?.fuelPriceApplied ?? 1400.0;
                                final fCost = (ride?.fuelCostEstimated != null && ride!.fuelCostEstimated! > 0)
                                    ? ride.fuelCostEstimated!
                                    : (((ride?.actualDistanceKm ?? 5.0) / 12.0) * fPrice);
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
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.paperRaised,
                            borderRadius: BorderRadius.circular(12),
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
                                            Text(
                                              dName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
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
                                          style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₦${pFare.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ],
                              ),
                              if (note != null && note.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '"$note"',
                                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.inkSoft),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 38,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.coral,
                                          side: const BorderSide(color: AppColors.coral),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(vertical: 0),
                                        ),
                                        onPressed: () async {
                                          final offerId = offer['name']?.toString();
                                          if (offerId != null) {
                                            await activeVm.declineCounterOffer(offerId);
                                          }
                                        },
                                        child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: SizedBox(
                                      height: 38,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.navy,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(vertical: 0),
                                        ),
                                        onPressed: () async {
                                          final offerId = offer['name']?.toString();
                                          if (offerId != null) {
                                            await activeVm.acceptCounterOffer(offerId);
                                          }
                                        },
                                        child: Text('Agree & Accept (₦${pFare.toStringAsFixed(0)})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
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
              ],
              const Spacer(),

              // Trip Summary Card from r-match
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.paperRaised,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${ride?.vehicleCategory ?? "Standard"} · ${ride?.pickupAddress.split(",").first ?? "Lekki"} → ${ride?.destinationAddress.split(",").first ?? "Ikeja"}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₦${(ride?.totalFare ?? 5600).toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => _showCancelDialog(context, activeVm),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.line, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                  child: const Text(
                    'Cancel Request',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.ink),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
