import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../viewmodels/ride_booking_viewmodel.dart';

/// 9. Fare Estimate Screen
class FareEstimateScreen extends StatefulWidget {
  const FareEstimateScreen({super.key});

  @override
  State<FareEstimateScreen> createState() => _FareEstimateScreenState();
}

class _FareEstimateScreenState extends State<FareEstimateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookingVm = context.read<RideBookingViewModel>();
      if (bookingVm.fareEstimates.isEmpty && bookingVm.hasValidRoute) {
        bookingVm.fetchFareEstimates();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingVm = context.watch<RideBookingViewModel>();
    final selectedCat = bookingVm.selectedCategory;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Fare Estimate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Route Summary Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location, color: AppColors.navy, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          bookingVm.pickupAddress ?? 'Pickup location',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 4, bottom: 4),
                    child: Row(
                      children: [
                        Container(width: 2, height: 16, color: AppColors.line),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.coral, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          bookingVm.destinationAddress ?? 'Destination',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (selectedCat != null) ...[
                    const Divider(height: 20, color: AppColors.line),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.straighten, size: 16, color: AppColors.inkSoft),
                            const SizedBox(width: 6),
                            Text(
                              '${selectedCat.distanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.inkSoft),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 16, color: AppColors.line),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: AppColors.inkSoft),
                            const SizedBox(width: 6),
                            Text(
                              '~${selectedCat.estimatedDurationMins.toStringAsFixed(0)} mins',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.inkSoft),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Category Selection Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AVAILABLE RIDE OPTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  Text(
                    '${bookingVm.fareEstimates.length} options',
                    style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),

            // Vehicle Category List
            Expanded(
              child: bookingVm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : bookingVm.fareEstimates.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.directions_car_outlined, size: 48, color: AppColors.inkSoft),
                              const SizedBox(height: 12),
                              const Text('No fare estimates available', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => bookingVm.fetchFareEstimates(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: bookingVm.fareEstimates.length,
                          itemBuilder: (context, index) {
                            final cat = bookingVm.fareEstimates[index];
                            final isSelected = selectedCat?.vehicleCategory == cat.vehicleCategory;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : AppColors.paperRaised,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? AppColors.navy : AppColors.line,
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: AppColors.navy.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 4))]
                                    : null,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => bookingVm.selectCategory(cat),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppColors.navy : AppColors.paper,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          _getCategoryIcon(cat.vehicleCategory),
                                          color: isSelected ? AppColors.gold : AppColors.navy,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  cat.categoryName,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.ink),
                                                ),
                                                if (isSelected) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.greenSoft,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: const Text('SELECTED', style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _getCategoryDescription(cat.vehicleCategory),
                                              style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₦${cat.totalFare.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.navy,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            'Estimated',
                                            style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),

            // Settlement banner and Continue CTA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.greenSoft, shape: BoxShape.circle),
                        child: const Icon(Icons.shield_outlined, size: 14, color: AppColors.green),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Direct P2P Settlement: Pay 100% directly to your driver (Cash/Transfer/POS)',
                          style: TextStyle(fontSize: 11, color: AppColors.inkSoft, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: selectedCat != null
                          ? () => Navigator.pushNamed(context, AppRoutes.confirmRide)
                          : null,
                      child: Text(
                        selectedCat != null
                            ? 'Continue with ${selectedCat.categoryName} (₦${selectedCat.totalFare.toStringAsFixed(2)})'
                            : 'Select a Ride Option',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
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

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'COMFORT':
        return Icons.airline_seat_recline_extra;
      case 'EXECUTIVE':
        return Icons.star;
      case 'ECONOMY':
      default:
        return Icons.directions_car;
    }
  }

  String _getCategoryDescription(String category) {
    switch (category.toUpperCase()) {
      case 'COMFORT':
        return 'Spacious sedan • Top rated drivers';
      case 'EXECUTIVE':
        return 'Premium luxury • Maximum comfort';
      case 'ECONOMY':
      default:
        return 'Affordable daily rides • 4 seats';
    }
  }
}
