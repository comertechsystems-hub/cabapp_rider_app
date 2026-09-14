import '../../domain/entities/support.dart';

class SupportTicketModel extends SupportTicket {
  const SupportTicketModel({
    required super.id,
    required super.subject,
    required super.category,
    required super.description,
    super.status = 'OPEN',
    super.priority = 'MEDIUM',
    super.rideId,
    required super.createdAt,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['name'] ?? json['id'] ?? '',
      subject: json['subject'] ?? '',
      category: json['category'] ?? 'RIDE_ISSUE',
      description: json['description'] ?? '',
      status: json['status'] ?? 'OPEN',
      priority: json['priority'] ?? 'MEDIUM',
      rideId: json['ride'] ?? json['ride_id'],
      createdAt: json['creation'] != null
          ? DateTime.tryParse(json['creation']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': id,
        'subject': subject,
        'category': category,
        'description': description,
        'status': status,
        'priority': priority,
        'ride': rideId,
        'creation': createdAt.toIso8601String(),
      };
}

class EmergencyContactModel extends EmergencyContact {
  const EmergencyContactModel({
    required super.id,
    required super.contactName,
    required super.phone,
    required super.relationship,
    super.email,
    super.isPrimary = false,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['name'] ?? json['id'] ?? '',
      contactName: json['contact_name'] ?? json['name'] ?? '',
      phone: json['phone'] ?? json['phone_number'] ?? '',
      relationship: json['relationship'] ?? 'Family',
      email: json['email'],
      isPrimary: json['is_primary'] == 1 || json['is_primary'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'contact_name': contactName,
        'phone': phone,
        'relationship': relationship,
        'email': email,
        'is_primary': isPrimary ? 1 : 0,
      };
}
