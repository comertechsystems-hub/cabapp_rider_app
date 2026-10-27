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
  final double fuelPricePerLiter;
  final double estimatedFuelCost;
  final double totalOperatingCost;
  final double surgeMultiplier;
  final String? surgeReason;
  final double recommendedFare;
  final double minOfferedFare;
  final double maxOfferedFare;

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
    this.fuelPricePerLiter = 1400.0,
    this.estimatedFuelCost = 0.0,
    this.totalOperatingCost = 0.0,
    this.surgeMultiplier = 1.0,
    this.surgeReason,
    this.recommendedFare = 0.0,
    this.minOfferedFare = 0.0,
    this.maxOfferedFare = 0.0,
  });
}
