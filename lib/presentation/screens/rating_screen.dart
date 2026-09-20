import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../viewmodels/active_ride_viewmodel.dart';
import '../viewmodels/rating_viewmodel.dart';
import '../viewmodels/ride_booking_viewmodel.dart';
import '../viewmodels/ride_viewmodel.dart';

/// 16. Rating Screen (r-done from Cabapp UIUX mockup)
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
    final effectiveDriverName = widget.driverName ?? ride?.driverDetails?.name ?? 'Babatunde';
    final initial = effectiveDriverName.isNotEmpty ? effectiveDriverName[0].toUpperCase() : 'B';
    final fare = ride?.totalFare ?? 5600.0;
    final distanceText = '${ride?.actualDistanceKm ?? 18.4} km';
    final durationText = '${ride?.actualDurationMins ?? 26} min';
    final paymentMethodText = ride?.paymentMethod == 'TRANSFER' || ride?.paymentMethod == 'CASH'
        ? 'paid by transfer'
        : 'paid directly';

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Trip Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 26.0),
          child: Column(
            children: [
              // Header from r-done mockup
              Text(
                'Trip complete',
                style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '₦${fare.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$distanceText · $durationText · $paymentMethodText',
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 18),

              // Payment Status Card
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
                    const Text(
                      'Payment status',
                      style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft, fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F3EC),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: AppColors.green, size: 7),
                          SizedBox(width: 5),
                          Text(
                            'Confirmed by driver',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Driver Feedback Section
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'How was your ride?',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.ink),
              ),
              const SizedBox(height: 4),
              Text(
                'Trip with $effectiveDriverName',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),

              // Interactive Star Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return GestureDetector(
                    onTap: () => ratingVm.setScore(starNum),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Icon(
                        starNum <= ratingVm.score ? Icons.star : Icons.star_border,
                        color: AppColors.gold,
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Compliment Tag Chips
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
                        fontSize: 11.5,
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
              const SizedBox(height: 14),

              // Optional Review TextField
              TextField(
                controller: _reviewController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Leave a compliment or comment (optional)...',
                  hintStyle: const TextStyle(fontSize: 12),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.navy, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onChanged: (val) => ratingVm.setReview(val),
              ),

              if (ratingVm.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(ratingVm.errorMessage!, style: const TextStyle(color: AppColors.coral, fontSize: 12)),
              ],
              const SizedBox(height: 24),

              // Buttons from r-done mockup
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Submit Rating', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),

              // Book another ride Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _finishAndReturnHome,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.line, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Book another ride', style: TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),

              // Maybe Later Button
              Center(
                child: TextButton(
                  onPressed: _finishAndReturnHome,
                  child: const Text('Maybe Later', style: TextStyle(color: AppColors.inkSoft, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
