import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RealisticVehicleCard extends StatelessWidget {
  final String? category;
  final String? make;
  final String? model;
  final String? color;
  final String? licensePlate;
  final bool compact;

  const RealisticVehicleCard({
    super.key,
    this.category,
    this.make,
    this.model,
    this.color,
    this.licensePlate,
    this.compact = false,
  });

  String _resolveAssetImage() {
    final cat = (category ?? '').toUpperCase();
    final mdl = (model ?? '').toUpperCase();
    if (cat.contains('XL') || cat.contains('SUV') || mdl.contains('SUV') || mdl.contains('SIENNA')) {
      return 'assets/images/vehicle_xl.png';
    }
    if (cat.contains('COMFORT') || cat.contains('EXEC') || cat.contains('CAMRY') || cat.contains('LEXUS')) {
      return 'assets/images/vehicle_comfort.png';
    }
    return 'assets/images/vehicle_economy.png';
  }

  String _resolveCategoryLabel() {
    final cat = (category ?? '').toUpperCase();
    if (cat.contains('XL') || cat.contains('SUV')) return 'CabApp XL (SUV)';
    if (cat.contains('COMFORT') || cat.contains('EXEC')) return 'CabApp Comfort (Executive)';
    return 'CabApp Economy (Sedan)';
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = _resolveAssetImage();
    final plate = (licensePlate != null && licensePlate!.trim().isNotEmpty)
        ? licensePlate!.trim().toUpperCase()
        : 'LAGOS PLATE';
    final vehicleTitle = [
      if (color != null && color!.trim().isNotEmpty) color!.trim(),
      if (make != null && make!.trim().isNotEmpty) make!.trim(),
      if (model != null && model!.trim().isNotEmpty) model!.trim(),
    ].join(' ');

    final displayTitle = vehicleTitle.isNotEmpty ? vehicleTitle : 'Verified CabApp Vehicle';

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Image.asset(
              assetPath,
              width: 80,
              height: 44,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, size: 36, color: AppColors.navy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _resolveCategoryLabel(),
                    style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.navy, width: 1.2),
              ),
              child: Text(
                plate,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge Row
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _resolveCategoryLabel(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🇳🇬 ',
                        style: TextStyle(fontSize: 10),
                      ),
                      Text(
                        plate,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // High-Fidelity Realistic Car Artwork Display
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Center(
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.directions_car_filled,
                  size: 64,
                  color: AppColors.navy,
                ),
              ),
            ),
          ),

          // Bottom Specs Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined, size: 16, color: Color(0xFF10B981)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    displayTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Text(
                  'Pickup Vehicle',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
