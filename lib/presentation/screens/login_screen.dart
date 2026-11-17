import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Rider Access Screen: Sign In & Sign Up with Dual Phone/Email Verification
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignUp = false;

  final _signInPhoneController = TextEditingController(text: '+234');
  final _signUpNameController = TextEditingController();
  final _signUpPhoneController = TextEditingController(text: '+234');
  final _signUpEmailController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _signInPhoneController.dispose();
    _signUpNameController.dispose();
    _signUpPhoneController.dispose();
    _signUpEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleAction() async {
    if (!_formKey.currentState!.validate()) return;
    final authVm = context.read<AuthViewModel>();

    if (_isSignUp) {
      final name = _signUpNameController.text.trim();
      final phone = _signUpPhoneController.text.trim();
      final email = _signUpEmailController.text.trim();

      final success = await authVm.requestSignUpOtp(
        fullName: name,
        phone: phone,
        email: email,
      );
      if (success && mounted) {
        Navigator.pushNamed(context, AppRoutes.otp, arguments: phone);
      }
    } else {
      final phone = _signInPhoneController.text.trim();
      final success = await authVm.requestSignInOtp(phone);
      if (success && mounted) {
        Navigator.pushNamed(context, AppRoutes.otp, arguments: phone);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Brand Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset('assets/images/icon.png', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CabApp',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'Your Daily Ride • Nigeria',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Tab Switcher: Sign In vs Sign Up
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.line.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_isSignUp) setState(() => _isSignUp = false);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isSignUp ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: !_isSignUp
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: !_isSignUp ? AppColors.navy : AppColors.inkSoft,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!_isSignUp) setState(() => _isSignUp = true);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isSignUp ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _isSignUp
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Create Account',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _isSignUp ? AppColors.navy : AppColors.inkSoft,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                Text(
                  _isSignUp ? 'Create your account' : 'Welcome back',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isSignUp
                      ? 'Enter your name, phone number, and email. We will verify both with a single code.'
                      : 'Enter your phone number to receive your 6-digit verification code.',
                  style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.4),
                ),
                const SizedBox(height: 26),

                // Form Fields
                if (_isSignUp) ...[
                  _buildLabel('FULL NAME'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _signUpNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _buildInputDecoration(
                      hint: 'e.g. Amina Bello',
                      icon: Icons.person_outline,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length < 2) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  _buildLabel('PHONE NUMBER'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _signUpPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _buildInputDecoration(
                      hint: '+234 801 234 5678',
                      icon: Icons.phone_iphone,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length < 8) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  _buildLabel('EMAIL ADDRESS'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _signUpEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _buildInputDecoration(
                      hint: 'e.g. amina@example.com',
                      icon: Icons.mail_outline,
                    ),
                    validator: (val) {
                      if (val == null || !val.contains('@') || !val.contains('.')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  _buildLabel('PHONE NUMBER'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _signInPhoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink),
                    decoration: _buildInputDecoration(
                      hint: '+234 801 234 5678',
                      icon: Icons.phone_iphone,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length < 8) {
                        return 'Please enter your registered phone number';
                      }
                      return null;
                    },
                  ),
                ],

                if (authVm.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.coralSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      authVm.errorMessage!,
                      style: const TextStyle(color: AppColors.coral, fontSize: 13),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: authVm.isLoading ? null : _handleAction,
                    child: authVm.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _isSignUp ? 'Create Account & Send Code' : 'Continue',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Single-session security: One device active at a time.\nPermanently logged in until you log out.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.inkSoft, height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        color: AppColors.inkSoft,
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: AppColors.navy),
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.navy, width: 2),
      ),
    );
  }
}
