import 'package:flutter/foundation.dart';
import '../../core/state/view_state.dart';
import '../../domain/entities/support.dart';
import '../../domain/repositories/i_support_repository.dart';

class SupportViewModel extends ChangeNotifier with ViewStateMixin {
  final ISupportRepository supportRepo;

  List<SupportTicket> _tickets = [];
  bool _sosTriggered = false;

  SupportViewModel({required this.supportRepo});

  List<SupportTicket> get tickets => _tickets;
  bool get sosTriggered => _sosTriggered;

  Future<void> loadTickets() async {
    setState(ViewState.loading);
    notifyListeners();

    try {
      _tickets = await supportRepo.getTickets();
      setState(_tickets.isEmpty ? ViewState.empty : ViewState.success);
      notifyListeners();
    } catch (e) {
      setState(ViewState.error, errorMessage: e.toString());
      notifyListeners();
    }
  }

  Future<SupportTicket?> createTicket({
    required String subject,
    required String category,
    required String description,
    String? rideId,
    String? priority,
  }) async {
    setState(ViewState.loading);
    notifyListeners();

    try {
      final ticket = await supportRepo.createTicket(
        subject: subject,
        category: category,
        description: description,
        rideId: rideId,
        priority: priority,
      );
      _tickets.insert(0, ticket);
      setState(ViewState.success);
      notifyListeners();
      return ticket;
    } catch (e) {
      setState(ViewState.error, errorMessage: e.toString());
      notifyListeners();
      return null;
    }
  }

  Future<bool> triggerEmergencySos({
    required String rideId,
    double? lat,
    double? lng,
    String? address,
  }) async {
    try {
      final res = await supportRepo.triggerEmergencySos(
        rideId: rideId,
        lat: lat,
        lng: lng,
        address: address,
      );
      _sosTriggered = true;
      notifyListeners();
      return res['success'] == true || res.containsKey('incident_id');
    } catch (_) {
      return false;
    }
  }
}
