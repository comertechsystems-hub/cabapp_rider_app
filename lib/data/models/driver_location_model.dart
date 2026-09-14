import '../../domain/entities/driver_location.dart';

class DriverLocationModel extends DriverLocationEvent {
  const DriverLocationModel({
    required super.rideId,
    required super.driverId,
    required super.latitude,
    required super.longitude,
    super.bearing,
    super.speedKmh,
    super.accuracyMeters,
    required super.recordedAt,
  });

  factory DriverLocationModel.fromJson(Map<String, dynamic> json) {
    return DriverLocationModel(
      rideId: json['ride'] ?? json['ride_id'] ?? '',
      driverId: json['driver'] ?? json['driver_id'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? (json['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? (json['lng'] as num?)?.toDouble() ?? 0.0,
      bearing: (json['bearing_degrees'] as num?)?.toDouble() ?? (json['bearing'] as num?)?.toDouble() ?? 0.0,
      speedKmh: (json['speed_kmh'] as num?)?.toDouble() ?? (json['speed'] as num?)?.toDouble() ?? 0.0,
      accuracyMeters: (json['accuracy_meters'] as num?)?.toDouble() ?? (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      recordedAt: json['recorded_at'] != null
          ? DateTime.tryParse(json['recorded_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'ride_id': rideId,
        'driver_id': driverId,
        'latitude': latitude,
        'longitude': longitude,
        'bearing': bearing,
        'speed_kmh': speedKmh,
        'accuracy_meters': accuracyMeters,
        'recorded_at': recordedAt.toIso8601String(),
      };
}
