import '../entities/payment.dart';

abstract class IPaymentRepository {
  Future<PaymentRecord> getPayment(String rideId);
  Future<PaymentRecord> confirmPayment({
    required String rideId,
    required String paymentMethod,
    String? transactionReference,
  });
  Future<PaymentRecord> disputePayment({
    required String rideId,
    required String reason,
  });
}
