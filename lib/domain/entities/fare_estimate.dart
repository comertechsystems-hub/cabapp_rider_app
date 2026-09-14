/// Pure domain entity representing upfront fare estimation for a vehicle category.
class FareEstimate {
  final String vehicleCategory;
  final String categoryName;
  final double baseFare;
  final double distanceRate;
  final double timeRate;
  final double minimumFare;
  final double estimatedDurationMins;
  final double distanceKm;
  final double totalFare;
  final String? serviceArea;
  final String currency;

  const FareEstimate({
    required this.vehicleCategory,
    required this.categoryName,
    required this.baseFare,
    required this.distanceRate,
    required this.timeRate,
    required this.minimumFare,
    required this.estimatedDurationMins,
    required this.distanceKm,
    required this.totalFare,
    this.serviceArea,
    this.currency = 'NGN',
  });
}
