import 'dart:async';
import '../../domain/entities/driver_location.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/ride.dart';
import '../../data/models/ride_model.dart';
import '../../data/models/driver_location_model.dart';
import '../../data/models/payment_model.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';

/// Abstract contract for real-time rider messaging and telemetry updates
abstract class IRealtimeService {
  Stream<ActiveRide> get rideUpdateStream;
  Stream<DriverLocationEvent> get driverLocationStream;
  Stream<PaymentRecord> get paymentUpdateStream;
  Stream<bool> get connectionStream;
  bool get isConnected;

  void connect();
  void disconnect();
  void listenToRide(String rideId);
  void stopListeningToRide();
}

/// In-memory mock realtime service for unit tests and offline testing
class MockRealtimeService implements IRealtimeService {
  final _rideUpdateController = StreamController<ActiveRide>.broadcast();
  final _driverLocationController = StreamController<DriverLocationEvent>.broadcast();
  final _paymentUpdateController = StreamController<PaymentRecord>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  bool _connected = false;
  String? activeListeningRideId;

  @override
  Stream<ActiveRide> get rideUpdateStream => _rideUpdateController.stream;

  @override
  Stream<DriverLocationEvent> get driverLocationStream =>
      _driverLocationController.stream;

  @override
  Stream<PaymentRecord> get paymentUpdateStream => _paymentUpdateController.stream;

  @override
  Stream<bool> get connectionStream => _connectionController.stream;

  @override
  bool get isConnected => _connected;

  @override
  void connect() {
    _connected = true;
    _connectionController.add(true);
  }

  @override
  void disconnect() {
    _connected = false;
    _connectionController.add(false);
  }

  @override
  void listenToRide(String rideId) {
    activeListeningRideId = rideId;
  }

  @override
  void stopListeningToRide() {
    activeListeningRideId = null;
  }

  void pushRideUpdate(ActiveRide ride) {
    _rideUpdateController.add(ride);
  }

  void pushDriverLocation(DriverLocationEvent event) {
    _driverLocationController.add(event);
  }

  void pushPaymentUpdate(PaymentRecord payment) {
    _paymentUpdateController.add(payment);
  }

  void dispose() {
    _rideUpdateController.close();
    _driverLocationController.close();
    _paymentUpdateController.close();
    _connectionController.close();
  }
}

/// Polling fallback realtime service querying syncRealtimeState periodically
class PollingRealtimeService implements IRealtimeService {
  final IApiClient apiClient;
  final Duration interval;

  final _rideUpdateController = StreamController<ActiveRide>.broadcast();
  final _driverLocationController = StreamController<DriverLocationEvent>.broadcast();
  final _paymentUpdateController = StreamController<PaymentRecord>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Timer? _pollingTimer;
  String? _listeningRideId;
  bool _connected = false;

  PollingRealtimeService({
    required this.apiClient,
    this.interval = const Duration(seconds: 4),
  });

  @override
  Stream<ActiveRide> get rideUpdateStream => _rideUpdateController.stream;

  @override
  Stream<DriverLocationEvent> get driverLocationStream =>
      _driverLocationController.stream;

  @override
  Stream<PaymentRecord> get paymentUpdateStream => _paymentUpdateController.stream;

  @override
  Stream<bool> get connectionStream => _connectionController.stream;

  @override
  bool get isConnected => _connected;

  @override
  void connect() {
    _connected = true;
    _connectionController.add(true);
    _startPolling();
  }

  @override
  void disconnect() {
    _connected = false;
    _connectionController.add(false);
    _stopPolling();
  }

  @override
  void listenToRide(String rideId) {
    _listeningRideId = rideId;
    if (_connected) {
      _pollAuthoritativeState();
    }
  }

  @override
  void stopListeningToRide() {
    _listeningRideId = null;
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) => _pollAuthoritativeState());
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _pollAuthoritativeState() async {
    final rideId = _listeningRideId;
    if (rideId == null) return;

    try {
      final res = await apiClient.post(
        ApiEndpoints.syncRealtimeState,
        body: {'ride_id': rideId},
      );

      final data = res is Map<String, dynamic> ? res : <String, dynamic>{};
      if (data.containsKey('ride')) {
        final ride = RideModel.fromJson(data['ride']);
        _rideUpdateController.add(ride);
      }

      if (data.containsKey('driver_location') && data['driver_location'] != null) {
        final loc = DriverLocationModel.fromJson(data['driver_location']);
        _driverLocationController.add(loc);
      }

      if (data.containsKey('payment_record') && data['payment_record'] != null) {
        final payment = PaymentModel.fromJson(data['payment_record']);
        _paymentUpdateController.add(payment);
      }
    } catch (_) {
      // Periodic poll fails gracefully
    }
  }

  void dispose() {
    _stopPolling();
    _rideUpdateController.close();
    _driverLocationController.close();
    _paymentUpdateController.close();
    _connectionController.close();
  }
}
