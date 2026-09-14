/// Pure domain entity representing a registered Rider profile.
class RiderProfile {
  final String id;
  final String user;
  final String phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? email;
  final double rating;
  final int totalTrips;
  final String status;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? suspensionReason;

  const RiderProfile({
    required this.id,
    required this.user,
    required this.phoneNumber,
    this.firstName,
    this.lastName,
    this.email,
    this.rating = 5.0,
    this.totalTrips = 0,
    this.status = 'ACTIVE',
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.suspensionReason,
  });

  String get fullName {
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty);
    return parts.isEmpty ? 'Rider' : parts.join(' ');
  }

  bool get isActive => status == 'ACTIVE';
  bool get isSuspended => status == 'SUSPENDED';
  bool get hasEmergencyContact =>
      emergencyContactPhone != null && emergencyContactPhone!.isNotEmpty;
}
