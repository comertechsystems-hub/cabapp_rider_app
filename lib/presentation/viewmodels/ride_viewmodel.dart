import 'package:flutter/foundation.dart';
import '../../core/state/view_state.dart';
import '../../domain/repositories/i_ride_repository.dart';
import '../../data/models/fare_estimate_model.dart';
import '../../data/models/ride_model.dart';

enum RideBookingState {
  idle,
  estimating,
  estimatesReady,
  requesting,
  activeRide,
  completed,
  error,
}

class RideViewModel extends ChangeNotifier with ViewStateMixin {
  final IRideRepository _rideRepo;

  RideBookingState _bookingState = RideBookingState.idle;
  List<FareEstimateModel> _fareEstimates = [];
  FareEstimateModel? _selectedCategory;
  RideModel? _currentRide;

  String? _pickupAddress;
  double? _pickupLat;
  double? _pickupLng;
  String? _destAddress;
  double? _destLat;
  double? _destLng;

  RideViewModel(this._rideRepo);

  RideBookingState get bookingState => _bookingState;
  bool get isEstimating => _bookingState == RideBookingState.estimating;
  bool get isRequesting => _bookingState == RideBookingState.requesting;
  bool get hasActiveRide => _bookingState == RideBookingState.activeRide;
  bool get isCompletedRide => _bookingState == RideBookingState.completed;

  List<FareEstimateModel> get fareEstimates => _fareEstimates;
  FareEstimateModel? get selectedCategory => _selectedCategory;
  RideModel? get currentRide => _currentRide;

  String? get pickupAddress => _pickupAddress;
  String? get destAddress => _destAddress;
  double? get pickupLat => _pickupLat;
  double? get pickupLng => _pickupLng;
  double? get destLat => _destLat;
  double? get destLng => _destLng;

  void setPickup(String address, double lat, double lng) {
    _pickupAddress = address;
    _pickupLat = lat;
    _pickupLng = lng;
    notifyListeners();
  }

  void setDestination(String address, double lat, double lng) {
    _destAddress = address;
    _destLat = lat;
    _destLng = lng;
    notifyListeners();
  }

  void selectCategory(FareEstimateModel category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<bool> fetchFareEstimates() async {
    if (_pickupLat == null || _pickupLng == null || _destLat == null || _destLng == null) {
      return false;
    }

    _bookingState = RideBookingState.estimating;
    setState(ViewState.loading);
    notifyListeners();

    try {
      final estimates = await _rideRepo.getFareEstimates(
        pickupLat: _pickupLat!,
        pickupLng: _pickupLng!,
        destLat: _destLat!,
        destLng: _destLng!,
      );
      _fareEstimates = estimates.map((e) {
        if (e is FareEstimateModel) return e;
        return FareEstimateModel(
          vehicleCategory: e.vehicleCategory,
          categoryName: e.categoryName,
          baseFare: e.baseFare,
          distanceRate: e.distanceRate,
          timeRate: e.timeRate,
          minimumFare: e.minimumFare,
          estimatedDurationMins: e.estimatedDurationMins,
          distanceKm: e.distanceKm,
          totalFare: e.totalFare,
          serviceArea: e.serviceArea,
          currency: e.currency,
        );
      }).toList();

      if (_fareEstimates.isNotEmpty) {
        _selectedCategory = _fareEstimates.first;
      }
      _bookingState = RideBookingState.estimatesReady;
      setState(ViewState.success);
      notifyListeners();
      return true;
    } catch (e) {
      _bookingState = RideBookingState.error;
      setState(ViewState.error, errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> bookRide() async {
    if (_pickupAddress == null ||
        _pickupLat == null ||
        _pickupLng == null ||
        _destAddress == null ||
        _destLat == null ||
        _destLng == null ||
        _selectedCategory == null) {
      return false;
    }

    _bookingState = RideBookingState.requesting;
    setState(ViewState.loading);
    notifyListeners();

    try {
      final ride = await _rideRepo.requestRide(
        pickupAddress: _pickupAddress!,
        pickupLat: _pickupLat!,
        pickupLng: _pickupLng!,
        destinationAddress: _destAddress!,
        destLat: _destLat!,
        destLng: _destLng!,
        vehicleCategory: _selectedCategory!.vehicleCategory,
        autoSearch: true,
      );

      _currentRide = ride is RideModel
          ? ride
          : RideModel(
              id: ride.id,
              riderId: ride.riderId,
              status: ride.status,
              pickupAddress: ride.pickupAddress,
              pickupLat: ride.pickupLat,
              pickupLng: ride.pickupLng,
              destinationAddress: ride.destinationAddress,
              destinationLat: ride.destinationLat,
              destinationLng: ride.destinationLng,
              vehicleCategory: ride.vehicleCategory,
              totalFare: ride.totalFare,
              startOtp: ride.startOtp,
            );

      _bookingState = RideBookingState.activeRide;
      setState(ViewState.success);
      notifyListeners();
      return true;
    } catch (e) {
      _bookingState = RideBookingState.error;
      setState(ViewState.error, errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshActiveRide() async {
    if (_currentRide == null) return;
    try {
      final updated = await _rideRepo.syncRealtimeState(_currentRide!.id);
      _currentRide = updated is RideModel
          ? updated
          : RideModel(
              id: updated.id,
              riderId: updated.riderId,
              status: updated.status,
              pickupAddress: updated.pickupAddress,
              pickupLat: updated.pickupLat,
              pickupLng: updated.pickupLng,
              destinationAddress: updated.destinationAddress,
              destinationLat: updated.destinationLat,
              destinationLng: updated.destinationLng,
              vehicleCategory: updated.vehicleCategory,
              totalFare: updated.totalFare,
              finalFare: updated.finalFare,
              startOtp: updated.startOtp,
              driverName: updated.driverDetails?.name,
              driverPhone: updated.driverDetails?.phoneNumber,
              vehicle: updated.driverDetails?.licensePlate,
            );

      if (_currentRide!.isCompleted) {
        _bookingState = RideBookingState.completed;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> cancelRide(String reason) async {
    if (_currentRide == null) return false;
    try {
      final cancelled = await _rideRepo.cancelRide(_currentRide!.id, reason: reason);
      _currentRide = cancelled is RideModel ? cancelled : null;
      _bookingState = RideBookingState.idle;
      setState(ViewState.initial);
      notifyListeners();
      return true;
    } catch (e) {
      setState(ViewState.error, errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmPayment() async {
    if (_currentRide == null) return false;
    try {
      _bookingState = RideBookingState.completed;
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
    _bookingState = RideBookingState.idle;
    _fareEstimates = [];
    _selectedCategory = null;
    _currentRide = null;
    setState(ViewState.initial);
    notifyListeners();
  }
}
