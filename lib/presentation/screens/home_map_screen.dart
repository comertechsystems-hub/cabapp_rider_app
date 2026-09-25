import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/fare_estimate_model.dart';
import '../../domain/repositories/i_ride_repository.dart';
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
import '../widgets/interactive_live_map.dart';
import '../../core/services/device_location_service.dart';

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

  List<Map<String, dynamic>> _nearbyDrivers = [];
  Timer? _nearbyTimer;
  double _myLat = 6.4281;
  double _myLng = 3.4219;
  bool _hasDeviceLocation = false;

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

      _fetchNearbyDrivers();

      // Acquire actual device GPS coordinates asynchronously without blocking initial render
      DeviceLocationService.getCurrentPosition().then((pos) {
        if (pos != null && mounted) {
          setState(() {
            _myLat = pos.latitude;
            _myLng = pos.longitude;
            _hasDeviceLocation = true;
          });
          bookingVm.setPickup('My Current Location', pos.latitude, pos.longitude);
          bookingVm.setDestination('Selected Destination', pos.latitude + 0.015, pos.longitude + 0.020);
          bookingVm.fetchFareEstimates();

          legacyVm.setPickup('My Current Location', pos.latitude, pos.longitude);
          legacyVm.setDestination('Selected Destination', pos.latitude + 0.015, pos.longitude + 0.020);
          legacyVm.fetchFareEstimates();

          _fetchNearbyDrivers();
        }
      }).catchError((_) {});
    });
    _nearbyTimer = Timer.periodic(const Duration(seconds: 4), (_) => _fetchNearbyDrivers());
  }

  void _fetchNearbyDrivers() async {
    try {
      final repo = context.read<IRideRepository>();
      final drivers = await repo.getAvailableDrivers(
        serviceArea: 'Lagos Metropolitan',
        latitude: _myLat,
        longitude: _myLng,
      );
      if (mounted) {
        setState(() {
          _nearbyDrivers = drivers;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nearbyTimer?.cancel();
    super.dispose();
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
        title: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset('assets/images/icon.png', width: 34, height: 34, fit: BoxFit.cover),
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
          // Greeting Row from r-home
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Where to, ${authVm.profile?.fullName.split(' ').first ?? 'Tomiwa'}?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (authVm.profile?.fullName.isNotEmpty == true ? authVm.profile!.fullName[0] : 'T').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Live Interactive Map Canvas
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  InteractiveLiveMap(
                    pickupLat: bookingVm.pickupLat ?? legacyVm.pickupLat ?? _myLat,
                    pickupLng: bookingVm.pickupLng ?? legacyVm.pickupLng ?? _myLng,
                    pickupAddress: bookingVm.pickupAddress ?? legacyVm.pickupAddress ?? 'Victoria Island (Adeola Odeku)',
                    destinationLat: bookingVm.destinationLat ?? legacyVm.destLat ?? (_myLat + 0.015),
                    destinationLng: bookingVm.destinationLng ?? legacyVm.destLng ?? (_myLng + 0.020),
                    destinationAddress: bookingVm.destinationAddress ?? legacyVm.destAddress ?? 'Lekki Phase 1 (Admiralty Way)',
                    myLocationLat: _hasDeviceLocation ? _myLat : null,
                    myLocationLng: _hasDeviceLocation ? _myLng : null,
                    nearbyDrivers: _nearbyDrivers,
                  ),
                  // Emergency Floating SOS shortcut on Home Map
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: FloatingActionButton.small(
                      heroTag: 'home_sos',
                      backgroundColor: AppColors.coral,
                      child: const Icon(Icons.shield, color: Colors.white, size: 18),
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

          // Bottom Booking Panel from r-home
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup field with dot a
                GestureDetector(
                  onTap: () => _openLocationPicker(context, isPickup: true, bookingVm: bookingVm, legacyVm: legacyVm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.paperRaised,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PICKUP', style: TextStyle(fontSize: 10.5, color: AppColors.inkSoft, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              Text(
                                bookingVm.pickupAddress ?? legacyVm.pickupAddress ?? '14 Admiralty Way, Lekki Phase 1',
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.ink),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Destination field with dot b
                GestureDetector(
                  onTap: () => _openLocationPicker(context, isPickup: false, bookingVm: bookingVm, legacyVm: legacyVm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.paperRaised,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.coral, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DESTINATION', style: TextStyle(fontSize: 10.5, color: AppColors.inkSoft, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              Text(
                                bookingVm.destinationAddress ?? legacyVm.destAddress ?? 'Murtala Muhammed Airport, Ikeja',
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.ink),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Choose a ride section
                const Text(
                  'CHOOSE A RIDE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 8),

                // Category pills row
                if (bookingVm.isLoading || legacyVm.isEstimating)
                  const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                else if (estimates.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Calculating route fares...', style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              bookingVm.fetchFareEstimates();
                              legacyVm.fetchFareEstimates();
                            },
                            child: const Text('Retry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy)),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Row(
                    children: estimates.map((cat) {
                      final isSelected = selectedCat?.vehicleCategory == cat.vehicleCategory;
                      return Expanded(
                        child: GestureDetector(
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
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEEF0F6) : AppColors.paperRaised,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.navy : AppColors.line,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  cat.categoryName,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? AppColors.navy : AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₦${cat.totalFare.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isSelected ? AppColors.navy : AppColors.inkSoft,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 12),

                // Estimated Fare Card from r-home
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.paperRaised,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Estimated fare',
                            style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            selectedCat != null ? '₦${selectedCat.totalFare.toStringAsFixed(0)}' : '₦5,600',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '~${selectedCat?.estimatedDurationMins.toStringAsFixed(0) ?? "24"} min · ${selectedCat?.distanceKm.toStringAsFixed(1) ?? "18.2"} km',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Request Button from r-home
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (bookingVm.isLoading || selectedCat == null)
                        ? null
                        : () async {
                            final ride = await bookingVm.bookRide();
                            if (ride != null) {
                              activeVm.setActiveRide(ride);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    ),
                    child: bookingVm.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Confirm ${selectedCat?.categoryName ?? "Standard"} • ₦${selectedCat?.totalFare.toStringAsFixed(0) ?? "1500"}',
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
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

class _MapPinBadge extends StatelessWidget {
  final bool isPickup;
  const _MapPinBadge({required this.isPickup});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isPickup ? AppColors.navy : AppColors.coral,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
