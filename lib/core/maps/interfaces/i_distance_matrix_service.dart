import '../models/distance_matrix_result.dart';
import '../models/geo_point.dart';
import '../models/route_result.dart';

/// Abstract service defining multi-origin multi-destination distance & ETA matrix calculations.
abstract class IDistanceMatrixService {
  /// Calculate NxM distance and duration table between origins and destinations
  Future<DistanceMatrixResult> getDistanceMatrix({
    required List<GeoPoint> origins,
    required List<GeoPoint> destinations,
    RouteTravelMode travelMode = RouteTravelMode.driving,
  });
}
