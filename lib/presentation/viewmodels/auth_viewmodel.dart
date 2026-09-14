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
  bool get isAuthenticated => _profile != null;

  Future<void> _checkInitialAuth() async {
    try {
      final user = await authRepo.getCurrentUser();
      if (user != null) {
        _profile = user;
        _state = AuthState.authenticated;
        setState(ViewState.success);
        notifyListeners();
      }
    } catch (_) {
      _state = AuthState.initial;
      setState(ViewState.initial);
      notifyListeners();
    }
  }

  Future<bool> requestOtp(String phone) async {
    _state = AuthState.loading;
    setState(ViewState.loading);
    _phoneNumber = phone;
    notifyListeners();

    try {
      await authRepo.requestOtp(phone);
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
    _state = AuthState.initial;
    setState(ViewState.initial);
    notifyListeners();
  }
}
