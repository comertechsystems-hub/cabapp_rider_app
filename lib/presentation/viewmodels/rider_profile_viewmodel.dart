import 'package:flutter/foundation.dart';
import '../../core/state/view_state.dart';
import '../../domain/entities/rider_profile.dart';
import '../../domain/repositories/i_rider_repository.dart';

class RiderProfileViewModel extends ChangeNotifier with ViewStateMixin {
  final IRiderRepository riderRepo;

  RiderProfile? _profile;

  RiderProfileViewModel({required this.riderRepo});

  RiderProfile? get profile => _profile;

  Future<void> loadProfile() async {
    setState(ViewState.loading);
    notifyListeners();

    try {
      _profile = await riderRepo.getProfile();
      setState(_profile == null ? ViewState.empty : ViewState.success);
      notifyListeners();
    } catch (e) {
      setState(ViewState.error, errorMessage: e.toString());
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    setState(ViewState.loading);
    notifyListeners();

    try {
      _profile = await riderRepo.updateProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
      );
      setState(ViewState.success);
      notifyListeners();
      return true;
    } catch (e) {
      setState(ViewState.error, errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }
}
