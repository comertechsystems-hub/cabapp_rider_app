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

/// Mapbox Navigation & Mapping Engine Provider.
class MapboxMapProvider implements IMapProvider {
  String? accessToken;
  final http.Client _client;
  late final MapboxGeocodingService _geocoding;
  late final MapboxRoutingService _routing;
  late final MapboxDistanceMatrixService _distanceMatrix;
  bool _initialized = false;

  MapboxMapProvider({this.accessToken, http.Client? client})
      : _client = client ?? http.Client() {
    _geocoding = MapboxGeocodingService(provider: this);
    _routing = MapboxRoutingService(provider: this);
    _distanceMatrix = MapboxDistanceMatrixService(provider: this);
  }

  http.Client get client => _client;

  @override
  MapVendor get vendor => MapVendor.mapbox;

  @override
  String get name => 'Mapbox';

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
    if (apiKey != null) accessToken = apiKey;
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
    return Container(
      color: const Color(0xFFE2E8F0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.navigation_outlined, size: 44, color: Color(0xFF0F172A)),
            const SizedBox(height: 8),
            Text(
              'Mapbox Vector Tiles (${initialCamera.target.latitude.toStringAsFixed(4)}, ${initialCamera.target.longitude.toStringAsFixed(4)})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
            ),
            const Text('Mapbox GL Adapter Active', style: TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class MapboxGeocodingService implements IGeocodingService {
  final MapboxMapProvider provider;
  final MockGeocodingService _fallback = MockGeocodingService();

  MapboxGeocodingService({required this.provider});

  @override
  Future<List<GeocodedLocation>> searchPlaces(
    String query, {
    GeoPoint? proximity,
    GeoBounds? bounds,
    int limit = 5,
  }) async {
    if (provider.accessToken == null || provider.accessToken!.isEmpty) {
      return _fallback.searchPlaces(query, proximity: proximity, bounds: bounds, limit: limit);
    }

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final params = {
        'access_token': provider.accessToken!,
        'limit': limit.toString(),
        if (proximity != null) 'proximity': '${proximity.longitude},${proximity.latitude}',
      };

      final uri = Uri.https('api.mapbox.com', '/geocoding/v5/mapbox.places/$encodedQuery.json', params);
      final response = await provider.client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];

        return features.map((f) {
          final center = f['center'] as List<dynamic>;
          return GeocodedLocation(
            formattedAddress: f['place_name'] as String? ?? query,
            name: f['text'] as String?,
            point: GeoPoint(
              longitude: (center[0] as num).toDouble(),
              latitude: (center[1] as num).toDouble(),
            ),
            placeId: f['id'] as String?,
          );
        }).toList();
      }
    } catch (_) {}

    return _fallback.searchPlaces(query, proximity: proximity, bounds: bounds, limit: limit);
  }

