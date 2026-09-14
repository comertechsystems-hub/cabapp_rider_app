import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/support.dart';
import '../../domain/repositories/i_support_repository.dart';
import '../models/support_model.dart';

class SupportRepository implements ISupportRepository {
  final IApiClient apiClient;

  SupportRepository({required this.apiClient});

  @override
  Future<SupportTicket> createTicket({
    required String subject,
    required String category,
    required String description,
    String? rideId,
    String? priority,
  }) async {
    final res = await apiClient.post(
      ApiEndpoints.createTicket,
      body: {
        'subject': subject,
        'category': category,
        'description': description,
        'ride_id': ?rideId,
        'priority': ?priority,
      },
    );
    final data = res['data'] ?? res['ticket'] ?? res;
    return SupportTicketModel.fromJson(data);
  }

  @override
  Future<List<SupportTicket>> getTickets() async {
    final res = await apiClient.get(ApiEndpoints.getTickets);
    final List<dynamic> list = res is List
        ? res
        : (res['data'] is List ? res['data'] : (res['tickets'] is List ? res['tickets'] : []));
    return list.map((item) => SupportTicketModel.fromJson(item)).toList();
  }

  @override
  Future<EmergencyContact> addEmergencyContact({
    required String contactName,
    required String phone,
    required String relationship,
    String? email,
    bool isPrimary = false,
  }) async {
    final res = await apiClient.post(
      ApiEndpoints.addEmergencyContact,
      body: {
        'contact_name': contactName,
        'phone': phone,
        'relationship': relationship,
        'email': ?email,
        'is_primary': isPrimary ? 1 : 0,
      },
    );
    final data = res['data'] ?? res['contact'] ?? res;
    return EmergencyContactModel.fromJson(data);
  }

  @override
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    final res = await apiClient.get(ApiEndpoints.getMyEmergencyContacts);
    final List<dynamic> list = res is List
        ? res
        : (res['contacts'] is List ? res['contacts'] : (res['data'] is List ? res['data'] : []));
    return list.map((item) => EmergencyContactModel.fromJson(item)).toList();
  }

  @override
  Future<bool> deleteEmergencyContact(String contactId) async {
    final res = await apiClient.post(
      ApiEndpoints.deleteEmergencyContact,
      body: {'contact_id': contactId},
    );
    return res is Map<String, dynamic> ? (res['success'] ?? true) : true;
  }

  @override
  Future<Map<String, dynamic>> triggerEmergencySos({
    required String rideId,
    double? lat,
    double? lng,
    String? address,
  }) async {
    final res = await apiClient.post(
      ApiEndpoints.triggerSos,
      body: {
        'ride_id': rideId,
        'location_lat': ?lat,
        'location_lng': ?lng,
        'address': ?address,
      },
    );
    return res is Map<String, dynamic> ? res : {'success': true};
  }
}
