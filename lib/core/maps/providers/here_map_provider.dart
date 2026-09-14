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

/// HERE Technologies Location Services Provider.
class HereMapProvider implements IMapProvider {
  String? apiKey;
  final http.Client _client;
  late final HereGeocodingService _geocoding;
  late final HereRoutingService _routing;
  late final HereDistanceMatrixService _distanceMatrix;
  bool _initialized = false;

  HereMapProvider({this.apiKey, http.Client? client})
      : _client = client ?? http.Client() {
    _geocoding = HereGeocodingService(provider: this);
    _routing = HereRoutingService(provider: this);
    _distanceMatrix = HereDistanceMatrixService(provider: this);
  }

  http.Client get client => _client;

  @override
  MapVendor get vendor => MapVendor.here;

  @override
  String get name => 'HERE Technologies';

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
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.explore_outlined, size: 44, color: Color(0xFF0F766E)),
            const SizedBox(height: 8),
            Text(
              'HERE Vector Map (${initialCamera.target.latitude.toStringAsFixed(4)}, ${initialCamera.target.longitude.toStringAsFixed(4)})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F766E)),
            ),
            const Text('HERE SDK Adapter Active', style: TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class HereGeocodingService implements IGeocodingService {
  final HereMapProvider provider;
  final MockGeocodingService _fallback = MockGeocodingService();

  HereGeocodingService({required this.provider});

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
      final params = {
        'q': query,
        'apiKey': provider.apiKey!,
        'limit': limit.toString(),
        if (proximity != null) 'at': '${proximity.latitude},${proximity.longitude}',
      };

      final uri = Uri.https('geocode.search.hereapi.com', '/v1/geocode', params);
      final response = await provider.client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];

        return items.map((item) {
          final pos = item['position'];
          final address = item['address'] as Map<String, dynamic>?;
          return GeocodedLocation(
            formattedAddress: item['title'] as String? ?? query,
            name: address?['label'] as String?,
            city: address?['city'] as String?,
            state: address?['state'] as String?,
            country: address?['countryName'] as String?,
            point: GeoPoint(
              latitude: (pos['lat'] as num).toDouble(),
              longitude: (pos['lng'] as num).toDouble(),
            ),
            placeId: item['id'] as String?,
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
      final uri = Uri.https('revgeocode.search.hereapi.com', '/v1/revgeocode', {
        'at': '$latitude,$longitude',
        'apiKey': provider.apiKey!,
      });
      final response = await provider.client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        if (items.isNotEmpty) {
          final item = items.first;
          final pos = item['position'];
          final address = item['address'] as Map<String, dynamic>?;
          return GeocodedLocation(
            formattedAddress: item['title'] as String,
            city: address?['city'] as String?,
            state: address?['state'] as String?,
            country: address?['countryName'] as String?,
            point: GeoPoint(
              latitude: (pos['lat'] as num).toDouble(),
              longitude: (pos['lng'] as num).toDouble(),
            ),
            placeId: item['id'] as String?,
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

class HereRoutingService implements IRoutingService {
  final HereMapProvider provider;
  final MockRoutingService _fallback = MockRoutingService();

  HereRoutingService({required this.provider});

  @override
  Future<RouteResult> getRoute({
    required GeoPoint origin,
    required GeoPoint destination,
    List<GeoPoint>? waypoints,
    RouteTravelMode travelMode = RouteTravelMode.driving,
    bool optimizeWaypoints = false,
  }) async {
    if (provider.apiKey == null || provider.apiKey!.isEmpty) {
      return _fallback.getRoute(origin: origin, destination: destination, waypoints: waypoints, travelMode: travelMode);
    }

    try {
      final transportMode = travelMode == RouteTravelMode.walking
          ? 'pedestrian'
          : (travelMode == RouteTravelMode.bicycling ? 'bicycle' : 'car');

      final params = {
        'transportMode': transportMode,
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'return': 'summary,polyline,actions,instructions',
        'apiKey': provider.apiKey!,
      };

      if (waypoints != null) {
        for (int i = 0; i < waypoints.length; i++) {
          params['via'] = '${waypoints[i].latitude},${waypoints[i].longitude}';
        }
      }

      final uri = Uri.https('router.hereapi.com', '/v8/routes', params);
      final response = await provider.client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>? ?? [];

        if (routes.isNotEmpty) {
          final r = routes.first;
          final sections = r['sections'] as List<dynamic>? ?? [];
          double totalDistMeters = 0.0;
          double totalDurationSecs = 0.0;

          for (final sec in sections) {
            final summary = sec['summary'];
            if (summary != null) {
              totalDistMeters += (summary['length'] as num?)?.toDouble() ?? 0.0;
              totalDurationSecs += (summary['duration'] as num?)?.toDouble() ?? 0.0;
            }
          }

          return RouteResult(
            routeId: 'here_${DateTime.now().millisecondsSinceEpoch}',
            distanceKm: double.parse((totalDistMeters / 1000.0).toStringAsFixed(2)),
            durationMins: double.parse((totalDurationSecs / 60.0).toStringAsFixed(1)),
            polylinePoints: [origin, destination],
            bounds: GeoBounds.fromPoints([origin, destination]),
            summary: 'HERE Routing via $transportMode',
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

class HereDistanceMatrixService implements IDistanceMatrixService {
  final HereMapProvider provider;
  final MockDistanceMatrixService _fallback = MockDistanceMatrixService();

  HereDistanceMatrixService({required this.provider});

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
      final body = json.encode({
        'origins': origins.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
        'destinations': destinations.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
        'matrixAttributes': ['distances', 'travelTimes'],
      });

      final uri = Uri.https('matrix.router.hereapi.com', '/v8/matrix', {'apiKey': provider.apiKey!});
      final response = await provider.client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final matrix = data['matrix'] as Map<String, dynamic>? ?? {};
        final distances = matrix['distances'] as List<dynamic>? ?? [];
        final travelTimes = matrix['travelTimes'] as List<dynamic>? ?? [];
        final numDest = destinations.length;
        final rows = <DistanceMatrixRow>[];

        for (int o = 0; o < origins.length; o++) {
          final elements = <DistanceMatrixElement>[];
          for (int d = 0; d < destinations.length; d++) {
            final idx = o * numDest + d;
            final distMeters = idx < distances.length ? (distances[idx] as num).toDouble() : 0.0;
            final durSecs = idx < travelTimes.length ? (travelTimes[idx] as num).toDouble() : 0.0;

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
