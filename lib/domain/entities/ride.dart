import 'driver_details.dart';

/// Pure domain entity representing an active or completed Ride.
class ActiveRide {
  final String id;
  final String status;
  final String riderId;
  final String? driverId;
  final DriverDetails? driverDetails;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLng;
  final String vehicleCategory;
  final String? serviceArea;
  final double totalFare;
  final double? finalFare;
  final String? startOtp;
  final double? actualDistanceKm;
  final double? actualDurationMins;
  final String? paymentMethod;
  final String? paymentStatus;
  final double? driverLat;
  final double? driverLng;
  final double? driverEtaMins;
  final double? driverDistanceKm;
  final List<Map<String, dynamic>> chatMessages;
  final DateTime? createdAt;
  final double? offeredFare;
  final double? agreedFare;
  final String? biddingStatus;
  final double? surgeMultiplier;
  final String? surgeReason;

  const ActiveRide({
    required this.id,
    required this.status,
    required this.riderId,
    this.driverId,
    this.driverDetails,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.vehicleCategory,
    this.serviceArea,
    required this.totalFare,
    this.finalFare,
    this.startOtp,
    this.actualDistanceKm,
    this.actualDurationMins,
    this.paymentMethod,
    this.paymentStatus,
    this.driverLat,
    this.driverLng,
    this.driverEtaMins,
    this.driverDistanceKm,
    this.chatMessages = const [],
    this.createdAt,
    this.offeredFare,
    this.agreedFare,
    this.biddingStatus,
    this.surgeMultiplier,
    this.surgeReason,
  });

  bool get isRequested => status == 'REQUESTED';
  bool get isSearching => status == 'SEARCHING';
  bool get isDriverAssigned => status == 'DRIVER_ASSIGNED';
  bool get isDriverAccepted => status == 'DRIVER_ACCEPTED';
  bool get isDriverEnRoute => status == 'DRIVER_EN_ROUTE';
  bool get isDriverArrived => status == 'DRIVER_ARRIVED';
  bool get isTripStarted => status == 'TRIP_STARTED';
  bool get isInProgress => isTripStarted;
  bool get isCompleted =>
      status == 'TRIP_COMPLETED' ||
      status == 'PAYMENT_PENDING' ||
      status == 'PAYMENT_CONFIRMED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isDisputed => status == 'DISPUTED';
  bool get isPaymentPending => status == 'PAYMENT_PENDING';
  bool get isPaymentConfirmed => status == 'PAYMENT_CONFIRMED';

  bool get hasDriver => driverId != null || driverDetails != null;
  String? get driverName => driverDetails?.name;
  bool get isDriverOnTheWay => isDriverAccepted || isDriverEnRoute;
  bool get canCancel => isRequested || isSearching || isDriverAssigned || isDriverAccepted;

  double get displayFare => isCancelled
      ? (finalFare ?? 0.0)
      : ((finalFare != null && finalFare! > 0)
          ? finalFare!
          : (totalFare > 0 ? totalFare : 1500.0));
}
