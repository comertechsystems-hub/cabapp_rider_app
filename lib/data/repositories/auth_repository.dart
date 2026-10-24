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
  bool get isAuthenticated => sessionManager.isAuthenticated;

  @override
  Future<Map<String, dynamic>> requestOtp(
    String phoneNumber, {
    String? email,
    String? fullName,
  }) async {
    final body = <String, dynamic>{
      'phone': phoneNumber,
      'role': 'Rider',
      'device_id': sessionManager.deviceId,
    };
    if (email != null && email.trim().isNotEmpty) {
      body['email'] = email.trim();
    }
    if (fullName != null && fullName.trim().isNotEmpty) {
      body['full_name'] = fullName.trim();
    }

    final res = await apiClient.post(
      ApiEndpoints.requestOtp,
      body: body,
    );
    return res is Map<String, dynamic> ? res : {'success': true};
  }

  @override
  Future<RiderProfile> verifyOtp({
    required String phoneNumber,
    required String otp,
    String? firstName,
    String? lastName,
    String? fullName,
    String? email,
  }) async {
    final body = <String, dynamic>{
      'phone': phoneNumber,
      'otp': otp,
      'role': 'Rider',
      'device_id': sessionManager.deviceId,
    };
    if (firstName != null && firstName.trim().isNotEmpty) {
      body['first_name'] = firstName.trim();
    }
    if (lastName != null && lastName.trim().isNotEmpty) {
      body['last_name'] = lastName.trim();
    }
    if (fullName != null && fullName.trim().isNotEmpty) {
      body['full_name'] = fullName.trim();
    }
    if (email != null && email.trim().isNotEmpty) {
      body['email'] = email.trim();
    }

    final res = await apiClient.post(ApiEndpoints.verifyOtp, body: body);
    final data = res['data'] ?? res;

    final apiKey = data['api_key'] ?? '';
    final apiSecret = data['api_secret'] ?? '';
    final String userEmail = data['user'] is Map
        ? (data['user']['email']?.toString() ?? '')
        : (data['user']?.toString() ?? email ?? '');
    final Map<String, dynamic> profileData = data['profile'] is Map
        ? Map<String, dynamic>.from(data['profile'] as Map)
        : (data is Map<String, dynamic> ? data : <String, dynamic>{});
    final riderId = profileData['name'] ?? profileData['id'] ?? data['domain_profile'] ?? data['rider_id'] ?? '';

    final resolvedName = fullName?.trim() ??
        '${profileData['first_name'] ?? firstName ?? ''} ${profileData['last_name'] ?? lastName ?? ''}'.trim();

    await sessionManager.saveAuthCredentials(
      apiKey: apiKey,
      apiSecret: apiSecret,
      userEmail: userEmail,
      riderId: riderId,
      phone: phoneNumber,
      fullName: resolvedName.isNotEmpty ? resolvedName : 'Rider',
    );

    return RiderProfileModel.fromJson(profileData);
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
    try {
      await apiClient.post(ApiEndpoints.logout);
    } catch (_) {}
    await sessionManager.clearSession();
  }
}
