import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
import 'mock_map_provider.dart';

/// Google Maps Platform Provider implementation.
///
/// Encapsulates Google Geocoding, Directions API, and Distance Matrix API.
class GoogleMapProvider implements IMapProvider {
  String? apiKey;
  final http.Client _client;
  late final GoogleGeocodingService _geocoding;
  late final GoogleRoutingService _routing;
  late final GoogleDistanceMatrixService _distanceMatrix;
  bool _initialized = false;

  GoogleMapProvider({this.apiKey, http.Client? client})
      : _client = client ?? http.Client() {
    _geocoding = GoogleGeocodingService(provider: this);
    _routing = GoogleRoutingService(provider: this);
    _distanceMatrix = GoogleDistanceMatrixService(provider: this);
  }

  http.Client get client => _client;

  @override
  MapVendor get vendor => MapVendor.googleMaps;

  @override
  String get name => 'Google Maps';

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
    if (apiKey != null) this.apiKey = apiKey;
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
    return _GoogleMapWidget(
      initialCamera: initialCamera,
      markers: markers,
      polylines: polylines,
      onMapCreated: onMapCreated,
      onTap: onTap,
    );
  }
}

class GoogleGeocodingService implements IGeocodingService {
  final GoogleMapProvider provider;
  final MockGeocodingService _fallback = MockGeocodingService();

  GoogleGeocodingService({required this.provider});

  @override
  Future<List<GeocodedLocation>> searchPlaces(
    String query, {
    GeoPoint? proximity,
    GeoBounds? bounds,
    int limit = 5,
  }) async {
    if (provider.apiKey == null || provider.apiKey!.isEmpty) {
      return _fallback.searchPlaces(query, proximity: proximity, bounds: bounds, limit: limit);
    }

    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'address': query,
        'key': provider.apiKey,
        if (proximity != null) 'location': '${proximity.latitude},${proximity.longitude}',
      });

      final response = await provider.client.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];

        return results.take(limit).map((r) {
          final loc = r['geometry']['location'];
          return GeocodedLocation(
            formattedAddress: r['formatted_address'] as String? ?? query,
            point: GeoPoint(
              latitude: (loc['lat'] as num).toDouble(),
              longitude: (loc['lng'] as num).toDouble(),
            ),
            placeId: r['place_id'] as String?,
          );
        }).toList();
      }
    } catch (_) {}

    return _fallback.searchPlaces(query, proximity: proximity, bounds: bounds, limit: limit);
  }

  @override
  Future<GeocodedLocation?> reverseGeocode(double latitude, double longitude) async {
    if (provider.apiKey == null || provider.apiKey!.isEmpty) {
      return _fallback.reverseGeocode(latitude, longitude);
    }

    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'latlng': '$latitude,$longitude',
        'key': provider.apiKey,
      });

      final response = await provider.client.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        if (results.isNotEmpty) {
          final first = results.first;
          final loc = first['geometry']['location'];
          return GeocodedLocation(
            formattedAddress: first['formatted_address'] as String,
            point: GeoPoint(
              latitude: (loc['lat'] as num).toDouble(),
              longitude: (loc['lng'] as num).toDouble(),
            ),
            placeId: first['place_id'] as String?,
          );
        }
      }
    } catch (_) {}

    return _fallback.reverseGeocode(latitude, longitude);
  }

  @override
  Future<GeocodedLocation?> getPlaceDetails(String placeId) async {
    return _fallback.getPlaceDetails(placeId);
  }
}

class GoogleRoutingService implements IRoutingService {
  final GoogleMapProvider provider;
  final MockRoutingService _fallback = MockRoutingService();

  GoogleRoutingService({required this.provider});

  @override
  Future<RouteResult> getRoute({
    required GeoPoint origin,
    required GeoPoint destination,
    List<GeoPoint>? waypoints,
    RouteTravelMode travelMode = RouteTravelMode.driving,
    bool optimizeWaypoints = false,
  }) async {
    if (provider.apiKey == null || provider.apiKey!.isEmpty) {
      return _fallback.getRoute(
        origin: origin,
        destination: destination,
        waypoints: waypoints,
        travelMode: travelMode,
      );
    }

    try {
      final params = {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': travelMode.name,
        'key': provider.apiKey,
      };

      if (waypoints != null && waypoints.isNotEmpty) {
        final wpStr = waypoints.map((p) => '${p.latitude},${p.longitude}').join('|');
        params['waypoints'] = optimizeWaypoints ? 'optimize:true|$wpStr' : wpStr;
      }

      final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', params);
      final response = await provider.client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>? ?? [];

        if (routes.isNotEmpty) {
          final route = routes.first;
          final legs = route['legs'] as List<dynamic>? ?? [];
          double totalDistMeters = 0.0;
          double totalDurationSecs = 0.0;
          final steps = <RouteStep>[];

          for (final leg in legs) {
            totalDistMeters += (leg['distance']?['value'] as num?)?.toDouble() ?? 0.0;
            totalDurationSecs += (leg['duration']?['value'] as num?)?.toDouble() ?? 0.0;

            final legSteps = leg['steps'] as List<dynamic>? ?? [];
            for (final s in legSteps) {
              final startLoc = s['start_location'];
              final endLoc = s['end_location'];
              steps.add(
                RouteStep(
                  instruction: s['html_instructions']?.toString().replaceAll(RegExp(r'<[^>]*>'), '') ?? 'Proceed',
                  distanceKm: ((s['distance']?['value'] as num?)?.toDouble() ?? 0.0) / 1000.0,
                  durationMins: ((s['duration']?['value'] as num?)?.toDouble() ?? 0.0) / 60.0,
                  maneuver: s['maneuver'] as String?,
                  startPoint: GeoPoint(latitude: (startLoc['lat'] as num).toDouble(), longitude: (startLoc['lng'] as num).toDouble()),
                  endPoint: GeoPoint(latitude: (endLoc['lat'] as num).toDouble(), longitude: (endLoc['lng'] as num).toDouble()),
                ),
              );
            }
          }

          final polylineStr = route['overview_polyline']?['points'] as String?;

          return RouteResult(
            routeId: 'google_${DateTime.now().millisecondsSinceEpoch}',
            distanceKm: double.parse((totalDistMeters / 1000.0).toStringAsFixed(2)),
            durationMins: double.parse((totalDurationSecs / 60.0).toStringAsFixed(1)),
            polylinePoints: [origin, destination],
            encodedPolyline: polylineStr,
            bounds: GeoBounds.fromPoints([origin, destination]),
            summary: route['summary'] as String? ?? 'Google Maps Route',
            steps: steps,
          );
        }
      }
    } catch (_) {}

