import '../../domain/entities/payment.dart';

class PaymentModel extends PaymentRecord {
  const PaymentModel({
    required super.rideId,
    super.paymentMethod = 'CASH',
    required super.amount,
    super.status = 'PENDING',
    super.transactionReference,
    super.disputeReason,
    super.resolutionNotes,
    super.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      rideId: json['ride'] ?? json['ride_id'] ?? '',
      paymentMethod: json['payment_method'] ?? 'CASH',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'PENDING',
      transactionReference: json['transaction_reference'] ?? json['payment_reference'],
      disputeReason: json['dispute_reason'],
      resolutionNotes: json['resolution_notes'],
      createdAt: json['creation'] != null ? DateTime.tryParse(json['creation']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'ride_id': rideId,
        'payment_method': paymentMethod,
        'amount': amount,
        'status': status,
        'transaction_reference': transactionReference,
        'dispute_reason': disputeReason,
        'resolution_notes': resolutionNotes,
        'creation': createdAt?.toIso8601String(),
      };
}
