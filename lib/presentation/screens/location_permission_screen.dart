import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../routes/app_routes.dart';

/// 6. Location Permission Screen
class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

  void _proceedToHome(BuildContext context) {
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.greenSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.green.withValues(alpha: 0.2), width: 3),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.green,
                  size: 56,
                ),
              ),
              const SizedBox(height: 36),
              const Text(
                'Enable Location Access',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              const Text(
                'CabApp uses your current location to connect you with nearby verified drivers, pinpoint your exact pickup spot, and ensure ride safety.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.inkSoft,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _proceedToHome(context),
                  child: const Text(
                    'Allow Location Access',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => _proceedToHome(context),
                child: const Text(
                  'Set Location Manually',
                  style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
