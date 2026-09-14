import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../viewmodels/rider_profile_viewmodel.dart';
import 'emergency_contacts_screen.dart';
import 'support_screen.dart';

class RiderProfileScreen extends StatefulWidget {
  final RiderProfileViewModel profileVm;

  const RiderProfileScreen({super.key, required this.profileVm});

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  @override
  void initState() {
    super.initState();
    widget.profileVm.loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.profileVm,
      builder: (context, _) {
        final vm = widget.profileVm;
        final profile = vm.profile;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Rider Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            actions: [
              if (profile != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showEditProfileDialog(context, vm),
                ),
            ],
          ),
          body: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : profile == null
                  ? const Center(child: Text('Profile not available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Avatar Card
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: AppColors.navy,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.line, width: 2),
                                  ),
                                  child: const Icon(Icons.person, color: Colors.white, size: 44),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  profile.fullName,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profile.phoneNumber,
                                  style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.goldSoft,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star, color: AppColors.gold, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        profile.rating.toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.goldInk),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '(${profile.totalTrips} trips)',
                                        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Details Box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.paperRaised,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Column(
                              children: [
                                _detailRow(Icons.email_outlined, 'Email', profile.email ?? 'Not set'),
                                const Divider(height: 20, color: AppColors.line),
                                _detailRow(Icons.phone_outlined, 'Phone', profile.phoneNumber),
                                const Divider(height: 20, color: AppColors.line),
                                _detailRow(
                                  Icons.contact_phone_outlined,
                                  'Emergency Contact',
                                  profile.hasEmergencyContact
                                      ? '${profile.emergencyContactName ?? ""} (${profile.emergencyContactPhone})'
                                      : 'No contact set',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Safety & Emergency Contact Button
                          _actionTile(
                            icon: Icons.shield_outlined,
                            iconColor: AppColors.green,
                            title: 'Emergency Contacts & SOS',
                            subtitle: 'Manage trusted contacts and safety alerts',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EmergencyContactsScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          // Help & Support Button
                          _actionTile(
                            icon: Icons.help_outline,
                            iconColor: AppColors.navy,
                            title: 'Help & Support Desk',
                            subtitle: 'Report trip issues or technical problems',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SupportScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.navy, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ],
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, RiderProfileViewModel vm) {
    final firstCtrl = TextEditingController(text: vm.profile?.firstName ?? '');
    final lastCtrl = TextEditingController(text: vm.profile?.lastName ?? '');
    final emailCtrl = TextEditingController(text: vm.profile?.email ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: firstCtrl, decoration: const InputDecoration(labelText: 'First Name')),
            const SizedBox(height: 10),
            TextField(controller: lastCtrl, decoration: const InputDecoration(labelText: 'Last Name')),
            const SizedBox(height: 10),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await vm.updateProfile(
                firstName: firstCtrl.text.trim(),
                lastName: lastCtrl.text.trim(),
                email: emailCtrl.text.trim(),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
