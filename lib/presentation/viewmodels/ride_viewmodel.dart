import 'package:flutter/foundation.dart';
import '../../data/models/fare_estimate_model.dart';
import '../../data/models/ride_model.dart';
import '../../data/repositories/ride_repository.dart';

enum RideBookingState { idle, estimating, estimatesReady, requesting, activeRide, completed, error }

class RideViewModel extends ChangeNotifier {
  final RideRepository _rideRepo;

  RideBookingState _state = RideBookingState.idle;
  List<FareEstimateModel> _fareEstimates = [];
  FareEstimateModel? _selectedCategory;
  RideModel? _currentRide;
  String? _errorMessage;

  String? _pickupAddress;
  double? _pickupLat;
  double? _pickupLng;
  String? _destAddress;
  double? _destLat;
  double? _destLng;

  RideViewModel(this._rideRepo);

  RideBookingState get state => _state;
  List<FareEstimateModel> get fareEstimates => _fareEstimates;
  FareEstimateModel? get selectedCategory => _selectedCategory;
  RideModel? get currentRide => _currentRide;
  String? get errorMessage => _errorMessage;

  String? get pickupAddress => _pickupAddress;
  String? get destAddress => _destAddress;

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

    _state = RideBookingState.estimating;
    _errorMessage = null;
    notifyListeners();

    try {
      _fareEstimates = await _rideRepo.getFareEstimates(
        pickupLat: _pickupLat!,
        pickupLng: _pickupLng!,
        destinationLat: _destLat!,
        destinationLng: _destLng!,
      );
      if (_fareEstimates.isNotEmpty) {
        _selectedCategory = _fareEstimates.first;
      }
      _state = RideBookingState.estimatesReady;
      notifyListeners();
      return true;
    } catch (e) {
      _state = RideBookingState.error;
      _errorMessage = e.toString();
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

    _state = RideBookingState.requesting;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentRide = await _rideRepo.requestRide(
        pickupAddress: _pickupAddress!,
        pickupLat: _pickupLat!,
        pickupLng: _pickupLng!,
        destinationAddress: _destAddress!,
        destinationLat: _destLat!,
        destinationLng: _destLng!,
        vehicleCategory: _selectedCategory!.vehicleCategory,
        autoSearch: true,
      );
      _state = RideBookingState.activeRide;
      notifyListeners();
      return true;
    } catch (e) {
      _state = RideBookingState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshActiveRide() async {
    if (_currentRide == null) return;
    try {
      _currentRide = await _rideRepo.syncRealtimeState(_currentRide!.id);
      if (_currentRide!.isCompleted) {
        _state = RideBookingState.completed;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> cancelRide(String reason) async {
    if (_currentRide == null) return false;
    try {
      _currentRide = await _rideRepo.cancelRide(_currentRide!.id, reason: reason);
      _state = RideBookingState.idle;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmPayment() async {
    if (_currentRide == null) return false;
    try {
      _currentRide = await _rideRepo.confirmPayment(_currentRide!.id);
      _state = RideBookingState.completed;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _state = RideBookingState.idle;
    _fareEstimates = [];
    _selectedCategory = null;
    _currentRide = null;
    _errorMessage = null;
    notifyListeners();
  }
}
