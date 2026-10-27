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
    super.driverLat,
    super.driverLng,
    super.driverEtaMins,
    super.driverDistanceKm,
    super.chatMessages = const [],
    super.createdAt,
    super.offeredFare,
    super.agreedFare,
    super.biddingStatus,
    super.surgeMultiplier,
    super.surgeReason,
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

    final dLat = (json['driver_lat'] as num?)?.toDouble() ??
        (json['latest_location'] is Map ? (json['latest_location']['latitude'] as num?)?.toDouble() : null);
    final dLng = (json['driver_lng'] as num?)?.toDouble() ??
        (json['latest_location'] is Map ? (json['latest_location']['longitude'] as num?)?.toDouble() : null);
    final dEta = (json['driver_eta_mins'] as num?)?.toDouble();
    final dDist = (json['driver_distance_km'] as num?)?.toDouble();

    final rawChat = json['chat_messages'];
    final List<Map<String, dynamic>> parsedChat = rawChat is List
        ? rawChat.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : const [];

    final statusStr = (json['status'] ?? 'REQUESTED').toString();
    final parsedTotal = (json['total_fare'] as num?)?.toDouble() ??
        (json['estimated_fare'] as num?)?.toDouble() ??
        0.0;
    final rawFinal = (json['final_fare'] as num?)?.toDouble();
    final parsedFinal = statusStr == 'CANCELLED'
        ? rawFinal
        : ((rawFinal != null && rawFinal > 0) ? rawFinal : null);

    return RideModel(
      id: json['name'] ?? json['id'] ?? '',
      riderId: json['rider'] ?? json['rider_id'] ?? '',
      driverId: json['driver'] ?? json['driver_id'],
      driverName: json['driver_name'] ?? driverDetails?.name,
      driverPhone: json['driver_phone'] ?? driverDetails?.phoneNumber,
      vehicle: json['vehicle'] ?? driverDetails?.licensePlate,
      vehicleCategory: json['vehicle_category'] ?? 'ECONOMY',
      status: statusStr,
      pickupAddress: json['pickup_address'] ?? '',
      pickupLat: (json['pickup_lat'] as num?)?.toDouble() ?? 0.0,
      pickupLng: (json['pickup_lng'] as num?)?.toDouble() ?? 0.0,
      destinationAddress: json['destination_address'] ?? '',
      destinationLat: (json['destination_lat'] as num?)?.toDouble() ?? 0.0,
      destinationLng: (json['destination_lng'] as num?)?.toDouble() ?? 0.0,
      totalFare: parsedTotal,
      finalFare: parsedFinal,
      currency: json['currency'] ?? 'NGN',
      startOtp: json['start_otp']?.toString(),
      paymentMethod: json['payment_method'] ?? 'CASH',
      paymentStatus: json['payment_status'] ?? 'PENDING',
      actualDistanceKm: (json['actual_distance_km'] as num?)?.toDouble(),
      actualDurationMins: (json['actual_duration_mins'] as num?)?.toDouble(),
      serviceArea: json['service_area'],
      driverDetails: driverDetails,
      driverLat: dLat,
      driverLng: dLng,
      driverEtaMins: dEta,
      driverDistanceKm: dDist,
      chatMessages: parsedChat,
      createdAt: json['creation'] != null
          ? DateTime.tryParse(json['creation'])
          : (json['timestamp'] != null ? DateTime.tryParse(json['timestamp']) : null),
      offeredFare: (json['offered_fare'] as num?)?.toDouble(),
      agreedFare: (json['agreed_fare'] as num?)?.toDouble(),
      biddingStatus: json['bidding_status']?.toString(),
      surgeMultiplier: (json['surge_multiplier'] as num?)?.toDouble(),
      surgeReason: json['surge_reason']?.toString(),
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
