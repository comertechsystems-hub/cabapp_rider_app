import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../viewmodels/active_ride_viewmodel.dart';
import '../viewmodels/ride_viewmodel.dart';

/// 12. Driver Assigned Screen
class DriverAssignedScreen extends StatelessWidget {
  const DriverAssignedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activeVm = context.watch<ActiveRideViewModel>();
    final legacyVm = context.watch<RideViewModel>();
    final ride = activeVm.currentRide ?? legacyVm.currentRide;
    final driver = ride?.driverDetails;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Driver Assigned', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success Match Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.greenSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Driver Found!',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.green),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Your driver has accepted the trip and is heading to your pickup location.',
                            style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Driver Information Card
              Container(
                padding: const EdgeInsets.all(18),
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
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.navySoft,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.line, width: 1.5),
                          ),
                          child: const Icon(Icons.person, size: 36, color: AppColors.navy),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driver?.name ?? 'Assigned Driver',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.ink),
                              ),
                              const SizedBox(height: 2),
                              if (driver != null && driver.rating > 0)
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: AppColors.gold, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      driver.rating.toStringAsFixed(1),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.goldInk),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('• Verified Driver', style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppColors.line),
                    // Vehicle details row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('VEHICLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.inkSoft)),
                            const SizedBox(height: 2),
                            Text(
                              driver?.vehicleDescription ?? 'Standard Sedan',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.navy, width: 1.5),
                          ),
                          child: Text(
                            driver?.licensePlate ?? 'LAGOS PLATE',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.navy),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4-Digit Trip Start PIN Card
              if (ride?.startOtp != null)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.coralSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUR TRIP START PIN',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.coral),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Share with driver when boarding',
                            style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.coral),
                        ),
                        child: Text(
                          ride!.startOtp!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4.0,
                            color: AppColors.coral,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Route & Fare summary
              if (ride != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.my_location, color: AppColors.navy, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ride.pickupAddress,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.coral, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ride.destinationAddress,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.inkSoft),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '₦${ride.displayFare.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Track Arrival CTA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.driverArriving);
                  },
                  child: const Text('Track Driver Arrival', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
