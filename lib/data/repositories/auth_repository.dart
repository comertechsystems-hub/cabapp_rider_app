import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_manager.dart';
import '../../domain/entities/rider_profile.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../models/rider_profile_model.dart';
import '../models/user_profile_model.dart';

class AuthRepository implements IAuthRepository {
  final IApiClient apiClient;
  final SessionManager sessionManager;

  AuthRepository({
    required this.apiClient,
    required this.sessionManager,
  });

  @override
  Future<Map<String, dynamic>> requestOtp(String phoneNumber) async {
    final res = await apiClient.post(
      ApiEndpoints.requestOtp,
      body: {'phone': phoneNumber, 'role': 'Rider'},
    );
    return res is Map<String, dynamic> ? res : {'success': true};
  }

  @override
  Future<RiderProfile> verifyOtp({
    required String phoneNumber,
    required String otp,
    String? firstName,
    String? lastName,
  }) async {
    final body = <String, dynamic>{
      'phone': phoneNumber,
      'otp': otp,
      'role': 'Rider',
    };
    if (firstName != null) body['first_name'] = firstName;
    if (lastName != null) body['last_name'] = lastName;

    final res = await apiClient.post(ApiEndpoints.verifyOtp, body: body);
    final data = res['data'] ?? res;

    final apiKey = data['api_key'] ?? '';
    final apiSecret = data['api_secret'] ?? '';
    final userEmail = data['user'] ?? '';
    final riderId = data['domain_profile'] ?? data['rider_id'] ?? data['name'] ?? '';

    await sessionManager.saveAuthCredentials(
      apiKey: apiKey,
      apiSecret: apiSecret,
      userEmail: userEmail,
      riderId: riderId,
      phone: phoneNumber,
      fullName: '${firstName ?? ''} ${lastName ?? ''}'.trim(),
    );

    return RiderProfileModel.fromJson(data);
  }

  // Backward compatibility alias
  Future<UserProfileModel> verifyOtpAndLogin({
    required String phone,
    required String otp,
    String? firstName,
    String? lastName,
  }) async {
    final profile = await verifyOtp(
      phoneNumber: phone,
      otp: otp,
      firstName: firstName,
      lastName: lastName,
    );
    return UserProfileModel(
      email: profile.user,
      phone: profile.phoneNumber,
      fullName: profile.fullName,
      riderId: profile.id,
      status: profile.status,
      rating: profile.rating,
      totalRides: profile.totalTrips,
    );
  }

  @override
  Future<RiderProfile?> getCurrentUser() async {
    if (!sessionManager.isAuthenticated) return null;
    try {
      final res = await apiClient.get(ApiEndpoints.getProfile);
      final data = res['data'] ?? res['profile'] ?? res;
      return RiderProfileModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  // Backward compatibility alias
  Future<UserProfileModel?> getProfile() async {
    final user = await getCurrentUser();
    if (user == null) return null;
    return UserProfileModel(
      email: user.user,
      phone: user.phoneNumber,
      fullName: user.fullName,
      riderId: user.id,
      status: user.status,
      rating: user.rating,
      totalRides: user.totalTrips,
    );
  }

  @override
  Future<void> logout() async {
    await sessionManager.clearSession();
  }
}
