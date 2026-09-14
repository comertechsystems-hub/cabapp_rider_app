/// Pure domain entity representing a driver location telemetry event.
class DriverLocationEvent {
  final String rideId;
  final String driverId;
  final double latitude;
  final double longitude;
  final double bearing;
  final double speedKmh;
  final double accuracyMeters;
  final DateTime recordedAt;

  const DriverLocationEvent({
    required this.rideId,
    required this.driverId,
    required this.latitude,
    required this.longitude,
    this.bearing = 0.0,
    this.speedKmh = 0.0,
    this.accuracyMeters = 0.0,
    required this.recordedAt,
  });
}
