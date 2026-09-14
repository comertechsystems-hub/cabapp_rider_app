import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../viewmodels/ride_booking_viewmodel.dart';

/// 8. Destination Selection Screen
class DestinationScreen extends StatefulWidget {
  const DestinationScreen({super.key});

  @override
  State<DestinationScreen> createState() => _DestinationScreenState();
}

class _DestinationScreenState extends State<DestinationScreen> {
  final _searchController = TextEditingController();

  static const List<Map<String, dynamic>> popularDestinations = [
    {'name': 'Lekki Phase 1 (Admiralty Way)', 'lat': 6.4474, 'lng': 3.4723, 'area': 'Lekki'},
    {'name': 'Victoria Island (Adeola Odeku)', 'lat': 6.4281, 'lng': 3.4219, 'area': 'Victoria Island'},
    {'name': 'Murtala Muhammed Airport (MMA2)', 'lat': 6.5774, 'lng': 3.3211, 'area': 'Ikeja'},
    {'name': 'Ikoyi (Awolowo Road)', 'lat': 6.4500, 'lng': 3.4350, 'area': 'Ikoyi'},
    {'name': 'Ikeja City Mall (Alausa)', 'lat': 6.6194, 'lng': 3.3581, 'area': 'Ikeja'},
    {'name': 'Yaba Tech / Commercial Ave', 'lat': 6.5181, 'lng': 3.3762, 'area': 'Yaba'},
    {'name': 'Maryland Mall (Ikorodu Rd)', 'lat': 6.5721, 'lng': 3.3672, 'area': 'Maryland'},
    {'name': 'Ajah Market / Jubilee Bridge', 'lat': 6.4698, 'lng': 3.5645, 'area': 'Ajah'},
  ];

  List<Map<String, dynamic>> _filteredDestinations = popularDestinations;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredDestinations = popularDestinations;
      } else {
        _filteredDestinations = popularDestinations
            .where((d) => d['name'].toString().toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectDestination(Map<String, dynamic> loc) {
    final bookingVm = context.read<RideBookingViewModel>();
    bookingVm.setDestination(loc['name'], loc['lat'], loc['lng']);
    bookingVm.fetchFareEstimates();
    Navigator.pushNamed(context, AppRoutes.fareEstimate);
  }

  @override
  Widget build(BuildContext context) {
    final bookingVm = context.watch<RideBookingViewModel>();

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Where are you going?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Current Pickup & Destination Input Card
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location, color: AppColors.navy, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          (bookingVm.pickupAddress != null && bookingVm.pickupAddress!.isNotEmpty)
                              ? bookingVm.pickupAddress!
                              : 'Pickup not set',
                          style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: AppColors.line),
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.location_on, color: AppColors.coral),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      hintText: 'Enter drop-off destination...',
                      filled: true,
                      fillColor: AppColors.paper,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.line),
            // Destination Search Results
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredDestinations.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.line),
                itemBuilder: (context, index) {
                  final loc = _filteredDestinations[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.coralSoft,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.coral.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.flag, color: AppColors.coral, size: 18),
                    ),
                    title: Text(
                      loc['name'],
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink),
                    ),
                    subtitle: Text(loc['area'], style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.inkSoft),
                    onTap: () => _selectDestination(loc),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
