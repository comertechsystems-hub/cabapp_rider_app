class RideModel {
  final String id;
  final String rider;
  final String? driver;
  final String? driverName;
  final String? driverPhone;
  final String? vehicle;
  final String vehicleCategory;
  final String status;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLng;
  final double totalFare;
  final double? finalFare;
  final String currency;
  final String? startOtp;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime? createdAt;

  RideModel({
    required this.id,
    required this.rider,
    this.driver,
    this.driverName,
    this.driverPhone,
    this.vehicle,
    required this.vehicleCategory,
    required this.status,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.totalFare,
    this.finalFare,
    this.currency = 'NGN',
    this.startOtp,
    this.paymentMethod = 'CASH',
    this.paymentStatus = 'PENDING',
    this.createdAt,
  });

  bool get isSearching => status == 'SEARCHING';
  bool get isAssigned => status == 'DRIVER_ASSIGNED';
  bool get isAccepted => status == 'DRIVER_ACCEPTED';
  bool get isEnRoute => status == 'DRIVER_EN_ROUTE';
  bool get isArrived => status == 'DRIVER_ARRIVED';
  bool get isInProgress => status == 'TRIP_STARTED';
  bool get isCompleted => status == 'TRIP_COMPLETED' || status == 'PAYMENT_CONFIRMED';
  bool get isCancelled => status == 'CANCELLED';

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['name'] ?? json['id'] ?? '',
      rider: json['rider'] ?? '',
      driver: json['driver'],
      driverName: json['driver_name'],
      driverPhone: json['driver_phone'],
      vehicle: json['vehicle'],
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
      createdAt: json['creation'] != null ? DateTime.tryParse(json['creation']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': id,
        'rider': rider,
        'driver': driver,
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
      };
}
