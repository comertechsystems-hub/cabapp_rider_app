import '../models/geo_point.dart';
import '../models/route_result.dart';

/// Abstract service defining routing, polyline geometry, and turn-by-turn maneuvers.
abstract class IRoutingService {
  /// Calculate route between origin and destination with optional intermediate waypoints
  Future<RouteResult> getRoute({
    required GeoPoint origin,
    required GeoPoint destination,
    List<GeoPoint>? waypoints,
    RouteTravelMode travelMode = RouteTravelMode.driving,
    bool optimizeWaypoints = false,
  });

  /// Retrieve alternative candidate routes between origin and destination
  Future<List<RouteResult>> getAlternativeRoutes({
    required GeoPoint origin,
    required GeoPoint destination,
    int maxAlternatives = 2,
    RouteTravelMode travelMode = RouteTravelMode.driving,
  });
}
