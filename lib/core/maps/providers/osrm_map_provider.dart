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

/// OpenStreetMap & OSRM Open-Source Routing Engine Provider.
class OsrmMapProvider implements IMapProvider {
  final String osrmBaseUrl;
  final String nominatimBaseUrl;
  final http.Client _client;
  late final OsrmGeocodingService _geocoding;
  late final OsrmRoutingService _routing;
  late final OsrmDistanceMatrixService _distanceMatrix;
  bool _initialized = true;

  OsrmMapProvider({
    this.osrmBaseUrl = 'router.project-osrm.org',
    this.nominatimBaseUrl = 'nominatim.openstreetmap.org',
    http.Client? client,
  })  : _client = client ?? http.Client() {
    _geocoding = OsrmGeocodingService(provider: this);
    _routing = OsrmRoutingService(provider: this);
    _distanceMatrix = OsrmDistanceMatrixService(provider: this);
  }

  http.Client get client => _client;

  @override
  MapVendor get vendor => MapVendor.osrm;

  @override
  String get name => 'OpenStreetMap / OSRM';

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
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.public, size: 44, color: Color(0xFF0284C7)),
            const SizedBox(height: 8),
            Text(
              'OSM Map Tiles (${initialCamera.target.latitude.toStringAsFixed(4)}, ${initialCamera.target.longitude.toStringAsFixed(4)})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0284C7)),
            ),
            const Text('OpenStreetMap & OSRM Engine Active', style: TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class OsrmGeocodingService implements IGeocodingService {
  final OsrmMapProvider provider;
  final MockGeocodingService _fallback = MockGeocodingService();

  OsrmGeocodingService({required this.provider});

  @override
  Future<List<GeocodedLocation>> searchPlaces(
    String query, {
    GeoPoint? proximity,
    GeoBounds? bounds,
    int limit = 5,
  }) async {
    try {
      final uri = Uri.https(provider.nominatimBaseUrl, '/search', {
        'q': query,
        'format': 'json',
        'limit': limit.toString(),
        'addressdetails': '1',
      });

      final response = await provider.client.get(
        uri,
        headers: {'User-Agent': 'CabApp-Mobility/1.0'},
      );

      if (response.statusCode == 200) {
        final results = json.decode(response.body) as List<dynamic>? ?? [];
        return results.map((r) {
          final address = r['address'] as Map<String, dynamic>?;
          return GeocodedLocation(
            formattedAddress: r['display_name'] as String? ?? query,
            name: r['name'] as String?,
            city: address?['city'] ?? address?['town'] ?? address?['state_district'],
            state: address?['state'] as String?,
            country: address?['country'] as String?,
            point: GeoPoint(
              latitude: double.parse(r['lat'].toString()),
              longitude: double.parse(r['lon'].toString()),
            ),
            placeId: r['place_id']?.toString(),
          );
        }).toList();
      }
    } catch (_) {}

    return _fallback.searchPlaces(query, proximity: proximity, bounds: bounds, limit: limit);
  }

  @override
  Future<GeocodedLocation?> reverseGeocode(double latitude, double longitude) async {
    try {
      final uri = Uri.https(provider.nominatimBaseUrl, '/reverse', {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'json',
      });

      final response = await provider.client.get(
        uri,
        headers: {'User-Agent': 'CabApp-Mobility/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        return GeocodedLocation(
          formattedAddress: data['display_name'] as String,
          city: address?['city'] ?? address?['town'],
          state: address?['state'] as String?,
          country: address?['country'] as String?,
          point: GeoPoint(latitude: latitude, longitude: longitude),
          placeId: data['place_id']?.toString(),
        );
      }
    } catch (_) {}

    return _fallback.reverseGeocode(latitude, longitude);
  }

  @override
  Future<GeocodedLocation?> getPlaceDetails(String placeId) async {
    return _fallback.getPlaceDetails(placeId);
  }
}

class OsrmRoutingService implements IRoutingService {
  final OsrmMapProvider provider;
  final MockRoutingService _fallback = MockRoutingService();

  OsrmRoutingService({required this.provider});

  @override
  Future<RouteResult> getRoute({
    required GeoPoint origin,
    required GeoPoint destination,
    List<GeoPoint>? waypoints,
    RouteTravelMode travelMode = RouteTravelMode.driving,
    bool optimizeWaypoints = false,
  }) async {
    try {
      final coords = ['${origin.longitude},${origin.latitude}'];
      if (waypoints != null) {
        for (final wp in waypoints) {
          coords.add('${wp.longitude},${wp.latitude}');
        }
      }
      coords.add('${destination.longitude},${destination.latitude}');

      final coordsPath = coords.join(';');
      final uri = Uri.https(provider.osrmBaseUrl, '/route/v1/driving/$coordsPath', {
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'true',
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

          final legs = r['legs'] as List<dynamic>? ?? [];
          final steps = <RouteStep>[];

          for (final leg in legs) {
            final legSteps = leg['steps'] as List<dynamic>? ?? [];
            for (final s in legSteps) {
              final maneuver = s['maneuver'] as Map<String, dynamic>?;
              final loc = maneuver?['location'] as List<dynamic>?;
              steps.add(
                RouteStep(
                  instruction: s['name'] != null && s['name'].toString().isNotEmpty
                      ? 'Drive on ${s['name']}'
                      : 'Proceed on road',
                  distanceKm: ((s['distance'] as num?)?.toDouble() ?? 0.0) / 1000.0,
                  durationMins: ((s['duration'] as num?)?.toDouble() ?? 0.0) / 60.0,
                  maneuver: maneuver?['type'] as String?,
                  startPoint: loc != null
                      ? GeoPoint(latitude: (loc[1] as num).toDouble(), longitude: (loc[0] as num).toDouble())
                      : origin,
                  endPoint: destination,
                ),
              );
            }
          }

          return RouteResult(
            routeId: 'osrm_${DateTime.now().millisecondsSinceEpoch}',
            distanceKm: double.parse((distMeters / 1000.0).toStringAsFixed(2)),
            durationMins: double.parse((durSecs / 60.0).toStringAsFixed(1)),
            polylinePoints: points.isNotEmpty ? points : [origin, destination],
            bounds: GeoBounds.fromPoints([origin, destination]),
            summary: 'OSRM Route',
            steps: steps,
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

class OsrmDistanceMatrixService implements IDistanceMatrixService {
  final OsrmMapProvider provider;
  final MockDistanceMatrixService _fallback = MockDistanceMatrixService();

  OsrmDistanceMatrixService({required this.provider});

  @override
  Future<DistanceMatrixResult> getDistanceMatrix({
    required List<GeoPoint> origins,
    required List<GeoPoint> destinations,
    RouteTravelMode travelMode = RouteTravelMode.driving,
  }) async {
    try {
      final allPoints = <GeoPoint>[...origins, ...destinations];
      final coordsStr = allPoints.map((p) => '${p.longitude},${p.latitude}').join(';');
      final sourcesStr = List.generate(origins.length, (i) => '$i').join(';');
      final destsStr = List.generate(destinations.length, (i) => '${origins.length + i}').join(';');

      final uri = Uri.https(provider.osrmBaseUrl, '/table/v1/driving/$coordsStr', {
        'sources': sourcesStr,
        'destinations': destsStr,
        'annotations': 'duration,distance',
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
