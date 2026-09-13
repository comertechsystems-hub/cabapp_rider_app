import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/ride_viewmodel.dart';
import 'active_ride_screen.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  final _pickupController = TextEditingController(text: 'Victoria Island, Lagos');
  final _destController = TextEditingController(text: 'Lekki Phase 1, Lagos');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rideVm = context.read<RideViewModel>();
      rideVm.setPickup('Victoria Island, Lagos', 6.4550, 3.4350);
      rideVm.setDestination('Lekki Phase 1, Lagos', 6.4500, 3.4500);
      rideVm.fetchFareEstimates();
    });
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rideVm = context.watch<RideViewModel>();
    final authVm = context.watch<AuthViewModel>();

    if (rideVm.state == RideBookingState.activeRide || rideVm.state == RideBookingState.completed) {
      return const ActiveRideScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_taxi, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('CabApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.inkSoft),
            onPressed: () => authVm.logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Map Canvas Placeholder
          Expanded(
            child: Container(
              color: const Color(0xFFE5E9E0),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined, size: 64, color: AppColors.navy.withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        Text(
                          'Service Area: Lagos Metropolitan',
                          style: TextStyle(
                            color: AppColors.inkSoft.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.paperRaised,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '100% Fare Retention • 0% Ride Commission',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom Booking Sheet
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.paperRaised,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup & Destination Inputs
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.my_location, color: AppColors.navy, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              rideVm.pickupAddress ?? 'Select pickup',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16, color: AppColors.line),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.coral, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              rideVm.destAddress ?? 'Select destination',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Vehicle Categories Strip
                const Text(
                  'SELECT VEHICLE CATEGORY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 10),
                if (rideVm.state == RideBookingState.estimating)
                  const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: rideVm.fareEstimates.map((cat) {
                        final isSelected = rideVm.selectedCategory?.vehicleCategory == cat.vehicleCategory;
                        return GestureDetector(
                          onTap: () => rideVm.selectCategory(cat),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.navy : AppColors.paperRaised,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? AppColors.navy : AppColors.line,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.categoryName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₦${cat.totalFare.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? AppColors.gold : AppColors.navy,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${cat.distanceKm.toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected ? Colors.white70 : AppColors.inkSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 18),
                // Book Ride Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (rideVm.state == RideBookingState.requesting || rideVm.selectedCategory == null)
                        ? null
                        : () async {
                            await rideVm.bookRide();
                          },
                    child: rideVm.state == RideBookingState.requesting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            rideVm.selectedCategory != null
                                ? 'Book ${rideVm.selectedCategory!.categoryName} • ₦${rideVm.selectedCategory!.totalFare.toStringAsFixed(0)}'
                                : 'Request Ride',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
