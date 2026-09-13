import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_manager.dart';
import '../models/user_profile_model.dart';

class AuthRepository {
  final ApiClient apiClient;
  final SessionManager sessionManager;

  AuthRepository({
    required this.apiClient,
    required this.sessionManager,
  });

  Future<Map<String, dynamic>> requestOtp(String phone) async {
    final res = await apiClient.post(
      ApiEndpoints.requestOtp,
      body: {'phone': phone, 'role': 'Rider'},
    );
    return res is Map<String, dynamic> ? res : {'success': true};
  }

  Future<UserProfileModel> verifyOtpAndLogin({
    required String phone,
    required String otp,
    String? firstName,
    String? lastName,
  }) async {
    final body = <String, dynamic>{
      'phone': phone,
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
    final riderId = data['domain_profile'] ?? data['rider_id'];

    await sessionManager.saveAuthCredentials(
      apiKey: apiKey,
      apiSecret: apiSecret,
      userEmail: userEmail,
      riderId: riderId,
      phone: phone,
      fullName: '${firstName ?? ''} ${lastName ?? ''}'.trim(),
    );

    return UserProfileModel.fromJson(data);
  }

  Future<UserProfileModel?> getProfile() async {
    if (!sessionManager.isAuthenticated) return null;
    final res = await apiClient.get(ApiEndpoints.getProfile);
    final data = res['data'] ?? res;
    return UserProfileModel.fromJson(data);
  }

  Future<void> logout() async {
    await sessionManager.clear();
  }
}
