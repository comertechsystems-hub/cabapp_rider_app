import 'package:flutter/material.dart';

import '../interfaces/i_distance_matrix_service.dart';
import '../interfaces/i_geocoding_service.dart';
import '../interfaces/i_map_provider.dart';
import '../interfaces/i_routing_service.dart';
import '../models/distance_matrix_result.dart';
import '../models/geo_bounds.dart';
import '../models/geo_point.dart';
import '../models/geocoded_location.dart';
import '../models/map_visuals.dart';
import '../models/route_result.dart';

/// In-memory mock map provider providing deterministic calculations and realistic Lagos coordinates.
class MockMapProvider implements IMapProvider {
  bool _initialized = true;
  final MockGeocodingService _geocoding = MockGeocodingService();
  final MockRoutingService _routing = MockRoutingService();
  final MockDistanceMatrixService _distanceMatrix = MockDistanceMatrixService();

  @override
  MapVendor get vendor => MapVendor.mock;

  @override
  String get name => 'Mock Map Engine';

  @override
  bool get isInitialized => _initialized;

  @override
  IGeocodingService get geocoding => _geocoding;

  @override
  IRoutingService get routing => _routing;

  @override
  IDistanceMatrixService get distanceMatrix => _distanceMatrix;

  @override
  Future<void> initialize({String? apiKey, Map<String, dynamic>? options}) async {
    _initialized = true;
  }

  @override
  Widget buildMapView({
    required MapCameraPosition initialCamera,
    Set<MapMarker> markers = const {},
    Set<MapPolyline> polylines = const {},
    void Function(IMapController controller)? onMapCreated,
    void Function(GeoPoint point)? onTap,
  }) {
    return _MockMapWidget(
      initialCamera: initialCamera,
      markers: markers,
      polylines: polylines,
      onMapCreated: onMapCreated,
      onTap: onTap,
    );
  }
}

class MockGeocodingService implements IGeocodingService {
  static final List<GeocodedLocation> lagosLocations = [
    const GeocodedLocation(
      formattedAddress: '14 Admiralty Way, Lekki Phase 1, Lagos',
      point: GeoPoint(latitude: 6.4474, longitude: 3.4723),
      name: 'Lekki Phase 1 (Admiralty Way)',
      sublocality: 'Lekki',
      city: 'Lagos',
      state: 'Lagos State',
      country: 'Nigeria',
      placeId: 'lag_lekki_01',
    ),
    const GeocodedLocation(
      formattedAddress: '22 Adeola Odeku St, Victoria Island, Lagos',
      point: GeoPoint(latitude: 6.4281, longitude: 3.4219),
      name: 'Victoria Island (Adeola Odeku)',
      sublocality: 'Victoria Island',
      city: 'Lagos',
      state: 'Lagos State',
      country: 'Nigeria',
      placeId: 'lag_vi_01',
    ),
    const GeocodedLocation(
      formattedAddress: 'MMA2 Domestic Airport, Ikeja, Lagos',
      point: GeoPoint(latitude: 6.5774, longitude: 3.3211),
      name: 'Murtala Muhammed Airport (MMA2)',
      sublocality: 'Ikeja',
      city: 'Lagos',
      state: 'Lagos State',
      country: 'Nigeria',
      placeId: 'lag_mma2_01',
    ),
    const GeocodedLocation(
      formattedAddress: 'Ikeja City Mall, Obafemi Awolowo Way, Alausa, Ikeja',
      point: GeoPoint(latitude: 6.6194, longitude: 3.3581),
      name: 'Ikeja City Mall (Alausa)',
      sublocality: 'Alausa',
      city: 'Ikeja',
      state: 'Lagos State',
      country: 'Nigeria',
      placeId: 'lag_icm_01',
    ),
    const GeocodedLocation(
      formattedAddress: 'Marina Terminal, CMS, Lagos Island',
      point: GeoPoint(latitude: 6.4531, longitude: 3.4328),
      name: 'Marina Terminal (CMS)',
      sublocality: 'Lagos Island',
      city: 'Lagos',
      state: 'Lagos State',
      country: 'Nigeria',
      placeId: 'lag_marina_01',
    ),
    const GeocodedLocation(
      formattedAddress: 'Commercial Avenue, Yaba, Lagos',
      point: GeoPoint(latitude: 6.5181, longitude: 3.3762),
      name: 'Yaba Tech / Commercial Ave',
      sublocality: 'Yaba',
      city: 'Lagos',
      state: 'Lagos State',
      country: 'Nigeria',
      placeId: 'lag_yaba_01',
    ),
  ];

