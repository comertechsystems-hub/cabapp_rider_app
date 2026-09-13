class UserProfileModel {
  final String email;
  final String phone;
  final String fullName;
  final String? riderId;
  final String status;
  final double rating;
  final int totalRides;

  UserProfileModel({
    required this.email,
    required this.phone,
    required this.fullName,
    this.riderId,
    this.status = 'ACTIVE',
    this.rating = 5.0,
    this.totalRides = 0,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      email: json['email'] ?? json['user'] ?? '',
      phone: json['phone'] ?? json['phone_number'] ?? '',
      fullName: json['full_name'] ?? '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      riderId: json['rider_id'] ?? json['name'],
      status: json['status'] ?? 'ACTIVE',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      totalRides: (json['total_rides'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'phone': phone,
        'full_name': fullName,
        'rider_id': riderId,
        'status': status,
        'rating': rating,
        'total_rides': totalRides,
      };
}
