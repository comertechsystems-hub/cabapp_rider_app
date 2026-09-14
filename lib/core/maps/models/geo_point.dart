import 'dart:math' as math;

/// Vendor-agnostic geographic coordinate entity.
class GeoPoint {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? heading;
  final double? accuracy;
  final DateTime? timestamp;

  const GeoPoint({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.heading,
    this.accuracy,
    this.timestamp,
  });

  /// Calculate great-circle distance to another point in kilometers using Haversine formula
  double distanceTo(GeoPoint other) {
    const radiusKm = 6371.0;
    final dLat = _toRadians(other.latitude - latitude);
    final dLng = _toRadians(other.longitude - longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(latitude)) *
            math.cos(_toRadians(other.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return radiusKm * c;
  }

  /// Initial bearing from this point to target point in degrees (0..360)
  double bearingTo(GeoPoint other) {
    final lat1 = _toRadians(latitude);
    final lat2 = _toRadians(other.latitude);
    final dLng = _toRadians(other.longitude - longitude);

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final radians = math.atan2(y, x);
    return (_toDegrees(radians) + 360) % 360;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;
  static double _toDegrees(double radians) => radians * 180.0 / math.pi;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (altitude != null) 'altitude': altitude,
        if (heading != null) 'heading': heading,
        if (accuracy != null) 'accuracy': accuracy,
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      };

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoPoint &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}
