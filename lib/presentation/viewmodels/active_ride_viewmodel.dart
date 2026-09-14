import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/services/realtime_service.dart';
import '../../core/state/view_state.dart';
import '../../domain/entities/driver_details.dart';
import '../../domain/entities/driver_location.dart';
import '../../domain/entities/ride.dart';
import '../../domain/repositories/i_ride_repository.dart';

class ActiveRideViewModel extends ChangeNotifier with ViewStateMixin {
  final IRideRepository rideRepo;
  final IRealtimeService? realtimeService;

  ActiveRide? _currentRide;
  DriverLocationEvent? _driverLocation;
  StreamSubscription<ActiveRide>? _rideSub;
  StreamSubscription<DriverLocationEvent>? _locationSub;

  Timer? _searchTimer;
  int _searchSecondsElapsed = 0;

  ActiveRideViewModel({
    required this.rideRepo,
    this.realtimeService,
  }) {
    _subscribeToRealtime();
  }

  ActiveRide? get currentRide => _currentRide;
  DriverLocationEvent? get driverLocation => _driverLocation;
  int get searchSecondsElapsed => _searchSecondsElapsed;

  bool get hasActiveRide => _currentRide != null;
  bool get isSearching => _currentRide?.isSearching ?? false;
  bool get isDriverAssigned => _currentRide?.isDriverAssigned ?? false;
  bool get isDriverArriving =>
      (_currentRide?.isDriverAccepted ?? false) ||
      (_currentRide?.isDriverEnRoute ?? false) ||
      (_currentRide?.isDriverArrived ?? false);
  bool get isInProgress => _currentRide?.isInProgress ?? false;
  bool get isCompleted => _currentRide?.isCompleted ?? false;
  bool get isCancelled => _currentRide?.isCancelled ?? false;

  DriverDetails? get driverDetails => _currentRide?.driverDetails;
  String? get startOtp => _currentRide?.startOtp;

  void _subscribeToRealtime() {
    _rideSub = realtimeService?.rideUpdateStream.listen((ride) {
      if (_currentRide != null && ride.id == _currentRide!.id) {
        setActiveRide(ride);
      }
    });

    _locationSub = realtimeService?.driverLocationStream.listen((loc) {
      if (_currentRide != null && loc.rideId == _currentRide!.id) {
        _driverLocation = loc;
        notifyListeners();
      }
    });
  }

  void setActiveRide(ActiveRide ride) {
    _currentRide = ride;
    realtimeService?.listenToRide(ride.id);

    if (ride.isSearching) {
      _startSearchTimer();
    } else {
      _stopSearchTimer();
    }

    setState(ViewState.success);
    notifyListeners();
  }

  void _startSearchTimer() {
    _searchTimer?.cancel();
    _searchSecondsElapsed = 0;
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _searchSecondsElapsed++;
      notifyListeners();
    });
  }

  void _stopSearchTimer() {
    _searchTimer?.cancel();
    _searchTimer = null;
  }

  Future<void> refreshActiveRide() async {
    if (_currentRide == null) return;
    try {
      final updated = await rideRepo.syncRealtimeState(_currentRide!.id);
      setActiveRide(updated);
    } catch (_) {}
  }

  Future<bool> cancelRide(String reason) async {
    if (_currentRide == null) return false;

    setState(ViewState.loading);
    notifyListeners();

    try {
      final cancelled = await rideRepo.cancelRide(_currentRide!.id, reason: reason);
      setActiveRide(cancelled);
      _stopSearchTimer();
      setState(ViewState.success);
      notifyListeners();
      return true;
    } catch (e) {
      setState(ViewState.error, errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _stopSearchTimer();
    realtimeService?.stopListeningToRide();
    _currentRide = null;
    _driverLocation = null;
    _searchSecondsElapsed = 0;
    setState(ViewState.initial);
    notifyListeners();
  }

  @override
  void dispose() {
    _stopSearchTimer();
    _rideSub?.cancel();
    _locationSub?.cancel();
    super.dispose();
  }
}
