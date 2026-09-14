import 'package:flutter/foundation.dart';
import '../../core/state/view_state.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/i_payment_repository.dart';

class PaymentStatusViewModel extends ChangeNotifier with ViewStateMixin {
  final IPaymentRepository paymentRepo;

  PaymentRecord? _paymentRecord;
  String _selectedMethod = 'CASH';
  String? _transactionReference;

  PaymentStatusViewModel({required this.paymentRepo});

  PaymentRecord? get paymentRecord => _paymentRecord;
  String get selectedMethod => _selectedMethod;
  String? get transactionReference => _transactionReference;

  void setPaymentMethod(String method) {
    _selectedMethod = method;
    notifyListeners();
  }

  void setTransactionReference(String? ref) {
    _transactionReference = ref;
    notifyListeners();
  }

  Future<void> fetchPayment(String rideId) async {
    setState(ViewState.loading);
    notifyListeners();

    try {
      _paymentRecord = await paymentRepo.getPayment(rideId);
      setState(ViewState.success);
      notifyListeners();
    } catch (e) {
      setState(ViewState.error, errorMessage: e.toString());
      notifyListeners();
    }
  }

  Future<bool> confirmPaymentPaid(String rideId) async {
    setState(ViewState.loading);
    notifyListeners();

    try {
      _paymentRecord = await paymentRepo.confirmPayment(
        rideId: rideId,
        paymentMethod: _selectedMethod,
        transactionReference: _transactionReference,
      );
      setState(ViewState.success);
      notifyListeners();
      return true;
    } catch (e) {
      setState(ViewState.error, errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> raiseDispute(String rideId, String reason) async {
    setState(ViewState.loading);
    notifyListeners();

    try {
      _paymentRecord = await paymentRepo.disputePayment(
        rideId: rideId,
        reason: reason,
      );
      setState(ViewState.success);
      notifyListeners();
      return true;
    } catch (e) {
      setState(ViewState.error, errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }
}
