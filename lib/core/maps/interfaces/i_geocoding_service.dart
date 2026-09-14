import '../models/geo_bounds.dart';
import '../models/geo_point.dart';
import '../models/geocoded_location.dart';

/// Abstract service defining forward, reverse, and place-search geocoding.
abstract class IGeocodingService {
  /// Forward geocode text address into coordinate locations
  Future<List<GeocodedLocation>> searchPlaces(
    String query, {
    GeoPoint? proximity,
    GeoBounds? bounds,
    int limit = 5,
  });

  /// Reverse geocode GPS coordinate into human-readable address
  Future<GeocodedLocation?> reverseGeocode(
    double latitude,
    double longitude,
  );

  /// Retrieve detailed place attributes by unique placeId
  Future<GeocodedLocation?> getPlaceDetails(String placeId);
}
