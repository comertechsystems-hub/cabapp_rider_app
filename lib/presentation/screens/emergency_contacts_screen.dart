import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../viewmodels/emergency_contact_viewmodel.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmergencyContactViewModel>().loadContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final contactVm = context.watch<EmergencyContactViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          // Safety Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.coralSoft,
            child: Row(
              children: [
                const Icon(Icons.shield, color: AppColors.coral, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rider Safety & SOS',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.coral, fontSize: 14),
                      ),
                      Text(
                        'Your primary emergency contact will be notified automatically during an active trip emergency.',
                        style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: contactVm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : contactVm.contacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.contact_phone_outlined, size: 60, color: AppColors.inkSoft.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            const Text(
                              'No Emergency Contacts',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Add a family member or trusted friend for safety.',
                              style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: contactVm.contacts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final c = contactVm.contacts[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.paperRaised,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: c.isPrimary ? AppColors.greenSoft : AppColors.paper,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: c.isPrimary ? AppColors.green : AppColors.navy,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            c.contactName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          if (c.isPrimary) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.greenSoft,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'PRIMARY',
                                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.green),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${c.phone} • ${c.relationship}',
                                        style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.coral, size: 20),
                                  onPressed: () => contactVm.deleteContact(c.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Emergency Contact'),
                onPressed: () => _showAddContactDialog(context, contactVm),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog(BuildContext context, EmergencyContactViewModel vm) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+234');
    final relationCtrl = TextEditingController(text: 'Family');
    bool isPrimary = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('New Emergency Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Contact Name')),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
                const SizedBox(height: 10),
                TextField(controller: relationCtrl, decoration: const InputDecoration(labelText: 'Relationship (e.g. Spouse, Parent)')),
                const SizedBox(height: 10),
                CheckboxListTile(
                  title: const Text('Set as Primary Emergency Contact', style: TextStyle(fontSize: 13)),
                  value: isPrimary,
                  onChanged: (val) => setDlgState(() => isPrimary = val ?? false),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                final relation = relationCtrl.text.trim();
                if (name.isNotEmpty && phone.isNotEmpty) {
                  Navigator.pop(ctx);
                  await vm.addContact(
                    contactName: name,
                    phone: phone,
                    relationship: relation,
                    isPrimary: isPrimary,
                  );
                }
              },
              child: const Text('Add Contact'),
            ),
          ],
        ),
      ),
    );
  }
}
