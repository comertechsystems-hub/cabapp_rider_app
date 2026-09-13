import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController(text: '+234');
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final isOtpStep = authVm.state == AuthState.otpSent;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_taxi, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CabApp',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Driver-First Mobility',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Text(
                isOtpStep ? 'Verify Phone' : 'Enter your mobile',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isOtpStep
                    ? 'Enter the 6-digit code sent to ${authVm.phoneNumber}'
                    : 'We will send an SMS code to verify your account.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 32),
              if (!isOtpStep) ...[
                const Text(
                  'PHONE NUMBER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '+2348012345678',
                    prefixIcon: Icon(Icons.phone_outlined, color: AppColors.inkSoft),
                  ),
                ),
              ] else ...[
                const Text(
                  'ONE-TIME PIN (OTP)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    hintText: '123456',
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.inkSoft),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'YOUR NAME (OPTIONAL)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'First and Last Name',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.inkSoft),
                  ),
                ),
              ],
              if (authVm.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  authVm.errorMessage!,
                  style: const TextStyle(color: AppColors.coral, fontSize: 13),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: authVm.state == AuthState.loading
                      ? null
                      : () async {
                          if (!isOtpStep) {
                            final phone = _phoneController.text.trim();
                            if (phone.isNotEmpty) {
                              await authVm.requestOtp(phone);
                            }
                          } else {
                            final otp = _otpController.text.trim();
                            if (otp.isNotEmpty) {
                              final parts = _nameController.text.trim().split(' ');
                              final first = parts.isNotEmpty ? parts.first : null;
                              final last = parts.length > 1 ? parts.sublist(1).join(' ') : null;
                              await authVm.verifyOtp(otp, firstName: first, lastName: last);
                            }
                          }
                        },
                  child: authVm.state == AuthState.loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(isOtpStep ? 'Verify & Continue' : 'Send Code'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
