/// Pure domain entities for support tickets and emergency contacts.
class SupportTicket {
  final String id;
  final String subject;
  final String category; // RIDE_ISSUE, PAYMENT_ISSUE, DRIVER_ISSUE, TECHNICAL_ISSUE, SAFETY_ISSUE
  final String description;
  final String status; // OPEN, IN_PROGRESS, RESOLVED, CLOSED
  final String priority; // LOW, MEDIUM, HIGH, CRITICAL
  final String? rideId;
  final DateTime createdAt;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.category,
    required this.description,
    this.status = 'OPEN',
    this.priority = 'MEDIUM',
    this.rideId,
    required this.createdAt,
  });

  bool get isOpen => status == 'OPEN' || status == 'IN_PROGRESS';
  bool get isResolved => status == 'RESOLVED' || status == 'CLOSED';
}

class EmergencyContact {
  final String id;
  final String contactName;
  final String phone;
  final String relationship;
  final String? email;
  final bool isPrimary;

  const EmergencyContact({
    required this.id,
    required this.contactName,
    required this.phone,
    required this.relationship,
    this.email,
    this.isPrimary = false,
  });
}
