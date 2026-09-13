class FareEstimateModel {
  final String vehicleCategory;
  final String categoryName;
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double subtotal;
  final double totalFare;
  final String currency;
  final double distanceKm;
  final double estimatedDurationMins;

  FareEstimateModel({
    required this.vehicleCategory,
    required this.categoryName,
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.subtotal,
    required this.totalFare,
    this.currency = 'NGN',
    required this.distanceKm,
    required this.estimatedDurationMins,
  });

  factory FareEstimateModel.fromJson(Map<String, dynamic> json) {
    return FareEstimateModel(
      vehicleCategory: json['vehicle_category'] ?? json['category'] ?? 'ECONOMY',
      categoryName: json['category_name'] ?? json['vehicle_category'] ?? 'Economy',
      baseFare: (json['base_fare'] as num?)?.toDouble() ?? 0.0,
      distanceFare: (json['distance_fare'] as num?)?.toDouble() ?? 0.0,
      timeFare: (json['time_fare'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      totalFare: (json['total_fare'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'NGN',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      estimatedDurationMins: (json['estimated_duration_mins'] as num?)?.toDouble() ?? 0.0,
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
      };
}
