class ApiEndpoints {
  static const String defaultBaseUrl = 'http://127.0.0.1:8000';

  // Auth Endpoints
  static const String requestOtp = '/api/method/mobility.api.auth.request_otp';
  static const String verifyOtp = '/api/method/mobility.api.auth.verify_otp';

  // Rider Profile
  static const String getProfile = '/api/method/mobility.api.rider.get_profile';
  static const String updateProfile = '/api/method/mobility.api.rider.update_profile';

  // Pricing
  static const String estimateFare = '/api/method/mobility.api.pricing.estimate_fare';
  static const String getFareEstimatesAll = '/api/method/mobility.api.pricing.get_fare_estimates_all_categories';

  // Ride Lifecycle
  static const String requestRide = '/api/method/mobility.api.ride.request_ride';
  static const String getRide = '/api/method/mobility.api.ride.get_ride';
  static const String cancelRide = '/api/method/mobility.api.ride.cancel_ride';
  static const String confirmPayment = '/api/method/mobility.api.ride.confirm_payment';
  static const String disputeRide = '/api/method/mobility.api.ride.dispute_ride';
  static const String syncRealtimeState = '/api/method/mobility.api.ride.sync_realtime_state';

  // Device & Notifications
  static const String registerDevice = '/api/method/mobility.api.notification.register_device';
  static const String unregisterDevice = '/api/method/mobility.api.notification.unregister_device';
}
