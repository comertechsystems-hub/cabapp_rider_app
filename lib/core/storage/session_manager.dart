import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyApiKey = 'api_key';
  static const String _keyApiSecret = 'api_secret';
  static const String _keyUser = 'user_email';
  static const String _keyRiderId = 'rider_id';
  static const String _keyPhone = 'phone';
  static const String _keyFullName = 'full_name';
  static const String _keyFcmToken = 'fcm_token';

  final SharedPreferences _prefs;

  SessionManager(this._prefs);

  static Future<SessionManager> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SessionManager(prefs);
  }

  bool get isAuthenticated =>
      _prefs.getString(_keyApiKey) != null && _prefs.getString(_keyApiSecret) != null;

  String? get apiKey => _prefs.getString(_keyApiKey);
  String? get apiSecret => _prefs.getString(_keyApiSecret);
  String? get userEmail => _prefs.getString(_keyUser);
  String? get riderId => _prefs.getString(_keyRiderId);
  String? get phone => _prefs.getString(_keyPhone);
  String? get fullName => _prefs.getString(_keyFullName);
  String? get fcmToken => _prefs.getString(_keyFcmToken);

  String? get authHeader {
    if (apiKey != null && apiSecret != null) {
      return 'token $apiKey:$apiSecret';
    }
    return null;
  }

  Future<void> saveAuthCredentials({
    required String apiKey,
    required String apiSecret,
    required String userEmail,
    String? riderId,
    String? phone,
    String? fullName,
  }) async {
    await _prefs.setString(_keyApiKey, apiKey);
    await _prefs.setString(_keyApiSecret, apiSecret);
    await _prefs.setString(_keyUser, userEmail);
    if (riderId != null) await _prefs.setString(_keyRiderId, riderId);
    if (phone != null) await _prefs.setString(_keyPhone, phone);
    if (fullName != null) await _prefs.setString(_keyFullName, fullName);
  }

  Future<void> saveFcmToken(String token) async {
    await _prefs.setString(_keyFcmToken, token);
  }

  Future<void> clear() async {
    await _prefs.clear();
  }
}
