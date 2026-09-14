import '../entities/rider_profile.dart';

abstract class IAuthRepository {
  Future<Map<String, dynamic>> requestOtp(String phoneNumber);
  Future<RiderProfile> verifyOtp({required String phoneNumber, required String otp});
  Future<RiderProfile?> getCurrentUser();
  Future<void> logout();
}
