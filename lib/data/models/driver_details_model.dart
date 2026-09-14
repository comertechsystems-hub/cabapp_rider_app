import '../../domain/entities/driver_details.dart';

class DriverDetailsModel extends DriverDetails {
  const DriverDetailsModel({
    required super.id,
    required super.name,
    required super.phoneNumber,
    super.photoUrl,
    super.rating,
    super.totalTrips,
    required super.vehicleMake,
    required super.vehicleModel,
    required super.vehicleColor,
    required super.licensePlate,
    required super.vehicleCategory,
    super.currentLat,
    super.currentLng,
    super.bearing,
  });

  factory DriverDetailsModel.fromJson(Map<String, dynamic> json) {
    return DriverDetailsModel(
      id: json['id'] ?? json['name'] ?? json['driver'] ?? '',
      name: json['name'] ?? json['driver_name'] ?? json['full_name'] ?? 'Driver Partner',
      phoneNumber: json['phone_number'] ?? json['phone'] ?? json['driver_phone'] ?? '',
      photoUrl: json['photo_url'] ?? json['image'],
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      totalTrips: (json['total_trips'] as num?)?.toInt() ?? 0,
      vehicleMake: json['vehicle_make'] ?? json['make'] ?? 'Toyota',
      vehicleModel: json['vehicle_model'] ?? json['model'] ?? 'Corolla',
      vehicleColor: json['vehicle_color'] ?? json['color'] ?? 'Silver',
      licensePlate: json['license_plate'] ?? json['plate_number'] ?? 'LAG-123XY',
      vehicleCategory: json['vehicle_category'] ?? 'ECONOMY',
      currentLat: (json['current_lat'] as num?)?.toDouble() ?? (json['lat'] as num?)?.toDouble(),
      currentLng: (json['current_lng'] as num?)?.toDouble() ?? (json['lng'] as num?)?.toDouble(),
      bearing: (json['bearing'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone_number': phoneNumber,
        'photo_url': photoUrl,
        'rating': rating,
        'total_trips': totalTrips,
        'vehicle_make': vehicleMake,
        'vehicle_model': vehicleModel,
        'vehicle_color': vehicleColor,
        'license_plate': licensePlate,
        'vehicle_category': vehicleCategory,
        'current_lat': currentLat,
        'current_lng': currentLng,
        'bearing': bearing,
      };
}
