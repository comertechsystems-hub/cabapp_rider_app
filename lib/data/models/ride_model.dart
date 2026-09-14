import '../../domain/entities/ride.dart';
import 'driver_details_model.dart';

class RideModel extends ActiveRide {
  final String? driverName;
  final String? driverPhone;
  final String? vehicle;
  final String currency;

  const RideModel({
    required super.id,
    required super.riderId,
    super.driverId,
    this.driverName,
    this.driverPhone,
    this.vehicle,
    required super.vehicleCategory,
    required super.status,
    required super.pickupAddress,
    required super.pickupLat,
    required super.pickupLng,
    required super.destinationAddress,
    required super.destinationLat,
    required super.destinationLng,
    required super.totalFare,
    super.finalFare,
    this.currency = 'NGN',
    super.startOtp,
    super.paymentMethod = 'CASH',
    super.paymentStatus = 'PENDING',
    super.actualDistanceKm,
    super.actualDurationMins,
    super.serviceArea,
    super.driverDetails,
    super.createdAt,
  });

  String get rider => riderId;
  String? get driver => driverId;

  bool get isAssigned => isDriverAssigned;
  bool get isAccepted => isDriverAccepted;
  bool get isEnRoute => isDriverEnRoute;
  bool get isArrived => isDriverArrived;

  factory RideModel.fromJson(Map<String, dynamic> json) {
    DriverDetailsModel? driverDetails;
    if (json['driver_details'] is Map<String, dynamic>) {
      driverDetails = DriverDetailsModel.fromJson(json['driver_details']);
    } else if (json['driver'] != null || json['driver_name'] != null) {
      driverDetails = DriverDetailsModel(
        id: json['driver'] ?? '',
        name: json['driver_name'] ?? 'Driver Partner',
        phoneNumber: json['driver_phone'] ?? '',
        photoUrl: json['driver_photo'],
        rating: (json['driver_rating'] as num?)?.toDouble() ?? 5.0,
        vehicleMake: json['vehicle_make'] ?? 'Toyota',
        vehicleModel: json['vehicle_model'] ?? json['vehicle'] ?? 'Corolla',
        vehicleColor: json['vehicle_color'] ?? 'Silver',
        licensePlate: json['license_plate'] ?? json['vehicle'] ?? 'LAG-123XY',
        vehicleCategory: json['vehicle_category'] ?? 'ECONOMY',
      );
    }

    return RideModel(
      id: json['name'] ?? json['id'] ?? '',
      riderId: json['rider'] ?? json['rider_id'] ?? '',
      driverId: json['driver'] ?? json['driver_id'],
      driverName: json['driver_name'] ?? driverDetails?.name,
      driverPhone: json['driver_phone'] ?? driverDetails?.phoneNumber,
      vehicle: json['vehicle'] ?? driverDetails?.licensePlate,
      vehicleCategory: json['vehicle_category'] ?? 'ECONOMY',
      status: json['status'] ?? 'REQUESTED',
      pickupAddress: json['pickup_address'] ?? '',
      pickupLat: (json['pickup_lat'] as num?)?.toDouble() ?? 0.0,
      pickupLng: (json['pickup_lng'] as num?)?.toDouble() ?? 0.0,
      destinationAddress: json['destination_address'] ?? '',
      destinationLat: (json['destination_lat'] as num?)?.toDouble() ?? 0.0,
      destinationLng: (json['destination_lng'] as num?)?.toDouble() ?? 0.0,
      totalFare: (json['total_fare'] as num?)?.toDouble() ?? 0.0,
      finalFare: (json['final_fare'] as num?)?.toDouble(),
      currency: json['currency'] ?? 'NGN',
      startOtp: json['start_otp']?.toString(),
      paymentMethod: json['payment_method'] ?? 'CASH',
      paymentStatus: json['payment_status'] ?? 'PENDING',
      actualDistanceKm: (json['actual_distance_km'] as num?)?.toDouble(),
      actualDurationMins: (json['actual_duration_mins'] as num?)?.toDouble(),
      serviceArea: json['service_area'],
      driverDetails: driverDetails,
      createdAt: json['creation'] != null
          ? DateTime.tryParse(json['creation'])
          : (json['timestamp'] != null ? DateTime.tryParse(json['timestamp']) : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': id,
        'rider': riderId,
        'driver': driverId,
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'vehicle': vehicle,
        'vehicle_category': vehicleCategory,
        'status': status,
        'pickup_address': pickupAddress,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'destination_address': destinationAddress,
        'destination_lat': destinationLat,
        'destination_lng': destinationLng,
        'total_fare': totalFare,
        'final_fare': finalFare,
        'currency': currency,
        'start_otp': startOtp,
        'payment_method': paymentMethod,
        'payment_status': paymentStatus,
        'service_area': serviceArea,
        'creation': createdAt?.toIso8601String(),
      };
}
