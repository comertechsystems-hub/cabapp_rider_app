/// Pure domain entity representing a historical trip item.
class TripHistoryItem {
  final String rideId;
  final String status;
  final String pickupAddress;
  final String destinationAddress;
  final double fare;
  final String? driverName;
  final String? vehicleModel;
  final String vehicleCategory;
  final DateTime createdAt;

  const TripHistoryItem({
    required this.rideId,
    required this.status,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.fare,
    this.driverName,
    this.vehicleModel,
    required this.vehicleCategory,
    required this.createdAt,
  });

  bool get isCompleted =>
      status == 'TRIP_COMPLETED' ||
      status == 'PAYMENT_PENDING' ||
      status == 'PAYMENT_CONFIRMED';
  bool get isCancelled => status == 'CANCELLED' || status.startsWith('CANCELLED');
}
