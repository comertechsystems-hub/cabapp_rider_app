import 'dart:math' as math;
import 'geo_point.dart';

/// Geographic bounding box defining a rectangular region on a map.
class GeoBounds {
  final GeoPoint northeast;
  final GeoPoint southwest;

  const GeoBounds({
    required this.northeast,
    required this.southwest,
  });

  /// Check if a point lies within this bounding box
  bool contains(GeoPoint point) {
    return point.latitude >= southwest.latitude &&
        point.latitude <= northeast.latitude &&
        point.longitude >= southwest.longitude &&
        point.longitude <= northeast.longitude;
  }

  /// Create bounds encompassing a list of points
  factory GeoBounds.fromPoints(List<GeoPoint> points) {
    if (points.isEmpty) {
      throw ArgumentError('Cannot create GeoBounds from an empty list of points');
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }

    return GeoBounds(
      northeast: GeoPoint(latitude: maxLat, longitude: maxLng),
      southwest: GeoPoint(latitude: minLat, longitude: minLng),
    );
  }

  GeoPoint get center => GeoPoint(
        latitude: (northeast.latitude + southwest.latitude) / 2.0,
        longitude: (northeast.longitude + southwest.longitude) / 2.0,
      );

  Map<String, dynamic> toJson() => {
        'northeast': northeast.toJson(),
        'southwest': southwest.toJson(),
      };

  factory GeoBounds.fromJson(Map<String, dynamic> json) {
    return GeoBounds(
      northeast: GeoPoint.fromJson(json['northeast'] as Map<String, dynamic>),
      southwest: GeoPoint.fromJson(json['southwest'] as Map<String, dynamic>),
    );
  }

  @override
  String toString() => 'GeoBounds(NE: $northeast, SW: $southwest)';
}
