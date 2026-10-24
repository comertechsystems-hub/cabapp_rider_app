import 'package:flutter/foundation.dart';
import '../../core/state/view_state.dart';
import '../../domain/entities/rider_profile.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../data/models/user_profile_model.dart';

enum AuthState { initial, loading, otpSent, authenticated, error }

class AuthViewModel extends ChangeNotifier with ViewStateMixin {
  final IAuthRepository authRepo;

  AuthState _state = AuthState.initial;
  RiderProfile? _profile;
  String? _phoneNumber;
  String? _email;
  String? _fullName;
  bool _emailNotified = false;

  AuthViewModel(this.authRepo) {
    _checkInitialAuth();
  }

  AuthState get authState => _state;
  bool get isOtpSent => _state == AuthState.otpSent;

  RiderProfile? get profile => _profile;
  UserProfileModel? get userProfile => _profile != null
      ? UserProfileModel(
          email: _profile!.user,
          phone: _profile!.phoneNumber,
          fullName: _profile!.fullName,
          riderId: _profile!.id,
          status: _profile!.status,
          rating: _profile!.rating,
          totalRides: _profile!.totalTrips,
        )
      : null;

  String? get phoneNumber => _phoneNumber;
  String? get email => _email;
  String? get fullName => _fullName;
  bool get emailNotified => _emailNotified;

  /// Permanent login: True as long as credentials exist in local session storage
  bool get isAuthenticated => authRepo.isAuthenticated;

  Future<void> _checkInitialAuth() async {
    if (!authRepo.isAuthenticated) {
      _state = AuthState.initial;
      setState(ViewState.initial);
      notifyListeners();
      return;
    }

    _state = AuthState.authenticated;
    setState(ViewState.success);
    notifyListeners();

    try {
      final user = await authRepo.getCurrentUser();
      if (user != null) {
        _profile = user;
        notifyListeners();
      }
    } catch (_) {
      // Kept authenticated from local session even when offline
    }
  }

  /// Request OTP for simple phone sign-in
  Future<bool> requestOtp(String phone) async {
    return requestSignInOtp(phone);
  }

  /// Sign In with phone number
  Future<bool> requestSignInOtp(String phone) async {
    _state = AuthState.loading;
    setState(ViewState.loading);
    _phoneNumber = phone;
    _email = null;
    _fullName = null;
    _emailNotified = false;
    notifyListeners();

    try {
      final res = await authRepo.requestOtp(phone);
      _emailNotified = res['email_notified'] == true;
      _email = res['email']?.toString();
      _state = AuthState.otpSent;
      setState(ViewState.success);
      notifyListeners();
      return true;
    } catch (e) {
      _state = AuthState.error;
      setState(ViewState.error, errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Sign Up with Full Name, Phone (+234), and Email (Dual OTP dispatch)
  Future<bool> requestSignUpOtp({
    required String fullName,
    required String phone,
    required String email,
  }) async {
    _state = AuthState.loading;
    setState(ViewState.loading);
    _phoneNumber = phone;
    _email = email.trim();
    _fullName = fullName.trim();
    _emailNotified = true;
    notifyListeners();

    try {
      final res = await authRepo.requestOtp(
        phone,
        email: email.trim(),
        fullName: fullName.trim(),
      );
      _emailNotified = res['email_notified'] == true || _email != null;
      _state = AuthState.otpSent;
      setState(ViewState.success);
      notifyListeners();
      return true;
    } catch (e) {
      _state = AuthState.error;
      setState(ViewState.error, errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Verify 6-digit OTP code confirming both phone and email
  Future<bool> verifyOtp(
    String otp, {
    String? firstName,
    String? lastName,
  }) async {
    if (_phoneNumber == null) return false;
    _state = AuthState.loading;
    setState(ViewState.loading);
    notifyListeners();

    try {
      _profile = await authRepo.verifyOtp(
        phoneNumber: _phoneNumber!,
        otp: otp,
        firstName: firstName,
        lastName: lastName,
        fullName: _fullName,
        email: _email,
      );
      _state = AuthState.authenticated;
      setState(ViewState.success);
      notifyListeners();
      return true;
    } catch (e) {
      _state = AuthState.error;
      setState(ViewState.error, errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }

  // Backward compatibility method
  Future<bool> verifyOtpAndLogin({
    required String phone,
    required String otp,
    String? firstName,
    String? lastName,
  }) async {
    _phoneNumber = phone;
    return verifyOtp(otp, firstName: firstName, lastName: lastName);
  }

  Future<void> logout() async {
    await authRepo.logout();
    _profile = null;
    _phoneNumber = null;
    _email = null;
    _fullName = null;
    _state = AuthState.initial;
    setState(ViewState.initial);
    notifyListeners();
  }
}
