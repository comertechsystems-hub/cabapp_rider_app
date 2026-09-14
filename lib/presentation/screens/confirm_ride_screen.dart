import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../viewmodels/active_ride_viewmodel.dart';
import '../viewmodels/ride_booking_viewmodel.dart';

/// 10. Confirm Ride Screen
class ConfirmRideScreen extends StatefulWidget {
  const ConfirmRideScreen({super.key});

  @override
  State<ConfirmRideScreen> createState() => _ConfirmRideScreenState();
}

class _ConfirmRideScreenState extends State<ConfirmRideScreen> {
  bool _isBooking = false;

  Future<void> _handleConfirmBooking() async {
    final bookingVm = context.read<RideBookingViewModel>();
    final activeVm = context.read<ActiveRideViewModel>();

    setState(() => _isBooking = true);

    try {
      final ride = await bookingVm.bookRide();
      if (ride != null && mounted) {
        activeVm.setActiveRide(ride);
        Navigator.pushReplacementNamed(context, AppRoutes.searching);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bookingVm.errorMessage ?? 'Could not book ride. Please try again.'),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingVm = context.watch<RideBookingViewModel>();
    final category = bookingVm.selectedCategory;

    if (category == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Confirm Ride')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No vehicle category selected.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Estimates'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Confirm Ride', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle category highlight banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_taxi, color: AppColors.gold, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.categoryName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Estimated ${category.distanceKm.toStringAsFixed(1)} km • ${category.estimatedDurationMins.toStringAsFixed(0)} mins',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₦${category.totalFare.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Route Recap Card
              const Text(
                'ROUTE DETAILS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 8),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.my_location, color: AppColors.navy, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PICKUP LOCATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.inkSoft)),
                              const SizedBox(height: 2),
                              Text(
                                bookingVm.pickupAddress ?? 'Pickup location',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 9.0, top: 6, bottom: 6),
                      child: Row(
                        children: [
                          Container(width: 2, height: 20, color: AppColors.line),
                        ],
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: AppColors.coral, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DESTINATION DROP-OFF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.inkSoft)),
                              const SizedBox(height: 2),
                              Text(
                                bookingVm.destinationAddress ?? 'Destination',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Fare Breakdown
              const Text(
                'FARE BREAKDOWN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    _buildFareRow('Base Fare', '₦${category.baseFare.toStringAsFixed(2)}'),
                    const Divider(height: 16, color: AppColors.line),
                    _buildFareRow('Distance (${category.distanceKm.toStringAsFixed(1)} km)', '₦${(category.distanceKm * category.distanceRate).toStringAsFixed(2)}'),
                    const Divider(height: 16, color: AppColors.line),
                    _buildFareRow('Duration (~${category.estimatedDurationMins.toStringAsFixed(0)} mins)', '₦${(category.estimatedDurationMins * category.timeRate).toStringAsFixed(2)}'),
                    const Divider(height: 16, color: AppColors.line),
                    _buildFareRow('Platform Service Fee', '₦0.00 (Free)'),
                    const Divider(height: 20, color: AppColors.line, thickness: 1.5),
                    _buildFareRow('Estimated Total', '₦${category.totalFare.toStringAsFixed(2)}', isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Settlement Method Notice Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.greenSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.handshake_outlined, color: AppColors.green, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '100% Direct P2P Settlement',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.green),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'You pay your driver directly via Cash, Bank Transfer, or POS upon trip completion. No wallet hold, no hidden fees.',
                            style: TextStyle(fontSize: 12, color: AppColors.inkSoft, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Security & Start OTP Notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.coralSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.pin, color: AppColors.coral, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Secure 4-Digit Trip Start PIN',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.coral),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'When a driver is assigned, you will receive a 4-digit PIN. Only give this PIN to the driver after verifying their vehicle license plate.',
                            style: TextStyle(fontSize: 12, color: AppColors.inkSoft, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Confirm CTA Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isBooking ? null : _handleConfirmBooking,
                  child: _isBooking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Confirm & Request ${category.categoryName}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFareRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? AppColors.ink : AppColors.inkSoft,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 17 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? AppColors.navy : AppColors.ink,
          ),
        ),
      ],
    );
  }
}
