import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/rider_profile.dart';
import '../../domain/repositories/i_rider_repository.dart';
import '../models/rider_profile_model.dart';

class RiderRepository implements IRiderRepository {
  final IApiClient apiClient;

  RiderRepository({required this.apiClient});

  @override
  Future<RiderProfile> getProfile() async {
    final res = await apiClient.get(ApiEndpoints.getProfile);
    final data = res['data'] ?? res['profile'] ?? res;
    return RiderProfileModel.fromJson(data);
  }

  @override
  Future<RiderProfile> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    final res = await apiClient.post(
      ApiEndpoints.updateProfile,
      body: {
        'first_name': ?firstName,
        'last_name': ?lastName,
        'email': ?email,
        'emergency_contact_name': ?emergencyContactName,
        'emergency_contact_phone': ?emergencyContactPhone,
      },
    );
    final data = res['data'] ?? res['profile'] ?? res;
    return RiderProfileModel.fromJson(data);
  }
}
