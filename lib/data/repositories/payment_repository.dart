import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/i_payment_repository.dart';
import '../models/payment_model.dart';

class PaymentRepository implements IPaymentRepository {
  final IApiClient apiClient;

  PaymentRepository({required this.apiClient});

  @override
  Future<PaymentRecord> getPayment(String rideId) async {
    final res = await apiClient.get(
      ApiEndpoints.getPayment,
      queryParams: {'ride_id': rideId},
    );
    final data = res['data'] ?? res['payment_record'] ?? res;
    return PaymentModel.fromJson(data);
  }

  @override
  Future<PaymentRecord> confirmPayment({
    required String rideId,
    required String paymentMethod,
    String? transactionReference,
  }) async {
    final res = await apiClient.post(
      ApiEndpoints.riderConfirmPayment,
      body: {
        'ride_id': rideId,
        'payment_method': paymentMethod,
        'transaction_reference': ?transactionReference,
      },
    );
    final data = res['data'] ?? res['payment_record'] ?? res;
    return PaymentModel.fromJson(data);
  }

  @override
  Future<PaymentRecord> disputePayment({
    required String rideId,
    required String reason,
  }) async {
    final res = await apiClient.post(
      ApiEndpoints.raiseDispute,
      body: {
        'ride_id': rideId,
        'reason': reason,
      },
    );
    final data = res['data'] ?? res['payment_record'] ?? res;
    return PaymentModel.fromJson(data);
  }
}
