import '../../domain/entities/rider_profile.dart';

class RiderProfileModel extends RiderProfile {
  const RiderProfileModel({
    required super.id,
    required super.user,
    required super.phoneNumber,
    super.firstName,
    super.lastName,
    super.email,
    super.rating = 5.0,
    super.totalTrips = 0,
    super.status = 'ACTIVE',
    super.emergencyContactName,
    super.emergencyContactPhone,
    super.suspensionReason,
  });

  factory RiderProfileModel.fromJson(Map<String, dynamic> json) {
    return RiderProfileModel(
      id: json['name'] ?? json['id'] ?? json['rider_id'] ?? '',
      user: json['user'] ?? json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phone'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      totalTrips: (json['total_trips'] as num?)?.toInt() ?? (json['total_rides'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? 'ACTIVE',
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactPhone: json['emergency_contact_phone'],
      suspensionReason: json['suspension_reason'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': id,
        'user': user,
        'phone_number': phoneNumber,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'rating': rating,
        'total_trips': totalTrips,
        'status': status,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'suspension_reason': suspensionReason,
      };
}
