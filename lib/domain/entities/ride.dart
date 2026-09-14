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
  final DateTime? createdAt;

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
    this.createdAt,
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
  bool get isDriverOnTheWay => isDriverAccepted || isDriverEnRoute;
  bool get canCancel => isRequested || isSearching || isDriverAssigned || isDriverAccepted;

  double get displayFare => finalFare ?? totalFare;
}