    return _fallback.getRoute(
      origin: origin,
      destination: destination,
      waypoints: waypoints,
      travelMode: travelMode,
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
    return [primary];
  }
}

class GoogleDistanceMatrixService implements IDistanceMatrixService {
  final GoogleMapProvider provider;
  final MockDistanceMatrixService _fallback = MockDistanceMatrixService();

  GoogleDistanceMatrixService({required this.provider});

  @override
  Future<DistanceMatrixResult> getDistanceMatrix({
    required List<GeoPoint> origins,
    required List<GeoPoint> destinations,
    RouteTravelMode travelMode = RouteTravelMode.driving,
  }) async {
    if (provider.apiKey == null || provider.apiKey!.isEmpty) {
      return _fallback.getDistanceMatrix(origins: origins, destinations: destinations, travelMode: travelMode);
    }

    try {
      final originsStr = origins.map((p) => '${p.latitude},${p.longitude}').join('|');
      final destsStr = destinations.map((p) => '${p.latitude},${p.longitude}').join('|');

      final uri = Uri.https('maps.googleapis.com', '/maps/api/distancematrix/json', {
        'origins': originsStr,
        'destinations': destsStr,
        'mode': travelMode.name,
        'key': provider.apiKey,
      });

      final response = await provider.client.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rowsJson = data['rows'] as List<dynamic>? ?? [];
        final rows = <DistanceMatrixRow>[];

        for (int oIdx = 0; oIdx < rowsJson.length; oIdx++) {
          final rowJson = rowsJson[oIdx];
          final elementsJson = rowJson['elements'] as List<dynamic>? ?? [];
          final elements = <DistanceMatrixElement>[];

          for (int dIdx = 0; dIdx < elementsJson.length; dIdx++) {
            final el = elementsJson[dIdx];
            final distMeters = (el['distance']?['value'] as num?)?.toDouble() ?? 0.0;
            final durSeconds = (el['duration']?['value'] as num?)?.toDouble() ?? 0.0;

            elements.add(
              DistanceMatrixElement(
                originIndex: oIdx,
                destinationIndex: dIdx,
                origin: origins[oIdx],
                destination: destinations[dIdx],
                distanceKm: double.parse((distMeters / 1000.0).toStringAsFixed(2)),
                durationMins: double.parse((durSeconds / 60.0).toStringAsFixed(1)),
                status: el['status'] == 'OK' ? DistanceMatrixStatus.ok : DistanceMatrixStatus.error,
              ),
            );
          }
          rows.add(DistanceMatrixRow(elements: elements));
        }

        return DistanceMatrixResult(origins: origins, destinations: destinations, rows: rows);
      }
    } catch (_) {}

    return _fallback.getDistanceMatrix(origins: origins, destinations: destinations, travelMode: travelMode);
  }
}

class _GoogleMapWidget extends StatefulWidget {
  final MapCameraPosition initialCamera;
  final Set<MapMarker> markers;
  final Set<MapPolyline> polylines;
  final void Function(IMapController controller)? onMapCreated;
  final void Function(GeoPoint point)? onTap;

  const _GoogleMapWidget({
    required this.initialCamera,
    this.markers = const {},
    this.polylines = const {},
    this.onMapCreated,
    this.onTap,
  });

  @override
  State<_GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<_GoogleMapWidget> implements IMapController {
  late MapCameraPosition _camera;

  @override
  void initState() {
    super.initState();
    _camera = widget.initialCamera;
    widget.onMapCreated?.call(this);
  }

  @override
  Future<void> animateTo(MapCameraPosition position) async {
    setState(() => _camera = position);
  }

  @override
  Future<void> fitBounds(GeoBounds bounds, {double padding = 40.0}) async {
    setState(() => _camera = MapCameraPosition(target: bounds.center, zoom: 13.0));
  }

  @override
  Future<void> addMarker(MapMarker marker) async {}

  @override
  Future<void> removeMarker(String markerId) async {}

  @override
  Future<void> addPolyline(MapPolyline polyline) async {}

  @override
  Future<void> removePolyline(String polylineId) async {}

  @override
  Future<void> clear() async {}

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8ECE9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map, size: 44, color: Color(0xFF1E3A8A)),
            const SizedBox(height: 8),
            Text(
              'Google Maps (${_camera.target.latitude.toStringAsFixed(4)}, ${_camera.target.longitude.toStringAsFixed(4)})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
            ),
            const Text('Google Maps Platform Adapter Active', style: TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
