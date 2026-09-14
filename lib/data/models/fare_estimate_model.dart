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
