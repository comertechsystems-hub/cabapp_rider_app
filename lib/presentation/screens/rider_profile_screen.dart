import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../viewmodels/auth_viewmodel.dart';
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
                          const SizedBox(height: 12),
                          // Privacy Policy & Terms (App Store Compliance)
                          _actionTile(
                            icon: Icons.policy_outlined,
                            iconColor: AppColors.navy,
                            title: 'Privacy Policy & Terms',
                            subtitle: 'Read our data privacy policy & NDPR terms',
                            onTap: () async {
                              final uri = Uri.parse('https://cabapp.com.ng/privacy');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          // Delete Account (Apple App Store & Play Store Compliance)
                          _actionTile(
                            icon: Icons.delete_forever_outlined,
                            iconColor: AppColors.coral,
                            title: 'Delete Account',
                            subtitle: 'Permanently remove your account and personal data',
                            onTap: () => _showDeleteAccountDialog(context, vm),
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

  void _showDeleteAccountDialog(BuildContext context, RiderProfileViewModel vm) {
    final reasonCtrl = TextEditingController();
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: AppColors.coral, size: 28),
                SizedBox(width: 8),
                Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.ink)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Are you sure you want to delete your CabApp account? This action is permanent and cannot be undone.',
                  style: TextStyle(fontSize: 13, color: AppColors.ink),
                ),
                const SizedBox(height: 10),
                const Text(
                  '• Your profile data will be permanently anonymized.\n• All device tokens and session credentials will be revoked.\n• You will be immediately signed out.',
                  style: TextStyle(fontSize: 12, color: AppColors.inkSoft, height: 1.4),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: reasonCtrl,
                  decoration: InputDecoration(
                    labelText: 'Reason for leaving (Optional)',
                    labelStyle: const TextStyle(fontSize: 13),
                    hintText: 'e.g., No longer need service',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.inkSoft)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() => isDeleting = true);
                        final success = await vm.deleteAccount(reason: reasonCtrl.text.trim());
                        if (!context.mounted) return;
                        Navigator.pop(ctx);
                        if (success) {
                          // Logout and navigate to login screen
                          final authVm = context.read<AuthViewModel>();
                          await authVm.logout();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.coral,
                              content: Text(vm.errorMessage ?? 'Failed to delete account. Active rides must be completed first.'),
                            ),
                          );
                        }
                      },
                child: isDeleting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Delete Permanently'),
              ),
            ],
          );
        },
      ),
    );
  }
}
