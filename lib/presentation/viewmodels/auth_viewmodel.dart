import 'package:flutter/foundation.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthState { initial, loading, otpSent, authenticated, error }

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;

  AuthState _state = AuthState.initial;
  UserProfileModel? _userProfile;
  String? _errorMessage;
  String? _phoneNumber;

  AuthViewModel(this._authRepo) {
    _checkInitialAuth();
  }

  AuthState get state => _state;
  UserProfileModel? get userProfile => _userProfile;
  String? get errorMessage => _errorMessage;
  String? get phoneNumber => _phoneNumber;
  bool get isAuthenticated => _authRepo.sessionManager.isAuthenticated;

  Future<void> _checkInitialAuth() async {
    if (_authRepo.sessionManager.isAuthenticated) {
      _state = AuthState.loading;
      notifyListeners();
      try {
        _userProfile = await _authRepo.getProfile();
        _state = AuthState.authenticated;
      } catch (e) {
        _state = AuthState.initial;
      }
      notifyListeners();
    }
  }

  Future<bool> requestOtp(String phone) async {
    _state = AuthState.loading;
    _errorMessage = null;
    _phoneNumber = phone;
    notifyListeners();

    try {
      await _authRepo.requestOtp(phone);
      _state = AuthState.otpSent;
      notifyListeners();
      return true;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String otp, {String? firstName, String? lastName}) async {
    if (_phoneNumber == null) return false;
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _userProfile = await _authRepo.verifyOtpAndLogin(
        phone: _phoneNumber!,
        otp: otp,
        firstName: firstName,
        lastName: lastName,
      );
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepo.logout();
    _userProfile = null;
    _phoneNumber = null;
    _state = AuthState.initial;
    notifyListeners();
  }
}
