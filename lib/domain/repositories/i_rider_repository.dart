import '../entities/rider_profile.dart';

abstract class IRiderRepository {
  Future<RiderProfile> getProfile();
  Future<RiderProfile> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? emergencyContactName,
    String? emergencyContactPhone,
  });
}
