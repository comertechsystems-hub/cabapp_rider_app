import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../viewmodels/active_ride_viewmodel.dart';
import '../viewmodels/payment_status_viewmodel.dart';
import '../viewmodels/ride_viewmodel.dart';

/// 15. Payment Screen (Direct P2P Settlement)
class PaymentScreen extends StatefulWidget {
  final String? rideId;
  final double? amount;

  const PaymentScreen({
    super.key,
    this.rideId,
    this.amount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _refController = TextEditingController();
  final _disputeReasonController = TextEditingController();
  bool _showDisputeForm = false;

  @override
  void dispose() {
    _refController.dispose();
    _disputeReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeVm = context.watch<ActiveRideViewModel>();
    final legacyVm = context.watch<RideViewModel>();
    final paymentVm = context.watch<PaymentStatusViewModel>();

    final ride = activeVm.currentRide ?? legacyVm.currentRide;
    final effectiveRideId = widget.rideId ?? ride?.id ?? '';
    final effectiveAmount = widget.amount ?? ride?.displayFare ?? 0.0;
    final driverName = ride?.driverDetails?.name ?? 'Driver';

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Payment Due', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Settlement Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.greenSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.payments_outlined, color: AppColors.green, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Direct Driver Settlement',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.ink),
                      ),
                      Text(
                        '100% P2P payment directly to your driver',
                        style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Total Fare Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    const Text(
                      'TOTAL FARE DUE',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₦${effectiveAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: AppColors.navy),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pay to driver: $driverName',
                      style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (!_showDisputeForm) ...[
                // Payment Method Selector
                const Text(
                  'SELECT PAYMENT METHOD USED',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: ['CASH', 'BANK_TRANSFER', 'POS', 'OTHER'].map((method) {
                    final isSelected = paymentVm.selectedMethod == method;
                    return ChoiceChip(
                      label: Text(
                        method.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.ink,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.navy,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (_) => paymentVm.setPaymentMethod(method),
                    );
                  }).toList(),
                ),

                // Bank Transfer Reference Input
                if (paymentVm.selectedMethod == 'BANK_TRANSFER') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _refController,
                    decoration: InputDecoration(
                      labelText: 'Bank Transfer Reference (Optional)',
                      hintText: 'e.g. 100234987',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (val) => paymentVm.setTransactionReference(val),
                  ),
                ],
                const SizedBox(height: 28),

                // Confirm Payment Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: paymentVm.isLoading
                        ? null
                        : () async {
                            final nav = Navigator.of(context);
                            final success = await paymentVm.confirmPaymentPaid(effectiveRideId);
                            if (!mounted) return;
                            if (success) {
                              nav.pushReplacementNamed(
                                AppRoutes.rating,
                                arguments: {
                                  'rideId': effectiveRideId,
                                  'driverName': driverName,
                                },
                              );
                            }
                          },
                    child: paymentVm.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Confirm Payment Made', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 14),

                // Dispute Trigger
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _showDisputeForm = true),
                    child: const Text('Having issues? Raise a payment dispute', style: TextStyle(color: AppColors.coral, fontSize: 13)),
                  ),
                ),
              ] else ...[
                // Payment Dispute Form
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.report_problem_outlined, color: AppColors.coral, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Raise Payment Dispute',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.coral),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Describe the payment issue encountered (e.g. incorrect amount, transfer declined, POS malfunction).',
                        style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _disputeReasonController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Enter dispute details...',
                          filled: true,
                          fillColor: AppColors.paper,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() => _showDisputeForm = false),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.coral,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: paymentVm.isLoading
                                  ? null
                                  : () async {
                                      final reason = _disputeReasonController.text.trim();
                                      if (reason.isNotEmpty) {
                                        final nav = Navigator.of(context);
                                        final success = await paymentVm.raiseDispute(effectiveRideId, reason);
                                        if (!mounted) return;
                                        if (success) {
                                          nav.pushReplacementNamed(
                                            AppRoutes.rating,
                                            arguments: {
                                              'rideId': effectiveRideId,
                                              'driverName': driverName,
                                            },
                                          );
                                        }
                                      }
                                    },
                              child: const Text('Submit Dispute'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
