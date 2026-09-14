import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../viewmodels/support_viewmodel.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'RIDE_ISSUE';

  static const List<Map<String, String>> categories = [
    {'id': 'RIDE_ISSUE', 'label': 'Ride Issue'},
    {'id': 'PAYMENT_ISSUE', 'label': 'Payment & Fare Issue'},
    {'id': 'DRIVER_ISSUE', 'label': 'Driver Conduct'},
    {'id': 'TECHNICAL_ISSUE', 'label': 'Technical / App Issue'},
    {'id': 'SAFETY_ISSUE', 'label': 'Safety & Security Concern'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportViewModel>().loadTickets();
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supportVm = context.watch<SupportViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support & Safety', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 24/7 Safety Hotline Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.support_agent, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '24/7 Safety & Dispatch Desk',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Toll-free emergency line: 0800-CABAPP-SOS',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // New Ticket Header
            const Text(
              'Submit a Support Request',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.paperRaised,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.inkSoft)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    items: categories
                        .map((c) => DropdownMenuItem(value: c['id'], child: Text(c['label']!)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  ),
                  const SizedBox(height: 14),
                  const Text('SUBJECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.inkSoft)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      hintText: 'Brief summary of the issue',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.inkSoft)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Provide detailed information to help our support team assist you...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: supportVm.isLoading
                          ? null
                          : () async {
                              final sub = _subjectController.text.trim();
                              final desc = _descriptionController.text.trim();
                              if (sub.isNotEmpty && desc.isNotEmpty) {
                                final res = await supportVm.createTicket(
                                  subject: sub,
                                  category: _selectedCategory,
                                  description: desc,
                                );
                                if (res != null && context.mounted) {
                                  _subjectController.clear();
                                  _descriptionController.clear();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Ticket created: ${res.id}')),
                                  );
                                }
                              }
                            },
                      child: supportVm.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Submit Ticket'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Existing Tickets
            const Text(
              'Your Recent Tickets',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            const SizedBox(height: 12),
            if (supportVm.tickets.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.paperRaised,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: const Center(
                  child: Text('No support tickets filed yet.', style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                ),
              )
            else
              ...supportVm.tickets.map((t) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.paperRaised,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: t.isOpen ? AppColors.navySoft.withValues(alpha: 0.1) : AppColors.greenSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            t.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: t.isOpen ? AppColors.navy : AppColors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(t.category.replaceAll('_', ' '), style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
