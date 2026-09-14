import 'package:flutter/foundation.dart';
import '../../core/state/view_state.dart';
import '../../domain/entities/fare_estimate.dart';
import '../../domain/entities/ride.dart';
import '../../domain/repositories/i_ride_repository.dart';

class RideBookingViewModel extends ChangeNotifier with ViewStateMixin {
  final IRideRepository rideRepo;

  String? _pickupAddress;
  double? _pickupLat;
  double? _pickupLng;

  String? _destinationAddress;
  double? _destinationLat;
  double? _destinationLng;

  List<FareEstimate> _fareEstimates = [];
  FareEstimate? _selectedCategory;
  ActiveRide? _bookedRide;

  RideBookingViewModel({required this.rideRepo});

  String? get pickupAddress => _pickupAddress;
  double? get pickupLat => _pickupLat;
  double? get pickupLng => _pickupLng;

  String? get destinationAddress => _destinationAddress;
  double? get destinationLat => _destinationLat;
  double? get destinationLng => _destinationLng;

  List<FareEstimate> get fareEstimates => _fareEstimates;
  FareEstimate? get selectedCategory => _selectedCategory;
  ActiveRide? get bookedRide => _bookedRide;

  bool get hasValidRoute =>
      _pickupLat != null &&
      _pickupLng != null &&
      _destinationLat != null &&
      _destinationLng != null;

  void setPickup(String address, double lat, double lng) {
    _pickupAddress = address;
    _pickupLat = lat;
    _pickupLng = lng;
    notifyListeners();
  }

  void setDestination(String address, double lat, double lng) {
    _destinationAddress = address;
    _destinationLat = lat;
    _destinationLng = lng;
    notifyListeners();
  }

  void selectCategory(FareEstimate category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<bool> fetchFareEstimates() async {
    if (!hasValidRoute) return false;

    setState(ViewState.loading);
    notifyListeners();

    try {
      _fareEstimates = await rideRepo.getFareEstimates(
        pickupLat: _pickupLat!,
        pickupLng: _pickupLng!,
        destLat: _destinationLat!,
        destLng: _destinationLng!,
      );

      if (_fareEstimates.isNotEmpty) {
        _selectedCategory ??= _fareEstimates.first;
        setState(ViewState.success);
      } else {
        setState(ViewState.empty);
      }
      notifyListeners();
      return true;
    } catch (e) {
      setState(ViewState.error, errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<ActiveRide?> bookRide() async {
    if (!hasValidRoute || _selectedCategory == null) return null;

    setState(ViewState.loading);
    notifyListeners();

    try {
      final ride = await rideRepo.requestRide(
        pickupAddress: _pickupAddress!,
        pickupLat: _pickupLat!,
        pickupLng: _pickupLng!,
        destinationAddress: _destinationAddress!,
        destLat: _destinationLat!,
        destLng: _destinationLng!,
        vehicleCategory: _selectedCategory!.vehicleCategory,
        distanceKm: _selectedCategory!.distanceKm,
        estimatedDurationMins: _selectedCategory!.estimatedDurationMins,
        autoSearch: true,
      );

      _bookedRide = ride;
      setState(ViewState.success);
      notifyListeners();
      return ride;
    } catch (e) {
      setState(ViewState.error, errorMessage: e.toString());
      notifyListeners();
      return null;
    }
  }

  void reset() {
    _pickupAddress = null;
    _pickupLat = null;
    _pickupLng = null;
    _destinationAddress = null;
    _destinationLat = null;
    _destinationLng = null;
    _fareEstimates = [];
    _selectedCategory = null;
    _bookedRide = null;
    setState(ViewState.initial);
    notifyListeners();
  }
}
