import '../../domain/entities/trip_history.dart';

class TripHistoryModel extends TripHistoryItem {
  const TripHistoryModel({
    required super.rideId,
    required super.status,
    required super.pickupAddress,
    required super.destinationAddress,
    required super.fare,
    super.driverName,
    super.vehicleModel,
    required super.vehicleCategory,
    required super.createdAt,
  });

  factory TripHistoryModel.fromJson(Map<String, dynamic> json) {
    return TripHistoryModel(
      rideId: json['name'] ?? json['id'] ?? json['ride_id'] ?? '',
      status: json['status'] ?? 'COMPLETED',
      pickupAddress: json['pickup_address'] ?? 'Pickup location',
      destinationAddress: json['destination_address'] ?? 'Destination location',
      fare: (json['final_fare'] as num?)?.toDouble() ??
          (json['total_fare'] as num?)?.toDouble() ??
          0.0,
      driverName: json['driver_name'],
      vehicleModel: json['vehicle_model'] ?? json['vehicle'],
      vehicleCategory: json['vehicle_category'] ?? 'ECONOMY',
      createdAt: json['creation'] != null
          ? DateTime.tryParse(json['creation']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': rideId,
        'status': status,
        'pickup_address': pickupAddress,
        'destination_address': destinationAddress,
        'final_fare': fare,
        'driver_name': driverName,
        'vehicle_model': vehicleModel,
        'vehicle_category': vehicleCategory,
        'creation': createdAt.toIso8601String(),
      };
}
