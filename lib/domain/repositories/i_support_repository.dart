import '../entities/support.dart';

abstract class ISupportRepository {
  Future<SupportTicket> createTicket({
    required String subject,
    required String category,
    required String description,
    String? rideId,
    String? priority,
  });

  Future<List<SupportTicket>> getTickets();

  Future<EmergencyContact> addEmergencyContact({
    required String contactName,
    required String phone,
    required String relationship,
    String? email,
    bool isPrimary = false,
  });

  Future<List<EmergencyContact>> getEmergencyContacts();

  Future<bool> deleteEmergencyContact(String contactId);

  Future<Map<String, dynamic>> triggerEmergencySos({
    required String rideId,
    double? lat,
    double? lng,
    String? address,
  });
}
