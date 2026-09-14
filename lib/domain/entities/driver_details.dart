/// Pure domain entity representing assigned driver information and vehicle details.
class DriverDetails {
  final String id;
  final String name;
  final String phoneNumber;
  final String? photoUrl;
  final double rating;
  final int totalTrips;
  final String vehicleMake;
  final String vehicleModel;
  final String vehicleColor;
  final String licensePlate;
  final String vehicleCategory;
  final double? currentLat;
  final double? currentLng;
  final double? bearing;

  const DriverDetails({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.photoUrl,
    this.rating = 5.0,
    this.totalTrips = 0,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.licensePlate,
    required this.vehicleCategory,
    this.currentLat,
    this.currentLng,
    this.bearing,
  });

  String get vehicleDescription => '$vehicleColor $vehicleMake $vehicleModel';
}