  @override
  Future<List<GeocodedLocation>> searchPlaces(
    String query, {
    GeoPoint? proximity,
    GeoBounds? bounds,
    int limit = 5,
  }) async {
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) return lagosLocations.take(limit).toList();

    final matches = lagosLocations.where((loc) {
      return loc.formattedAddress.toLowerCase().contains(lowerQuery) ||
          (loc.name?.toLowerCase().contains(lowerQuery) ?? false) ||
          (loc.sublocality?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();

    return matches.take(limit).toList();
  }

  @override
  Future<GeocodedLocation?> reverseGeocode(double latitude, double longitude) async {
    final target = GeoPoint(latitude: latitude, longitude: longitude);
    GeocodedLocation? closest;
    double minDistance = double.infinity;

    for (final loc in lagosLocations) {
      final dist = loc.point.distanceTo(target);
      if (dist < minDistance) {
        minDistance = dist;
        closest = loc;
      }
    }

    if (closest != null && minDistance < 5.0) {
      return closest;
    }

    return GeocodedLocation(
      formattedAddress: 'Near ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}, Lagos, Nigeria',
      point: target,
      city: 'Lagos',
      state: 'Lagos State',
      country: 'Nigeria',
    );
  }

  @override
  Future<GeocodedLocation?> getPlaceDetails(String placeId) async {
    return lagosLocations.cast<GeocodedLocation?>().firstWhere(
          (loc) => loc?.placeId == placeId,
          orElse: () => null,
        );
  }
}

class MockRoutingService implements IRoutingService {
  @override
  Future<RouteResult> getRoute({
    required GeoPoint origin,
    required GeoPoint destination,
    List<GeoPoint>? waypoints,
    RouteTravelMode travelMode = RouteTravelMode.driving,
    bool optimizeWaypoints = false,
  }) async {
    final straightDist = origin.distanceTo(destination);
    // Standard urban circuity factor 1.3
    final distanceKm = double.parse((straightDist * 1.3).toStringAsFixed(2));
    // Average urban speed ~28 km/h
    final durationMins = double.parse(((distanceKm / 28.0) * 60.0).toStringAsFixed(1));

    // Generate intermediate points along path
    final polylinePoints = <GeoPoint>[origin];
    const stepsCount = 5;
    for (int i = 1; i < stepsCount; i++) {
      final fraction = i / stepsCount;
      polylinePoints.add(
        GeoPoint(
          latitude: origin.latitude + (destination.latitude - origin.latitude) * fraction + 0.001 * (i % 2 == 0 ? 1 : -1),
          longitude: origin.longitude + (destination.longitude - origin.longitude) * fraction,
        ),
      );
    }
    polylinePoints.add(destination);

    final steps = [
      RouteStep(
        instruction: 'Head towards destination on main corridor',
        distanceKm: distanceKm * 0.4,
        durationMins: durationMins * 0.4,
        maneuver: 'depart',
        startPoint: origin,
        endPoint: polylinePoints[2],
      ),
      RouteStep(
        instruction: 'Continue straight through central expressway',
        distanceKm: distanceKm * 0.4,
        durationMins: durationMins * 0.4,
        maneuver: 'straight',
        startPoint: polylinePoints[2],
        endPoint: polylinePoints[4],
      ),
      RouteStep(
        instruction: 'Turn into destination drop-off lane',
        distanceKm: distanceKm * 0.2,
        durationMins: durationMins * 0.2,
        maneuver: 'arrive',
        startPoint: polylinePoints[4],
        endPoint: destination,
      ),
    ];

    return RouteResult(
      routeId: 'route_${DateTime.now().millisecondsSinceEpoch}',
      distanceKm: distanceKm,
      durationMins: durationMins,
      polylinePoints: polylinePoints,
      bounds: GeoBounds.fromPoints([origin, destination]),
      summary: 'Fastest route via Lagos Expressway',
      steps: steps,
    );
  }

  @override
  Future<List<RouteResult>> getAlternativeRoutes({
    required GeoPoint origin,
    required GeoPoint destination,
    int maxAlternatives = 2,
    RouteTravelMode travelMode = RouteTravelMode.driving,
  }) async {
    final primary = await getRoute(origin: origin, destination: destination, travelMode: travelMode);
    final alternative = RouteResult(
      routeId: 'alt_route_${DateTime.now().millisecondsSinceEpoch}',
      distanceKm: double.parse((primary.distanceKm * 1.12).toStringAsFixed(2)),
      durationMins: double.parse((primary.durationMins * 1.25).toStringAsFixed(1)),
      polylinePoints: primary.polylinePoints,
      bounds: primary.bounds,
      summary: 'Alternative route via Service Lane',
      steps: primary.steps,
    );
    return [primary, alternative].take(maxAlternatives).toList();
  }
}

class MockDistanceMatrixService implements IDistanceMatrixService {
  @override
  Future<DistanceMatrixResult> getDistanceMatrix({
    required List<GeoPoint> origins,
    required List<GeoPoint> destinations,
    RouteTravelMode travelMode = RouteTravelMode.driving,
  }) async {
    final rows = <DistanceMatrixRow>[];

    for (int oIdx = 0; oIdx < origins.length; oIdx++) {
      final origin = origins[oIdx];
      final elements = <DistanceMatrixElement>[];

      for (int dIdx = 0; dIdx < destinations.length; dIdx++) {
        final destination = destinations[dIdx];
        final distKm = double.parse((origin.distanceTo(destination) * 1.3).toStringAsFixed(2));
        final durMins = double.parse(((distKm / 30.0) * 60.0).toStringAsFixed(1));

        elements.add(
          DistanceMatrixElement(
            originIndex: oIdx,
            destinationIndex: dIdx,
            origin: origin,
            destination: destination,
            distanceKm: distKm,
            durationMins: durMins,
            status: DistanceMatrixStatus.ok,
          ),
        );
      }
      rows.add(DistanceMatrixRow(elements: elements));
    }

    return DistanceMatrixResult(origins: origins, destinations: destinations, rows: rows);
  }
}

class _MockMapWidget extends StatefulWidget {
  final MapCameraPosition initialCamera;
  final Set<MapMarker> markers;
  final Set<MapPolyline> polylines;
  final void Function(IMapController controller)? onMapCreated;
  final void Function(GeoPoint point)? onTap;

  const _MockMapWidget({
    required this.initialCamera,
    this.markers = const {},
    this.polylines = const {},
    this.onMapCreated,
    this.onTap,
  });

  @override
  State<_MockMapWidget> createState() => _MockMapWidgetState();
}

class _MockMapWidgetState extends State<_MockMapWidget> implements IMapController {
  late MapCameraPosition _camera;
  final Set<MapMarker> _markers = {};
  final Set<MapPolyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _camera = widget.initialCamera;
    _markers.addAll(widget.markers);
    _polylines.addAll(widget.polylines);
    widget.onMapCreated?.call(this);
  }

  @override
  Future<void> animateTo(MapCameraPosition position) async {
    setState(() => _camera = position);
  }

  @override
  Future<void> fitBounds(GeoBounds bounds, {double padding = 40.0}) async {
    setState(() => _camera = MapCameraPosition(target: bounds.center, zoom: 12.0));
  }

  @override
  Future<void> addMarker(MapMarker marker) async {
    setState(() => _markers.add(marker));
  }

  @override
  Future<void> removeMarker(String markerId) async {
    setState(() => _markers.removeWhere((m) => m.id == markerId));
  }

  @override
  Future<void> addPolyline(MapPolyline polyline) async {
    setState(() => _polylines.add(polyline));
  }

  @override
  Future<void> removePolyline(String polylineId) async {
    setState(() => _polylines.removeWhere((p) => p.id == polylineId));
  }

  @override
  Future<void> clear() async {
    setState(() {
      _markers.clear();
      _polylines.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        widget.onTap?.call(_camera.target);
      },
      child: Container(
        color: const Color(0xFFE5E9E0),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined, size: 48, color: Color(0xFF1E3A8A)),
                  const SizedBox(height: 8),
                  Text(
                    'Mock Map (${_camera.target.latitude.toStringAsFixed(4)}, ${_camera.target.longitude.toStringAsFixed(4)})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                  ),
                  Text(
                    '${_markers.length} markers • ${_polylines.length} polylines',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
