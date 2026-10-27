import '../../domain/entities/fare_estimate.dart';

class FareEstimateModel extends FareEstimate {
  final double distanceFare;
  final double timeFare;
  final double subtotal;

  const FareEstimateModel({
    required super.vehicleCategory,
    required super.categoryName,
    required super.baseFare,
    super.distanceRate = 0.0,
    super.timeRate = 0.0,
    super.minimumFare = 0.0,
    required super.estimatedDurationMins,
    required super.distanceKm,
    required super.totalFare,
    super.serviceArea,
    super.currency = 'NGN',
    super.fuelPricePerLiter = 1050.0,
    super.estimatedFuelCost = 0.0,
    super.totalOperatingCost = 0.0,
    super.surgeMultiplier = 1.0,
    super.surgeReason,
    super.recommendedFare = 0.0,
    super.minOfferedFare = 0.0,
    super.maxOfferedFare = 0.0,
    this.distanceFare = 0.0,
    this.timeFare = 0.0,
    this.subtotal = 0.0,
  });

  factory FareEstimateModel.fromJson(Map<String, dynamic> json) {
    final baseFare = (json['base_fare'] as num?)?.toDouble() ?? 0.0;
    final distFare = (json['distance_fare'] as num?)?.toDouble() ?? 0.0;
    final timeFare = (json['time_fare'] as num?)?.toDouble() ?? 0.0;
    final subtotal = (json['subtotal'] as num?)?.toDouble() ?? (baseFare + distFare + timeFare);
    final totalFare = (json['total_fare'] as num?)?.toDouble() ?? subtotal;
    final fuelPrice = (json['fuel_price_per_liter'] as num?)?.toDouble() ?? 1050.0;
    final fuelCost = (json['estimated_fuel_cost'] as num?)?.toDouble() ?? 0.0;
    final opCost = (json['total_operating_cost'] as num?)?.toDouble() ?? 0.0;
    final surgeMult = (json['surge_multiplier'] as num?)?.toDouble() ?? 1.0;
    final surgeReason = json['surge_reason']?.toString();
    final recFare = (json['recommended_fare'] as num?)?.toDouble() ?? totalFare;
    final minOffered = (json['min_offered_fare'] as num?)?.toDouble() ?? (recFare * 0.70);
    final maxOffered = (json['max_offered_fare'] as num?)?.toDouble() ?? (recFare * 2.0);

    return FareEstimateModel(
      vehicleCategory: json['vehicle_category'] ?? json['category'] ?? 'ECONOMY',
      categoryName: json['category_name'] ?? json['vehicle_category'] ?? 'Economy',
      baseFare: baseFare,
      distanceRate: (json['distance_rate'] as num?)?.toDouble() ?? 0.0,
      timeRate: (json['time_rate'] as num?)?.toDouble() ?? 0.0,
      minimumFare: (json['minimum_fare'] as num?)?.toDouble() ?? 0.0,
      estimatedDurationMins: (json['estimated_duration_mins'] as num?)?.toDouble() ??
          (json['duration_mins'] as num?)?.toDouble() ??
          0.0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ??
          (json['distance'] as num?)?.toDouble() ??
          0.0,
      totalFare: totalFare,
      serviceArea: json['service_area'],
      currency: json['currency'] ?? 'NGN',
      distanceFare: distFare,
      timeFare: timeFare,
      subtotal: subtotal,
      fuelPricePerLiter: fuelPrice,
      estimatedFuelCost: fuelCost,
      totalOperatingCost: opCost,
      surgeMultiplier: surgeMult,
      surgeReason: surgeReason,
      recommendedFare: recFare,
      minOfferedFare: minOffered,
      maxOfferedFare: maxOffered,
    );
  }

  Map<String, dynamic> toJson() => {
        'vehicle_category': vehicleCategory,
        'category_name': categoryName,
        'base_fare': baseFare,
        'distance_fare': distanceFare,
        'time_fare': timeFare,
        'subtotal': subtotal,
        'total_fare': totalFare,
        'currency': currency,
        'distance_km': distanceKm,
        'estimated_duration_mins': estimatedDurationMins,
        'service_area': serviceArea,
      };
}
