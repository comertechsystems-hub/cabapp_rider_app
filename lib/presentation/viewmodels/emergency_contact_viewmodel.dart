import 'package:flutter/foundation.dart';
import '../../core/state/view_state.dart';
import '../../domain/entities/support.dart';
import '../../domain/repositories/i_support_repository.dart';

class EmergencyContactViewModel extends ChangeNotifier with ViewStateMixin {
  final ISupportRepository supportRepo;

  List<EmergencyContact> _contacts = [];

  EmergencyContactViewModel({required this.supportRepo});

  List<EmergencyContact> get contacts => _contacts;

  Future<void> loadContacts() async {
    setState(ViewState.loading);
    notifyListeners();

    try {
      _contacts = await supportRepo.getEmergencyContacts();
      setState(_contacts.isEmpty ? ViewState.empty : ViewState.success);
      notifyListeners();
    } catch (e) {
      setState(ViewState.error, errorMessage: e.toString());
      notifyListeners();
    }
  }

  Future<bool> addContact({
    required String contactName,
    required String phone,
    required String relationship,
    String? email,
    bool isPrimary = false,
  }) async {
    setState(ViewState.loading);
    notifyListeners();

    try {
      final contact = await supportRepo.addEmergencyContact(
        contactName: contactName,
        phone: phone,
        relationship: relationship,
        email: email,
        isPrimary: isPrimary,
      );
      _contacts.add(contact);
      setState(ViewState.success);
      notifyListeners();
      return true;
    } catch (e) {
      setState(ViewState.error, errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteContact(String contactId) async {
    try {
      final success = await supportRepo.deleteEmergencyContact(contactId);
      if (success) {
        _contacts.removeWhere((c) => c.id == contactId);
        setState(_contacts.isEmpty ? ViewState.empty : ViewState.success);
        notifyListeners();
      }
      return success;
    } catch (e) {
      setState(ViewState.error, errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }
}
