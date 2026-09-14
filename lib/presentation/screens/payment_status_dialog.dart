import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../viewmodels/payment_status_viewmodel.dart';

class PaymentStatusDialog extends StatefulWidget {
  final String rideId;
  final double amount;
  final PaymentStatusViewModel paymentVm;
  final VoidCallback onConfirmed;

  const PaymentStatusDialog({
    super.key,
    required this.rideId,
    required this.amount,
    required this.paymentVm,
    required this.onConfirmed,
  });

  @override
  State<PaymentStatusDialog> createState() => _PaymentStatusDialogState();
}

class _PaymentStatusDialogState extends State<PaymentStatusDialog> {
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
    return AnimatedBuilder(
      animation: widget.paymentVm,
      builder: (context, _) {
        final vm = widget.paymentVm;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.greenSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.payments, color: AppColors.green, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Direct Payment',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            '100% P2P settlement to driver',
                            style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.line),
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'AMOUNT DUE',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.inkSoft),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₦${widget.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.navy),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_showDisputeForm) ...[
                    const Text(
                      'PAYMENT METHOD USED',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['CASH', 'BANK_TRANSFER', 'POS', 'OTHER'].map((method) {
                        final isSelected = vm.selectedMethod == method;
                        return ChoiceChip(
                          label: Text(method.replaceAll('_', ' '), style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.ink)),
                          selected: isSelected,
                          selectedColor: AppColors.navy,
                          backgroundColor: AppColors.paper,
                          onSelected: (_) => vm.setPaymentMethod(method),
                        );
                      }).toList(),
                    ),
                    if (vm.selectedMethod == 'BANK_TRANSFER') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _refController,
                        decoration: InputDecoration(
                          hintText: 'Bank transfer reference (optional)',
                          hintStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (val) => vm.setTransactionReference(val),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                        onPressed: vm.isLoading
                            ? null
                            : () async {
                                final success = await vm.confirmPaymentPaid(widget.rideId);
                                if (success && context.mounted) {
                                  Navigator.pop(context);
                                  widget.onConfirmed();
                                }
                              },
                        child: vm.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Confirm Payment Made'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() => _showDisputeForm = true);
                        },
                        child: const Text('Dispute Payment', style: TextStyle(color: AppColors.coral, fontSize: 13)),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'RAISE PAYMENT DISPUTE',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.coral),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _disputeReasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Explain the issue with this payment...',
                        hintStyle: const TextStyle(fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => setState(() => _showDisputeForm = false),
                            child: const Text('Cancel'),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
                            onPressed: vm.isLoading
                                ? null
                                : () async {
                                    final reason = _disputeReasonController.text.trim();
                                    if (reason.isNotEmpty) {
                                      final success = await vm.raiseDispute(widget.rideId, reason);
                                      if (success && context.mounted) {
                                        Navigator.pop(context);
                                        widget.onConfirmed();
                                      }
                                    }
                                  },
                            child: const Text('Submit Dispute'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
