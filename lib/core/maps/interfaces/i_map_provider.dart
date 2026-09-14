import 'package:flutter/widgets.dart';

import '../models/geo_bounds.dart';
import '../models/geo_point.dart';
import '../models/map_visuals.dart';
import 'i_distance_matrix_service.dart';
import 'i_geocoding_service.dart';
import 'i_routing_service.dart';

/// Supported mapping and geospatial engine vendors.
enum MapVendor {
  googleMaps,
  mapbox,
  here,
  osrm,
  mock,
}

/// Abstract controller for controlling live camera, markers, and visual layers.
abstract class IMapController {
  Future<void> animateTo(MapCameraPosition position);
  Future<void> fitBounds(GeoBounds bounds, {double padding = 40.0});
  Future<void> addMarker(MapMarker marker);
  Future<void> removeMarker(String markerId);
  Future<void> addPolyline(MapPolyline polyline);
  Future<void> removePolyline(String polylineId);
  Future<void> clear();
}

/// Core vendor-agnostic MapProvider abstraction.
///
/// Encapsulates Geocoding, Routing, Distance Matrix, and Map View rendering
/// behind vendor-neutral interfaces to decouple ride business logic from specific SDKs.
abstract class IMapProvider {
  /// Unique vendor identifier
  MapVendor get vendor;

  /// Human-readable vendor name (e.g. "Google Maps", "Mapbox", "HERE Technologies")
  String get name;

  /// Whether the provider has been initialized with credentials/config
  bool get isInitialized;

  /// Sub-service for forward/reverse geocoding and place suggestions
  IGeocodingService get geocoding;

  /// Sub-service for route geometry and turn-by-turn maneuvers
  IRoutingService get routing;

  /// Sub-service for multi-point distance and travel duration matrix
  IDistanceMatrixService get distanceMatrix;

  /// Initialize provider with vendor API key or options
  Future<void> initialize({
    String? apiKey,
    Map<String, dynamic>? options,
  });

  /// Construct vendor-agnostic Map View Widget
  Widget buildMapView({
    required MapCameraPosition initialCamera,
    Set<MapMarker> markers = const {},
    Set<MapPolyline> polylines = const {},
    void Function(IMapController controller)? onMapCreated,
    void Function(GeoPoint point)? onTap,
  });
}
