import '../entities/rider_profile.dart';

abstract class IAuthRepository {
  bool get isAuthenticated;

  Future<Map<String, dynamic>> requestOtp(
    String phoneNumber, {
    String? email,
    String? fullName,
  });

  Future<RiderProfile> verifyOtp({
    required String phoneNumber,
    required String otp,
    String? firstName,
    String? lastName,
    String? fullName,
    String? email,
  });

  Future<RiderProfile?> getCurrentUser();
  Future<void> logout();
}
