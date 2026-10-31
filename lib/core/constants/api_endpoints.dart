class ApiEndpoints {
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://cabapp.com.ng',
  );

  // Auth Endpoints
  static const String requestOtp = '/api/method/mobility.api.auth.request_otp';
  static const String verifyOtp = '/api/method/mobility.api.auth.verify_otp';
  static const String checkSession = '/api/method/mobility.api.auth.check_session';
  static const String logout = '/api/method/mobility.api.auth.logout';

  // Rider Profile
  static const String getProfile = '/api/method/mobility.api.rider.get_profile';
  static const String updateProfile = '/api/method/mobility.api.rider.update_profile';
  static const String deleteAccount = '/api/method/mobility.api.rider.delete_account';
  static const String getRiderTripHistory = '/api/method/mobility.api.rider.get_trip_history';

  // Pricing & Estimates
  static const String estimateFare = '/api/method/mobility.api.pricing.estimate_fare';
  static const String getFareEstimatesAll = '/api/method/mobility.api.pricing.get_fare_estimates_all_categories';

  // Ride Lifecycle
  static const String getAvailableDrivers = '/api/method/mobility.api.driver.get_available_drivers';
  static const String requestRide = '/api/method/mobility.api.ride.request_ride';
  static const String searchDrivers = '/api/method/mobility.api.ride.search_drivers';
  static const String getRide = '/api/method/mobility.api.ride.get_ride';
  static const String getMyActiveRide = '/api/method/mobility.api.ride.get_my_active_ride';
  static const String cancelRide = '/api/method/mobility.api.ride.cancel_ride';
  static const String updateRideOffer = '/api/method/mobility.api.ride.update_ride_offer';
  static const String getRideDriverOffers = '/api/method/mobility.api.ride.get_ride_driver_offers';
  static const String riderAcceptCounterOffer = '/api/method/mobility.api.ride.rider_accept_counter_offer';
  static const String riderDeclineCounterOffer = '/api/method/mobility.api.ride.rider_decline_counter_offer';
  static const String confirmPayment = '/api/method/mobility.api.ride.confirm_payment';
  static const String disputeRide = '/api/method/mobility.api.ride.dispute_ride';
  static const String syncRealtimeState = '/api/method/mobility.api.ride.sync_realtime_state';
  static const String getRideLocationEvents = '/api/method/mobility.api.ride.get_ride_location_events';
  static const String getRideStatusLogs = '/api/method/mobility.api.ride.get_ride_status_logs';
  static const String sendRideMessage = '/api/method/mobility.api.ride.send_ride_message';
  static const String getRideMessages = '/api/method/mobility.api.ride.get_ride_messages';
  static const String initiateInAppCall = '/api/method/mobility.api.ride.initiate_in_app_call';
  static const String answerInAppCall = '/api/method/mobility.api.ride.answer_in_app_call';
  static const String endInAppCall = '/api/method/mobility.api.ride.end_in_app_call';
  static const String getCallStatus = '/api/method/mobility.api.ride.get_call_status';

  // Payment Recording & Confirmation
  static const String createPayment = '/api/method/mobility.api.payment.create_payment';
  static const String riderConfirmPayment = '/api/method/mobility.api.payment.rider_confirm';
  static const String getPayment = '/api/method/mobility.api.payment.get_payment';
  static const String raiseDispute = '/api/method/mobility.api.payment.raise_dispute';

  // Ratings & Reviews
  static const String submitRating = '/api/method/mobility.api.rating.submit_ride_rating';
  static const String getUserRatings = '/api/method/mobility.api.rating.get_user_ratings';
  static const String getRideRatings = '/api/method/mobility.api.rating.get_ride_ratings';

  // Support & Safety
  static const String createTicket = '/api/method/mobility.api.support.create_ticket';
  static const String getTickets = '/api/method/mobility.api.support.get_tickets';
  static const String triggerSos = '/api/method/mobility.api.support.trigger_sos';

  // Emergency Contacts
  static const String addEmergencyContact = '/api/method/mobility.api.support.add_emergency_contact_endpoint';
  static const String getMyEmergencyContacts = '/api/method/mobility.api.support.get_my_emergency_contacts';
  static const String deleteEmergencyContact = '/api/method/mobility.api.support.delete_emergency_contact_endpoint';

  // Device & Notifications
  static const String registerDevice = '/api/method/mobility.api.notification.register_device';
  static const String unregisterDevice = '/api/method/mobility.api.notification.unregister_device';
}
