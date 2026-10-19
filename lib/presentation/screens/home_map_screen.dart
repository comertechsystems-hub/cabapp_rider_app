import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
    {'name': 'Victoria Island (Adeola Odeku)', 'area': 'Victoria Island, Lagos', 'lat': 6.4281, 'lng': 3.4219},
    {'name': 'Lekki Phase 1 (Admiralty Way)', 'area': 'Lekki Phase 1, Lagos', 'lat': 6.4474, 'lng': 3.4723},
    {'name': 'Murtala Muhammed Airport (MMA2)', 'area': 'Ikeja, Lagos', 'lat': 6.5774, 'lng': 3.3211},
    {'name': 'Ikeja City Mall (Alausa)', 'area': 'Obafemi Awolowo Way, Ikeja', 'lat': 6.6194, 'lng': 3.3581},
    {'name': 'Maryland Mall (Ikorodu Rd)', 'area': 'Maryland, Lagos', 'lat': 6.5721, 'lng': 3.3672},
    {'name': 'Yaba Tech / Commercial Ave', 'area': 'Sabo Yaba, Lagos', 'lat': 6.5181, 'lng': 3.3762},
    {'name': 'Eko Hotel & Suites, Adetokunbo Ademola', 'area': 'Victoria Island, Lagos', 'lat': 6.4266, 'lng': 3.4301},
    {'name': 'Landmark Beach & Boulevard, Water Corporation Dr', 'area': 'Oniru, Victoria Island', 'lat': 6.4235, 'lng': 3.4422},
    {'name': 'Ikoyi Club 1938, Awolowo Road', 'area': 'Ikoyi, Lagos', 'lat': 6.4519, 'lng': 3.4258},
    {'name': 'Falomo Shopping Centre, Awolowo Rd', 'area': 'Ikoyi, Lagos', 'lat': 6.4428, 'lng': 3.4209},
    {'name': 'Chevron Drive / Lekki Conservation Centre', 'area': 'Chevron, Lekki', 'lat': 6.4416, 'lng': 3.5359},
    {'name': 'Ajah Jubilee Bridge / Sangotedo', 'area': 'Lekki-Epe Expressway', 'lat': 6.4698, 'lng': 3.5652},
    {'name': 'Surulere Adeniran Ogunsanya Mall', 'area': 'Surulere, Lagos', 'lat': 6.4972, 'lng': 3.3569},
    {'name': 'National Stadium / Bode Thomas St', 'area': 'Surulere, Lagos', 'lat': 6.4983, 'lng': 3.3631},
    {'name': 'Allen Avenue Roundabout, Toyin Street', 'area': 'Ikeja, Lagos', 'lat': 6.6018, 'lng': 3.3515},
    {'name': 'Computer Village, Otigba Street', 'area': 'Ikeja, Lagos', 'lat': 6.5944, 'lng': 3.3418},
    {'name': 'Gbagada Phase 1 / Charley Boy Bus Stop', 'area': 'Gbagada, Lagos', 'lat': 6.5539, 'lng': 3.3861},
    {'name': 'Magodo GRA Phase 2 (CMD Road)', 'area': 'Magodo, Lagos', 'lat': 6.6285, 'lng': 3.3792},
    {'name': 'Ogba / Aguda Central Mosque', 'area': 'Ogba, Ikeja', 'lat': 6.6311, 'lng': 3.3398},
    {'name': 'Festac Town (23 Road / 1st Avenue)', 'area': 'Amuwo Odofin, Lagos', 'lat': 6.4664, 'lng': 3.2835},
    {'name': 'Apapa Wharf / Creek Road', 'area': 'Apapa, Lagos', 'lat': 6.4488, 'lng': 3.3662},
    {'name': 'University of Lagos (UNILAG Main Gate)', 'area': 'Akoka, Yaba', 'lat': 6.5158, 'lng': 3.3898},
    {'name': 'Lagos Island Marina / CMS', 'area': 'Marina, Lagos Island', 'lat': 6.4511, 'lng': 3.3892},
    {'name': 'Oshodi Transport Interchange', 'area': 'Oshodi, Lagos', 'lat': 6.5562, 'lng': 3.3497},
  ];

  late final TextEditingController _pickupController;
  late final TextEditingController _destinationController;
  late final FocusNode _pickupFocusNode;
  late final FocusNode _destinationFocusNode;

  List<Map<String, dynamic>> _nearbyDrivers = [];
  List<Map<String, dynamic>> _addressSuggestions = [];
  Timer? _nearbyTimer;
  Timer? _searchDebounce;

  double _myLat = 6.4281;
  double _myLng = 3.4219;
  bool _hasDeviceLocation = false;
  bool _isPinningPickup = false;
  bool _isSearchingAddress = false;
  bool _isReverseGeocoding = false;
  String? _activeSearchField; // 'PICKUP' or 'DESTINATION'

  bool get _isTestEnv => WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _pickupController = TextEditingController(text: 'Victoria Island (Adeola Odeku)');
    _destinationController = TextEditingController(text: 'Lekki Phase 1 (Admiralty Way)');
    _pickupFocusNode = FocusNode()
      ..addListener(() {
        if (_pickupFocusNode.hasFocus && mounted) {
          setState(() {
            _isPinningPickup = true;
            _activeSearchField = 'PICKUP';
          });
        }
      });
    _destinationFocusNode = FocusNode()
      ..addListener(() {
        if (_destinationFocusNode.hasFocus && mounted) {
          setState(() {
            _isPinningPickup = false;
            _activeSearchField = 'DESTINATION';
          });
        }
      });

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

      // Acquire actual device GPS coordinates and reverse-geocode street address on map
      DeviceLocationService.getCurrentPosition().then((pos) async {
        if (pos != null && mounted) {
          setState(() {
            _myLat = pos.latitude;
            _myLng = pos.longitude;
            _hasDeviceLocation = true;
          });
          final resolvedPickup = await _reverseGeocodeCoordinate(pos.latitude, pos.longitude);
          if (!mounted) return;
          _pickupController.text = resolvedPickup;
          bookingVm.setPickup(resolvedPickup, pos.latitude, pos.longitude);
          legacyVm.setPickup(resolvedPickup, pos.latitude, pos.longitude);
          bookingVm.fetchFareEstimates();
          legacyVm.fetchFareEstimates();
          _fetchNearbyDrivers();
        }
      }).catchError((_) {});
    });
    if (!_isTestEnv) {
      _nearbyTimer = Timer.periodic(const Duration(seconds: 4), (_) => _fetchNearbyDrivers());
    }
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
    _searchDebounce?.cancel();
    _pickupController.dispose();
    _destinationController.dispose();
    _pickupFocusNode.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }

  /// Reverse-geocodes a map coordinate (lat, lng) into a human-readable street address
  /// using OpenStreetMap Nominatim with a local Nigeria street gazetteer fallback.
  Future<String> _reverseGeocodeCoordinate(double lat, double lng) async {
    if (!_isTestEnv) {
      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
        );
        final resp = await http.get(
          uri,
          headers: const {'User-Agent': 'CabAppNigeria/1.0 (https://cabapp.com.ng)'},
        ).timeout(const Duration(seconds: 4));

        if (resp.statusCode == 200) {
          final data = json.decode(resp.body) as Map<String, dynamic>;
          final addr = data['address'] as Map<String, dynamic>?;
          if (addr != null) {
            final parts = <String>[];
            final road = addr['road'] ?? addr['pedestrian'] ?? addr['amenity'] ?? addr['building'];
            final suburb = addr['suburb'] ?? addr['neighbourhood'] ?? addr['quarter'] ?? addr['city_district'];
            final city = addr['city'] ?? addr['town'] ?? addr['state'] ?? 'Lagos';
            if (road != null && road.toString().trim().isNotEmpty) parts.add(road.toString().trim());
            if (suburb != null && suburb.toString().trim().isNotEmpty) parts.add(suburb.toString().trim());
            if (city != null && city.toString().trim().isNotEmpty && !parts.contains(city.toString().trim())) {
              parts.add(city.toString().trim());
            }
            if (parts.isNotEmpty) {
              return parts.take(3).join(', ');
            }
          }
          final displayName = data['display_name']?.toString();
          if (displayName != null && displayName.trim().isNotEmpty) {
            return displayName.split(',').take(3).map((e) => e.trim()).join(', ');
          }
        }
      } catch (_) {}
    }

    // Nearest landmark / street fallback if offline
    Map<String, dynamic>? nearest;
    double minDist = double.infinity;
    for (final loc in popularLocations) {
      final dLat = (loc['lat'] as num).toDouble() - lat;
      final dLng = (loc['lng'] as num).toDouble() - lng;
      final dist = math.sqrt(dLat * dLat + dLng * dLng);
      if (dist < minDist) {
        minDist = dist;
        nearest = loc;
      }
    }
    if (nearest != null && minDist < 0.025) {
      return 'Near ${nearest['name']}';
    }
    return 'Map Pin (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
  }

  /// Handles tapping directly on the InteractiveLiveMap to set Pickup or Destination address.
  Future<void> _handleMapTap(
    double lat,
    double lng,
    RideBookingViewModel bookingVm,
    RideViewModel legacyVm,
  ) async {
    FocusScope.of(context).unfocus();
    final isPickup = _isPinningPickup;

    setState(() {
      _isReverseGeocoding = true;
      _addressSuggestions = [];
      _activeSearchField = null;
    });

    final tempLabel = 'Pinning on map (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})...';
    if (isPickup) {
      _pickupController.text = tempLabel;
      bookingVm.setPickup(tempLabel, lat, lng);
      legacyVm.setPickup(tempLabel, lat, lng);
    } else {
      _destinationController.text = tempLabel;
      bookingVm.setDestination(tempLabel, lat, lng);
      legacyVm.setDestination(tempLabel, lat, lng);
    }

    final resolvedAddress = await _reverseGeocodeCoordinate(lat, lng);
    if (!mounted) return;

    setState(() {
      _isReverseGeocoding = false;
      if (isPickup) {
        _pickupController.text = resolvedAddress;
      } else {
        _destinationController.text = resolvedAddress;
      }
    });

    if (isPickup) {
      bookingVm.setPickup(resolvedAddress, lat, lng);
      legacyVm.setPickup(resolvedAddress, lat, lng);
    } else {
      bookingVm.setDestination(resolvedAddress, lat, lng);
      legacyVm.setDestination(resolvedAddress, lat, lng);
    }
    bookingVm.fetchFareEstimates();
    legacyVm.fetchFareEstimates();
  }

  /// Live address autocomplete as user types in Pickup or Destination TextField.
  void _onAddressInputChanged(String query, {required bool isPickup}) {
    _searchDebounce?.cancel();
    final trimmed = query.trim();

    setState(() {
      _isPinningPickup = isPickup;
      _activeSearchField = isPickup ? 'PICKUP' : 'DESTINATION';
    });

    if (trimmed.isEmpty) {
      setState(() {
        _addressSuggestions = popularLocations.take(6).toList();
        _isSearchingAddress = false;
      });
      return;
    }

    // Immediate local street/landmark matches
    final localMatches = popularLocations.where((loc) {
      final name = (loc['name'] as String).toLowerCase();
      final area = (loc['area'] as String? ?? '').toLowerCase();
      final q = trimmed.toLowerCase();
      return name.contains(q) || area.contains(q);
    }).toList();

    setState(() {
      _addressSuggestions = localMatches.isNotEmpty
          ? localMatches.take(6).toList()
          : [
              {
                'name': trimmed,
                'area': 'Use typed address on map',
                'lat': _myLat + (isPickup ? 0.002 : 0.014),
                'lng': _myLng + (isPickup ? 0.002 : 0.016),
              },
            ];
    });

    if (_isTestEnv) return;

    _searchDebounce = Timer(const Duration(milliseconds: 320), () async {
      if (!mounted) return;
      setState(() => _isSearchingAddress = true);
      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=jsonv2&countrycodes=ng&addressdetails=1&limit=6&q=${Uri.encodeQueryComponent(trimmed)}',
        );
        final resp = await http.get(
          uri,
          headers: const {'User-Agent': 'CabAppNigeria/1.0 (https://cabapp.com.ng)'},
        ).timeout(const Duration(seconds: 4));

        if (resp.statusCode == 200 && mounted) {
          final decoded = json.decode(resp.body) as List<dynamic>;
          final remoteResults = decoded.map<Map<String, dynamic>>((item) {
            final map = item as Map<String, dynamic>;
            final parts = (map['display_name'] as String? ?? trimmed)
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
            final title = parts.isNotEmpty ? parts.first : trimmed;
            final subtitle = parts.length > 1 ? parts.skip(1).take(3).join(', ') : 'Nigeria';
            return {
              'name': parts.take(2).join(', '),
              'area': subtitle,
              'lat': double.tryParse(map['lat']?.toString() ?? '') ?? (_myLat + 0.012),
              'lng': double.tryParse(map['lon']?.toString() ?? '') ?? (_myLng + 0.015),
              'title': title,
            };
          }).toList();

          final combined = <Map<String, dynamic>>[...localMatches];
          for (final r in remoteResults) {
            if (!combined.any((c) => c['name'] == r['name'])) {
              combined.add(r);
            }
          }

          setState(() {
            _addressSuggestions = combined.isNotEmpty
                ? combined.take(7).toList()
                : [
                    {
                      'name': '$trimmed, Lagos',
                      'area': 'Custom street address',
                      'lat': _myLat + (isPickup ? 0.003 : 0.015),
                      'lng': _myLng + (isPickup ? 0.003 : 0.018),
                    },
                  ];
            _isSearchingAddress = false;
          });
          return;
        }
      } catch (_) {}

      if (mounted) {
        setState(() => _isSearchingAddress = false);
      }
    });
  }

  void _selectAddressSuggestion(
    Map<String, dynamic> loc, {
    required bool isPickup,
    required RideBookingViewModel bookingVm,
    required RideViewModel legacyVm,
  }) {
    final name = loc['name'] as String;
    final lat = (loc['lat'] as num).toDouble();
    final lng = (loc['lng'] as num).toDouble();

    FocusScope.of(context).unfocus();
    setState(() {
      if (isPickup) {
        _pickupController.text = name;
      } else {
        _destinationController.text = name;
      }
      _addressSuggestions = [];
      _activeSearchField = null;
    });

    if (isPickup) {
      bookingVm.setPickup(name, lat, lng);
      legacyVm.setPickup(name, lat, lng);
    } else {
      bookingVm.setDestination(name, lat, lng);
      legacyVm.setDestination(name, lat, lng);
    }
    bookingVm.fetchFareEstimates();
    legacyVm.fetchFareEstimates();
  }

  Future<void> _submitTypedAddress(
    String value, {
    required bool isPickup,
    required RideBookingViewModel bookingVm,
    required RideViewModel legacyVm,
  }) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    if (_addressSuggestions.isNotEmpty) {
      _selectAddressSuggestion(
        _addressSuggestions.first,
        isPickup: isPickup,
        bookingVm: bookingVm,
        legacyVm: legacyVm,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _activeSearchField = null;
      _addressSuggestions = [];
    });

    final fallbackLat = isPickup ? _myLat : ((bookingVm.pickupLat ?? _myLat) + 0.016);
    final fallbackLng = isPickup ? _myLng : ((bookingVm.pickupLng ?? _myLng) + 0.019);
    if (isPickup) {
      bookingVm.setPickup(trimmed, fallbackLat, fallbackLng);
      legacyVm.setPickup(trimmed, fallbackLat, fallbackLng);
    } else {
      bookingVm.setDestination(trimmed, fallbackLat, fallbackLng);
      legacyVm.setDestination(trimmed, fallbackLat, fallbackLng);
    }
    bookingVm.fetchFareEstimates();
    legacyVm.fetchFareEstimates();
  }

  void _swapLocations(RideBookingViewModel bookingVm, RideViewModel legacyVm) {
    final pAddr = _pickupController.text;
    final pLat = bookingVm.pickupLat ?? legacyVm.pickupLat ?? _myLat;
    final pLng = bookingVm.pickupLng ?? legacyVm.pickupLng ?? _myLng;

    final dAddr = _destinationController.text;
    final dLat = bookingVm.destinationLat ?? legacyVm.destLat ?? (_myLat + 0.015);
    final dLng = bookingVm.destinationLng ?? legacyVm.destLng ?? (_myLng + 0.020);

    setState(() {
      _pickupController.text = dAddr;
      _destinationController.text = pAddr;
    });

    bookingVm.setPickup(dAddr, dLat, dLng);
    bookingVm.setDestination(pAddr, pLat, pLng);
    legacyVm.setPickup(dAddr, dLat, dLng);
    legacyVm.setDestination(pAddr, pLat, pLng);
    bookingVm.fetchFareEstimates();
    legacyVm.fetchFareEstimates();
  }

  IconData _categoryIcon(String categoryCode) {
    final upper = categoryCode.toUpperCase();
    if (upper.contains('SUV') || upper.contains('EXEC')) return Icons.airport_shuttle;
    if (upper.contains('COMFORT') || upper.contains('SEDAN')) return Icons.directions_car_filled;
    return Icons.local_taxi;
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/icon.png', width: 32, height: 32, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Text(
              'Hi, ${authVm.profile?.fullName.split(' ').first ?? 'Tomiwa'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
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
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Live Interactive Map Canvas (Tap anywhere to set Pickup or Destination)
            Expanded(
              flex: _activeSearchField != null ? 3 : 5,
              child: Container(
                margin: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                  ],
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
                      mapPinTargetLabel: _isPinningPickup ? 'Pickup' : 'Destination',
                      onToggleMapPinTarget: () {
                        setState(() => _isPinningPickup = !_isPinningPickup);
                      },
                      onMapTap: (lat, lng) => _handleMapTap(lat, lng, bookingVm, legacyVm),
                    ),
                    if (_isReverseGeocoding)
                      Positioned(
                        top: 44,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Fetching street address from map...',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Compact Safety Shield button in bottom-left of Home Map
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.95),
                        elevation: 3,
                        borderRadius: BorderRadius.circular(100),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(100),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EmergencyContactsScreen(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shield_outlined, color: AppColors.coral, size: 16),
                                const SizedBox(width: 5),
                                Text(
                                  'Safety',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.ink.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Ride Hailing Panel with Direct Address Input Fields + Map Pinning
            Flexible(
              flex: _activeSearchField != null ? 6 : 6,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.paperRaised,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -3)),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle & Pin-on-Map mode switcher
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Plan your ride',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
                          ),
                          Row(
                            children: [
                              InkWell(
                                onTap: () => setState(() => _isPinningPickup = true),
                                borderRadius: BorderRadius.circular(100),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _isPinningPickup ? AppColors.navy : AppColors.paper,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: _isPinningPickup ? AppColors.navy : AppColors.line),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.my_location,
                                        size: 12,
                                        color: _isPinningPickup ? Colors.white : AppColors.navy,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Pin Pickup',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: _isPinningPickup ? Colors.white : AppColors.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => setState(() => _isPinningPickup = false),
                                borderRadius: BorderRadius.circular(100),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: !_isPinningPickup ? AppColors.coral : AppColors.paper,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: !_isPinningPickup ? AppColors.coral : AppColors.line),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.place,
                                        size: 12,
                                        color: !_isPinningPickup ? Colors.white : AppColors.coral,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Pin Drop-off',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: !_isPinningPickup ? Colors.white : AppColors.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Direct Editable Pickup & Destination Address Input Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          children: [
                            // Route timeline dots
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle),
                                ),
                                Container(
                                  width: 2,
                                  height: 28,
                                  color: AppColors.line,
                                ),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(color: AppColors.coral, shape: BoxShape.circle),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            // Editable TextFields for Pickup & Destination
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // PICKUP INPUT FIELD
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _pickupController,
                                          focusNode: _pickupFocusNode,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.ink,
                                          ),
                                          textInputAction: TextInputAction.search,
                                          onTap: () {
                                            setState(() {
                                              _isPinningPickup = true;
                                              _activeSearchField = 'PICKUP';
                                              if (_addressSuggestions.isEmpty) {
                                                _addressSuggestions = popularLocations.take(5).toList();
                                              }
                                            });
                                          },
                                          onChanged: (val) => _onAddressInputChanged(val, isPickup: true),
                                          onSubmitted: (val) => _submitTypedAddress(
                                            val,
                                            isPickup: true,
                                            bookingVm: bookingVm,
                                            legacyVm: legacyVm,
                                          ),
                                          decoration: const InputDecoration(
                                            labelText: 'PICKUP ADDRESS',
                                            labelStyle: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.navy,
                                              letterSpacing: 0.5,
                                            ),
                                            hintText: 'Enter pickup street or tap map...',
                                            hintStyle: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                                            isDense: true,
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(vertical: 2),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.gps_fixed, size: 17, color: AppColors.green),
                                        tooltip: 'Use Current GPS Address',
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () async {
                                          final resolved = await _reverseGeocodeCoordinate(_myLat, _myLng);
                                          if (!mounted) return;
                                          setState(() {
                                            _pickupController.text = resolved;
                                            _addressSuggestions = [];
                                            _activeSearchField = null;
                                          });
                                          bookingVm.setPickup(resolved, _myLat, _myLng);
                                          legacyVm.setPickup(resolved, _myLat, _myLng);
                                          bookingVm.fetchFareEstimates();
                                          legacyVm.fetchFareEstimates();
                                        },
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 8, color: AppColors.line),
                                  // DESTINATION INPUT FIELD
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _destinationController,
                                          focusNode: _destinationFocusNode,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.ink,
                                          ),
                                          textInputAction: TextInputAction.search,
                                          onTap: () {
                                            setState(() {
                                              _isPinningPickup = false;
                                              _activeSearchField = 'DESTINATION';
                                              if (_addressSuggestions.isEmpty) {
                                                _addressSuggestions = popularLocations.take(5).toList();
                                              }
                                            });
                                          },
                                          onChanged: (val) => _onAddressInputChanged(val, isPickup: false),
                                          onSubmitted: (val) => _submitTypedAddress(
                                            val,
                                            isPickup: false,
                                            bookingVm: bookingVm,
                                            legacyVm: legacyVm,
                                          ),
                                          decoration: const InputDecoration(
                                            labelText: 'DESTINATION ADDRESS',
                                            labelStyle: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.coral,
                                              letterSpacing: 0.5,
                                            ),
                                            hintText: 'Where to? Type street or tap map...',
                                            hintStyle: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                                            isDense: true,
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(vertical: 2),
                                          ),
                                        ),
                                      ),
                                      if (_destinationController.text.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.clear, size: 17, color: AppColors.inkSoft),
                                          tooltip: 'Clear destination',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () {
                                            setState(() {
                                              _destinationController.clear();
                                              _activeSearchField = 'DESTINATION';
                                              _isPinningPickup = false;
                                              _addressSuggestions = popularLocations.take(6).toList();
                                            });
                                            _destinationFocusNode.requestFocus();
                                          },
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Swap Pickup & Destination button
                            IconButton(
                              icon: const Icon(Icons.swap_vert, color: AppColors.navy, size: 22),
                              tooltip: 'Swap Pickup & Destination',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _swapLocations(bookingVm, legacyVm),
                            ),
                          ],
                        ),
                      ),

                      // Live Address Autocomplete Suggestions List (Visible while typing or focused)
                      if (_activeSearchField != null && _addressSuggestions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 175),
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.navy.withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 6, 8, 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _activeSearchField == 'PICKUP' ? Icons.my_location : Icons.place,
                                          size: 13,
                                          color: _activeSearchField == 'PICKUP' ? AppColors.navy : AppColors.coral,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _isSearchingAddress
                                              ? 'Searching Nigeria map addresses...'
                                              : 'Matching map addresses (or tap directly on map)',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.inkSoft,
                                          ),
                                        ),
                                      ],
                                    ),
                                    InkWell(
                                      onTap: () {
                                        FocusScope.of(context).unfocus();
                                        setState(() {
                                          _activeSearchField = null;
                                          _addressSuggestions = [];
                                        });
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Text(
                                          'Done',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navy),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: AppColors.line),
                              Flexible(
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: _addressSuggestions.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.line),
                                  itemBuilder: (ctx, idx) {
                                    final loc = _addressSuggestions[idx];
                                    final isPickup = _activeSearchField == 'PICKUP';
                                    return ListTile(
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                      leading: Icon(
                                        Icons.location_on_outlined,
                                        size: 18,
                                        color: isPickup ? AppColors.navy : AppColors.coral,
                                      ),
                                      title: Text(
                                        loc['name'] as String,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: loc['area'] != null
                                          ? Text(
                                              loc['area'] as String,
                                              style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          : null,
                                      onTap: () => _selectAddressSuggestion(
                                        loc,
                                        isPickup: isPickup,
                                        bookingVm: bookingVm,
                                        legacyVm: legacyVm,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Choose a ride section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CHOOSE A RIDE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: AppColors.inkSoft,
                            ),
                          ),
                          if (selectedCat != null)
                            Text(
                              '~${selectedCat.estimatedDurationMins.toStringAsFixed(0)} min · ${selectedCat.distanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.navy),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Category pills row
                      if (bookingVm.isLoading || legacyVm.isEstimating)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (estimates.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Calculating route fares...',
                                  style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    bookingVm.fetchFareEstimates();
                                    legacyVm.fetchFareEstimates();
                                  },
                                  child: const Text(
                                    'Retry',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy),
                                  ),
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
                                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFEEF0F6) : AppColors.paper,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? AppColors.navy : AppColors.line,
                                      width: isSelected ? 1.6 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        _categoryIcon(cat.vehicleCategory),
                                        size: 18,
                                        color: isSelected ? AppColors.navy : AppColors.inkSoft,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        cat.categoryName,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? AppColors.navy : AppColors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₦${cat.totalFare.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isSelected ? AppColors.navy : AppColors.inkSoft,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 10),

                      // Estimated Fare & Direct Payment Summary Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.greenSoft,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.payments_outlined, color: AppColors.green, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Estimated fare',
                                      style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      'Cash / Transfer / POS',
                                      style: TextStyle(fontSize: 10.5, color: AppColors.ink.withValues(alpha: 0.7)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              selectedCat != null ? '₦${selectedCat.totalFare.toStringAsFixed(0)}' : '₦1,500',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Request Ride Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: (bookingVm.isLoading || selectedCat == null)
                              ? null
                              : () async {
                                  FocusScope.of(context).unfocus();
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
              ),
            ),
          ],
        ),
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
}
