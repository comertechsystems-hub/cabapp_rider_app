import 'package:flutter/foundation.dart';
import '../../core/state/view_state.dart';
import '../../domain/entities/trip_history.dart';
import '../../domain/repositories/i_ride_repository.dart';

enum HistoryFilter { all, completed, cancelled }

class TripHistoryViewModel extends ChangeNotifier with ViewStateMixin {
  final IRideRepository rideRepo;

  List<TripHistoryItem> _allTrips = [];
  HistoryFilter _currentFilter = HistoryFilter.all;

  TripHistoryViewModel({required this.rideRepo});

  HistoryFilter get currentFilter => _currentFilter;

  List<TripHistoryItem> get filteredTrips {
    switch (_currentFilter) {
      case HistoryFilter.completed:
        return _allTrips.where((t) => t.isCompleted).toList();
      case HistoryFilter.cancelled:
        return _allTrips.where((t) => t.isCancelled).toList();
      case HistoryFilter.all:
        return _allTrips;
    }
  }

  void setFilter(HistoryFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  Future<void> loadTripHistory() async {
    setState(ViewState.loading);
    notifyListeners();

    try {
      _allTrips = await rideRepo.getTripHistory();
      setState(_allTrips.isEmpty ? ViewState.empty : ViewState.success);
      notifyListeners();
    } catch (e) {
      setState(ViewState.error, errorMessage: e.toString());
      notifyListeners();
    }
  }
}