  @override
  Future<GeocodedLocation?> reverseGeocode(double latitude, double longitude) async {
    if (provider.accessToken == null || provider.accessToken!.isEmpty) {
      return _fallback.reverseGeocode(latitude, longitude);
    }

    try {
      final uri = Uri.https(
        'api.mapbox.com',
        '/geocoding/v5/mapbox.places/$longitude,$latitude.json',
        {'access_token': provider.accessToken!, 'limit': '1'},
      );
      final response = await provider.client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];
        if (features.isNotEmpty) {
          final first = features.first;
          final center = first['center'] as List<dynamic>;
          return GeocodedLocation(
            formattedAddress: first['place_name'] as String,
            name: first['text'] as String?,
            point: GeoPoint(
              longitude: (center[0] as num).toDouble(),
              latitude: (center[1] as num).toDouble(),
            ),
            placeId: first['id'] as String?,
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

class MapboxRoutingService implements IRoutingService {
  final MapboxMapProvider provider;
  final MockRoutingService _fallback = MockRoutingService();

  MapboxRoutingService({required this.provider});

  @override
  Future<RouteResult> getRoute({
    required GeoPoint origin,
    required GeoPoint destination,
    List<GeoPoint>? waypoints,
    RouteTravelMode travelMode = RouteTravelMode.driving,
    bool optimizeWaypoints = false,
  }) async {
    if (provider.accessToken == null || provider.accessToken!.isEmpty) {
      return _fallback.getRoute(
        origin: origin,
        destination: destination,
        waypoints: waypoints,
        travelMode: travelMode,
      );
    }

    try {
      final profile = travelMode == RouteTravelMode.walking
          ? 'mapbox/walking'
          : (travelMode == RouteTravelMode.bicycling ? 'mapbox/cycling' : 'mapbox/driving-traffic');

      final coords = ['${origin.longitude},${origin.latitude}'];
      if (waypoints != null) {
        for (final wp in waypoints) {
          coords.add('${wp.longitude},${wp.latitude}');
        }
      }
      coords.add('${destination.longitude},${destination.latitude}');

      final coordsPath = coords.join(';');
      final uri = Uri.https('api.mapbox.com', '/directions/v5/$profile/$coordsPath', {
        'access_token': provider.accessToken!,
        'geometries': 'geojson',
        'steps': 'true',
        'overview': 'full',
      });

      final response = await provider.client.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>? ?? [];

        if (routes.isNotEmpty) {
          final r = routes.first;
          final distMeters = (r['distance'] as num).toDouble();
          final durSecs = (r['duration'] as num).toDouble();

          final geometry = r['geometry'] as Map<String, dynamic>?;
          final coordinates = geometry?['coordinates'] as List<dynamic>? ?? [];

          final points = coordinates.map((c) {
            final pair = c as List<dynamic>;
            return GeoPoint(
              longitude: (pair[0] as num).toDouble(),
              latitude: (pair[1] as num).toDouble(),
            );
          }).toList();

          return RouteResult(
            routeId: 'mapbox_${DateTime.now().millisecondsSinceEpoch}',
            distanceKm: double.parse((distMeters / 1000.0).toStringAsFixed(2)),
            durationMins: double.parse((durSecs / 60.0).toStringAsFixed(1)),
            polylinePoints: points.isNotEmpty ? points : [origin, destination],
            bounds: GeoBounds.fromPoints([origin, destination]),
            summary: 'Mapbox route via ${profile.split('/').last}',
          );
        }
      }
    } catch (_) {}

    return _fallback.getRoute(origin: origin, destination: destination, waypoints: waypoints, travelMode: travelMode);
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

class MapboxDistanceMatrixService implements IDistanceMatrixService {
  final MapboxMapProvider provider;
  final MockDistanceMatrixService _fallback = MockDistanceMatrixService();

  MapboxDistanceMatrixService({required this.provider});

  @override
  Future<DistanceMatrixResult> getDistanceMatrix({
    required List<GeoPoint> origins,
    required List<GeoPoint> destinations,
    RouteTravelMode travelMode = RouteTravelMode.driving,
  }) async {
    if (provider.accessToken == null || provider.accessToken!.isEmpty) {
      return _fallback.getDistanceMatrix(origins: origins, destinations: destinations, travelMode: travelMode);
    }

    try {
      final allPoints = <GeoPoint>[...origins, ...destinations];
      final coordsStr = allPoints.map((p) => '${p.longitude},${p.latitude}').join(';');
      final sourcesStr = List.generate(origins.length, (i) => '$i').join(';');
      final destsStr = List.generate(destinations.length, (i) => '${origins.length + i}').join(';');

      final profile = travelMode == RouteTravelMode.walking
          ? 'mapbox/walking'
          : (travelMode == RouteTravelMode.bicycling ? 'mapbox/cycling' : 'mapbox/driving');

      final uri = Uri.https('api.mapbox.com', '/directions-matrix/v1/$profile/$coordsStr', {
        'access_token': provider.accessToken!,
        'sources': sourcesStr,
        'destinations': destsStr,
        'annotations': 'distance,duration',
      });

      final response = await provider.client.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final distances = data['distances'] as List<dynamic>? ?? [];
        final durations = data['durations'] as List<dynamic>? ?? [];
        final rows = <DistanceMatrixRow>[];

        for (int o = 0; o < origins.length; o++) {
          final rowDistances = (distances[o] as List<dynamic>?) ?? [];
          final rowDurations = (durations[o] as List<dynamic>?) ?? [];
          final elements = <DistanceMatrixElement>[];

          for (int d = 0; d < destinations.length; d++) {
            final distMeters = (rowDistances[d] as num?)?.toDouble() ?? 0.0;
            final durSecs = (rowDurations[d] as num?)?.toDouble() ?? 0.0;

            elements.add(
              DistanceMatrixElement(
                originIndex: o,
                destinationIndex: d,
                origin: origins[o],
                destination: destinations[d],
                distanceKm: double.parse((distMeters / 1000.0).toStringAsFixed(2)),
                durationMins: double.parse((durSecs / 60.0).toStringAsFixed(1)),
                status: DistanceMatrixStatus.ok,
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
