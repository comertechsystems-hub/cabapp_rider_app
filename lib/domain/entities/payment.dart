/// Pure domain entity representing a peer-to-peer Ride Payment Record.
class PaymentRecord {
  final String rideId;
  final String paymentMethod; // CASH, BANK_TRANSFER, POS, OTHER
  final double amount;
  final String status; // PENDING, DRIVER_CONFIRMED, RIDER_CONFIRMED, DISPUTED, RESOLVED
  final String? transactionReference;
  final String? disputeReason;
  final String? resolutionNotes;
  final DateTime? createdAt;

  const PaymentRecord({
    required this.rideId,
    this.paymentMethod = 'CASH',
    required this.amount,
    this.status = 'PENDING',
    this.transactionReference,
    this.disputeReason,
    this.resolutionNotes,
    this.createdAt,
  });

  bool get isPending => status == 'PENDING';
  bool get isDriverConfirmed => status == 'DRIVER_CONFIRMED';
  bool get isRiderConfirmed => status == 'RIDER_CONFIRMED';
  bool get isSettled =>
      status == 'DRIVER_CONFIRMED' || status == 'RIDER_CONFIRMED' || status == 'RESOLVED';
  bool get isDisputed => status == 'DISPUTED';
  bool get isResolved => status == 'RESOLVED';
}
