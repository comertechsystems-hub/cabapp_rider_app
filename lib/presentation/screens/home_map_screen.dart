import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/fare_estimate_model.dart';
import '../viewmodels/active_ride_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/ride_booking_viewmodel.dart';
import '../viewmodels/ride_viewmodel.dart';
import '../viewmodels/rider_profile_viewmodel.dart';
import '../viewmodels/trip_history_viewmodel.dart';
import 'active_ride_screen.dart';
import 'emergency_contacts_screen.dart';
import 'rider_profile_screen.dart';
import 'support_screen.dart';
import 'trip_history_screen.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  static const List<Map<String, dynamic>> popularLocations = [
    {'name': 'Victoria Island (Adeola Odeku)', 'lat': 6.4281, 'lng': 3.4219},
    {'name': 'Lekki Phase 1 (Admiralty Way)', 'lat': 6.4474, 'lng': 3.4723},
    {'name': 'Murtala Muhammed Airport (MMA2)', 'lat': 6.5774, 'lng': 3.3211},
    {'name': 'Ikeja City Mall (Alausa)', 'lat': 6.6194, 'lng': 3.3581},
    {'name': 'Maryland Mall (Ikorodu Rd)', 'lat': 6.5721, 'lng': 3.3672},
    {'name': 'Yaba Tech / Commercial Ave', 'lat': 6.5181, 'lng': 3.3762},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookingVm = context.read<RideBookingViewModel>();
      final legacyVm = context.read<RideViewModel>();

      bookingVm.setPickup('Victoria Island (Adeola Odeku)', 6.4281, 3.4219);
      bookingVm.setDestination('Lekki Phase 1 (Admiralty Way)', 6.4474, 3.4723);
      bookingVm.fetchFareEstimates();

      legacyVm.setPickup('Victoria Island (Adeola Odeku)', 6.4281, 3.4219);
      legacyVm.setDestination('Lekki Phase 1 (Admiralty Way)', 6.4474, 3.4723);
      legacyVm.fetchFareEstimates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingVm = context.watch<RideBookingViewModel>();
    final legacyVm = context.watch<RideViewModel>();
    final activeVm = context.watch<ActiveRideViewModel>();
    final authVm = context.watch<AuthViewModel>();

    // If an active ride exists, show ActiveRideScreen
    if (activeVm.hasActiveRide || legacyVm.hasActiveRide) {
      return const ActiveRideScreen();
    }

    final estimates = bookingVm.fareEstimates.isNotEmpty
        ? bookingVm.fareEstimates
        : legacyVm.fareEstimates;
    final selectedCat = bookingVm.selectedCategory ?? legacyVm.selectedCategory;

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
            icon: const Icon(Icons.history),
            tooltip: 'Trip History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TripHistoryScreen(historyVm: context.read<TripHistoryViewModel>()),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RiderProfileScreen(profileVm: context.read<RiderProfileViewModel>()),
                ),
              );
            },
          ),
        ],
      ),
      drawer: _buildAppDrawer(context, authVm),
      body: Column(
        children: [
          // Map Canvas
          Expanded(
            child: Container(
              color: const Color(0xFFE5E9E0),
              child: Stack(
                children: [
                  // Vector Grid Roads Graphic
                  CustomPaint(
                    size: Size.infinite,
                    painter: _MapCanvasPainter(),
                  ),
                  // Top Banner: Direct P2P notice
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
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '100% Direct P2P Settlement • 0% Platform Commission',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ink),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Emergency Floating SOS shortcut on Home Map
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.small(
                      heroTag: 'home_sos',
                      backgroundColor: AppColors.coral,
                      child: const Icon(Icons.shield, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EmergencyContactsScreen(),
                          ),
                        );
                      },
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
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup & Destination Selectors
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => _openLocationPicker(context, isPickup: true, bookingVm: bookingVm, legacyVm: legacyVm),
                        child: Row(
                          children: [
                            const Icon(Icons.my_location, color: AppColors.navy, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                bookingVm.pickupAddress ?? legacyVm.pickupAddress ?? 'Select pickup location',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.edit_location_alt, size: 16, color: AppColors.inkSoft),
                          ],
                        ),
                      ),
                      const Divider(height: 16, color: AppColors.line),
                      InkWell(
                        onTap: () => _openLocationPicker(context, isPickup: false, bookingVm: bookingVm, legacyVm: legacyVm),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.coral, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                bookingVm.destinationAddress ?? legacyVm.destAddress ?? 'Select destination',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.edit_location_alt, size: 16, color: AppColors.inkSoft),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Category Carousel
                const Text(
                  'SELECT VEHICLE CATEGORY',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 10),
                if (bookingVm.isLoading || legacyVm.isEstimating)
                  const Center(child: Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator()))
                else if (estimates.isEmpty)
                  const Center(child: Text('No vehicle categories available for this route.'))
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: estimates.map((cat) {
                        final isSelected = selectedCat?.vehicleCategory == cat.vehicleCategory;
                        return GestureDetector(
                          onTap: () {
                            bookingVm.selectCategory(cat);
                            legacyVm.selectCategory(
                              cat is FareEstimateModel
                                  ? cat
                                  : FareEstimateModel(
                                      vehicleCategory: cat.vehicleCategory,
                                      categoryName: cat.categoryName,
                                      baseFare: cat.baseFare,
                                      estimatedDurationMins: cat.estimatedDurationMins,
                                      distanceKm: cat.distanceKm,
                                      totalFare: cat.totalFare,
                                    ),
                            );
                          },
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
                                Row(
                                  children: [
                                    Icon(
                                      Icons.directions_car,
                                      size: 16,
                                      color: isSelected ? Colors.white : AppColors.navy,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      cat.categoryName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : AppColors.ink,
                                      ),
                                    ),
                                  ],
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
                                  '${cat.distanceKm.toStringAsFixed(1)} km • ${cat.estimatedDurationMins.toStringAsFixed(0)} min',
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
                // Book Ride CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (bookingVm.isLoading || selectedCat == null)
                        ? null
                        : () async {
                            final ride = await bookingVm.bookRide();
                            if (ride != null) {
                              activeVm.setActiveRide(ride);
                              legacyVm.bookRide();
                            }
                          },
                    child: bookingVm.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            selectedCat != null
                                ? 'Confirm ${selectedCat.categoryName} • ₦${selectedCat.totalFare.toStringAsFixed(0)}'
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

  Widget _buildAppDrawer(BuildContext context, AuthViewModel authVm) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.navy),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: AppColors.navy, size: 32),
                ),
                const SizedBox(height: 10),
                Text(
                  authVm.profile?.fullName ?? 'CabApp Rider',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  authVm.profile?.phoneNumber ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: AppColors.navy),
            title: const Text('Trip History'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TripHistoryScreen(historyVm: context.read<TripHistoryViewModel>()),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.navy),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RiderProfileScreen(profileVm: context.read<RiderProfileViewModel>()),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined, color: AppColors.green),
            title: const Text('Emergency Contacts & SOS'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EmergencyContactsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent, color: AppColors.navy),
            title: const Text('Support Desk'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SupportScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.coral),
            title: const Text('Log Out', style: TextStyle(color: AppColors.coral)),
            onTap: () {
              Navigator.pop(context);
              authVm.logout();
            },
          ),
        ],
      ),
    );
  }

  void _openLocationPicker(
    BuildContext context, {
    required bool isPickup,
    required RideBookingViewModel bookingVm,
    required RideViewModel legacyVm,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPickup ? 'Choose Pickup Location' : 'Choose Destination',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...popularLocations.map((loc) => ListTile(
                  leading: Icon(
                    isPickup ? Icons.my_location : Icons.location_on,
                    color: isPickup ? AppColors.navy : AppColors.coral,
                  ),
                  title: Text(loc['name'] as String, style: const TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    final name = loc['name'] as String;
                    final lat = loc['lat'] as double;
                    final lng = loc['lng'] as double;

                    if (isPickup) {
                      bookingVm.setPickup(name, lat, lng);
                      legacyVm.setPickup(name, lat, lng);
                    } else {
                      bookingVm.setDestination(name, lat, lng);
                      legacyVm.setDestination(name, lat, lng);
                    }

                    bookingVm.fetchFareEstimates();
                    legacyVm.fetchFareEstimates();
                  },
                )),
          ],
        ),
      ),
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final highwayPaint = Paint()
      ..color = const Color(0xFFFDE68A)
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke;

    // Horizontal roads
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.3), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.6), Offset(size.width, size.height * 0.6), highwayPaint);
    canvas.drawLine(Offset(0, size.height * 0.8), Offset(size.width, size.height * 0.8), roadPaint);

    // Vertical roads
    canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width * 0.25, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.75, size.height), roadPaint);

    // Route polyline between pickup and destination
    final routePaint = Paint()
      ..color = AppColors.navy
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.3, size.height * 0.4)
      ..lineTo(size.width * 0.5, size.height * 0.4)
      ..lineTo(size.width * 0.5, size.height * 0.65)
      ..lineTo(size.width * 0.7, size.height * 0.65);

    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
