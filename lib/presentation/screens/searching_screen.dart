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

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        context.read<ActiveRideViewModel>().refreshActiveRide();
      }
    });
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
    if (ride != null && (ride.hasDriver || activeVm.isDriverAssigned || activeVm.isDriverArriving)) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.driverAssigned);
        }
      });
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

              const Text(
                'Connecting with Drivers...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Matching you with a verified driver nearby. This usually takes under a minute.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.4),
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
