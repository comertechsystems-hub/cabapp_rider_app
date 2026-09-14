import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../viewmodels/ride_booking_viewmodel.dart';

/// 7. Pickup Selection Screen
class PickupScreen extends StatefulWidget {
  const PickupScreen({super.key});

  @override
  State<PickupScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends State<PickupScreen> {
  final _searchController = TextEditingController();

  static const List<Map<String, dynamic>> popularPickups = [
    {'name': 'Victoria Island (Adeola Odeku)', 'lat': 6.4281, 'lng': 3.4219, 'area': 'Victoria Island'},
    {'name': 'Lekki Phase 1 (Admiralty Way)', 'lat': 6.4474, 'lng': 3.4723, 'area': 'Lekki'},
    {'name': 'Murtala Muhammed Airport (MMA2)', 'lat': 6.5774, 'lng': 3.3211, 'area': 'Ikeja'},
    {'name': 'Ikeja City Mall (Alausa)', 'lat': 6.6194, 'lng': 3.3581, 'area': 'Ikeja'},
    {'name': 'Maryland Mall (Ikorodu Rd)', 'lat': 6.5721, 'lng': 3.3672, 'area': 'Maryland'},
    {'name': 'Marina Terminal (CMS)', 'lat': 6.4531, 'lng': 3.4328, 'area': 'Lagos Island'},
  ];

  List<Map<String, dynamic>> _filteredPickups = popularPickups;

  @override
  void initState() {
    super.initState();
    final bookingVm = context.read<RideBookingViewModel>();
    if (bookingVm.pickupAddress != null && bookingVm.pickupAddress!.isNotEmpty) {
      _searchController.text = bookingVm.pickupAddress!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredPickups = popularPickups;
      } else {
        _filteredPickups = popularPickups
            .where((p) => p['name'].toString().toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectPickup(Map<String, dynamic> loc) {
    final bookingVm = context.read<RideBookingViewModel>();
    bookingVm.setPickup(loc['name'], loc['lat'], loc['lng']);
    _searchController.text = loc['name'];
  }

  @override
  Widget build(BuildContext context) {
    final bookingVm = context.watch<RideBookingViewModel>();

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Set Pickup Spot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Box Card
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.my_location, color: AppColors.navy),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      hintText: 'Search pickup location...',
                      filled: true,
                      fillColor: AppColors.paper,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      _selectPickup(popularPickups.first);
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.gps_fixed, color: AppColors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Use current GPS location',
                          style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.line),
            // Location List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredPickups.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.line),
                itemBuilder: (context, index) {
                  final loc = _filteredPickups[index];
                  final isSelected = bookingVm.pickupAddress == loc['name'];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.navy : AppColors.paperRaised,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Icon(
                        Icons.place,
                        color: isSelected ? Colors.white : AppColors.navy,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      loc['name'],
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 15,
                        color: AppColors.ink,
                      ),
                    ),
                    subtitle: Text(loc['area'], style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.green, size: 20) : null,
                    onTap: () => _selectPickup(loc),
                  );
                },
              ),
            ),
            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (bookingVm.pickupAddress != null && bookingVm.pickupAddress!.isNotEmpty)
                      ? () => Navigator.pushNamed(context, AppRoutes.destination)
                      : null,
                  child: const Text('Confirm Pickup Spot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
