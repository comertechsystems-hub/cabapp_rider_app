import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../viewmodels/active_ride_viewmodel.dart';
import '../viewmodels/rating_viewmodel.dart';
import '../viewmodels/ride_booking_viewmodel.dart';
import '../viewmodels/ride_viewmodel.dart';

/// 16. Rating Screen
class RatingScreen extends StatefulWidget {
  final String? rideId;
  final String? driverName;

  const RatingScreen({
    super.key,
    this.rideId,
    this.driverName,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final _reviewController = TextEditingController();

  static const List<String> availableTags = [
    'Polite driver',
    'Clean vehicle',
    'Smooth ride',
    'Safe driving',
    'Great conversation',
    'Good music',
  ];

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _finishAndReturnHome() {
    context.read<ActiveRideViewModel>().reset();
    context.read<RideViewModel>().reset();
    context.read<RideBookingViewModel>().reset();
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final ratingVm = context.watch<RatingViewModel>();
    final activeVm = context.watch<ActiveRideViewModel>();
    final legacyVm = context.watch<RideViewModel>();

    final ride = activeVm.currentRide ?? legacyVm.currentRide;
    final effectiveRideId = widget.rideId ?? ride?.id ?? '';
    final effectiveDriverName = widget.driverName ?? ride?.driverDetails?.name ?? 'Driver';

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Trip Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Rating Badge
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.goldSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star, color: AppColors.gold, size: 44),
              ),
              const SizedBox(height: 16),
              const Text(
                'How was your ride?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              const SizedBox(height: 6),
              Text(
                'Your rating helps keep our Lagos driver community exceptional.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 8),
              Text(
                'Trip with $effectiveDriverName',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
              ),
              const SizedBox(height: 24),

              // Star Rating Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return IconButton(
                    iconSize: 44,
                    icon: Icon(
                      starNum <= ratingVm.score ? Icons.star : Icons.star_border,
                      color: AppColors.gold,
                    ),
                    onPressed: () => ratingVm.setScore(starNum),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Compliment Tag Chips
              const Text(
                'WHAT WENT WELL?',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: availableTags.map((tag) {
                  final isSelected = ratingVm.selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : AppColors.ink,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.navy,
                    backgroundColor: Colors.white,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onSelected: (_) => ratingVm.toggleTag(tag),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Review Feedback TextField
              TextField(
                controller: _reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Leave an optional review or compliment...',
                  hintStyle: const TextStyle(fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.navy, width: 2)),
                ),
                onChanged: (val) => ratingVm.setReview(val),
              ),

              if (ratingVm.errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(ratingVm.errorMessage!, style: const TextStyle(color: AppColors.coral, fontSize: 12)),
              ],
              const SizedBox(height: 28),

              // Submit CTA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: ratingVm.isLoading
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final success = await ratingVm.submitRating(effectiveRideId);
                          if (!mounted) return;
                          if (success) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Thank you for your rating!')),
                            );
                            _finishAndReturnHome();
                          }
                        },
                  child: ratingVm.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Submit Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),

              // Skip Button
              TextButton(
                onPressed: _finishAndReturnHome,
                child: const Text('Maybe Later', style: TextStyle(color: AppColors.inkSoft, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
