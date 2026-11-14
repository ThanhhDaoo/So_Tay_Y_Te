import 'package:shared_preferences/shared_preferences.dart';

abstract class AppPreferencesDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> saveSession({
    required String userId,
    required String patientCode,
    required String contact,
    required bool rememberMe,
  });
  Future<String?> getSessionUserId();
  Future<String?> getSessionPatientCode();
  Future<bool> getRememberMe();
  Future<void> clearSession();
  Future<void> setProStatus(bool isPro);
  Future<bool> getProStatus();
}

class AppPreferencesDataSourceImpl implements AppPreferencesDataSource {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyPatientCode = 'auth_patient_code';
  static const String _keyContact = 'auth_contact';
  static const String _keyRememberMe = 'auth_remember_me';
  static const String _keyIsPro = 'is_pro_member';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<void> saveToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_keyToken, token);
  }

  @override
  Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString(_keyToken);
  }

  @override
  Future<void> saveSession({
    required String userId,
    required String patientCode,
    required String contact,
    required bool rememberMe,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyPatientCode, patientCode);
    await prefs.setString(_keyContact, contact);
    await prefs.setBool(_keyRememberMe, rememberMe);
  }

  @override
  Future<String?> getSessionUserId() async {
    final prefs = await _prefs;
    return prefs.getString(_keyUserId);
  }

  @override
  Future<String?> getSessionPatientCode() async {
    final prefs = await _prefs;
    return prefs.getString(_keyPatientCode);
  }

  @override
  Future<bool> getRememberMe() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  @override
  Future<void> clearSession() async {
    final prefs = await _prefs;
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyPatientCode);
    await prefs.remove(_keyContact);
    await prefs.remove(_keyRememberMe);
  }

  @override
  Future<void> setProStatus(bool isPro) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyIsPro, isPro);
  }

  @override
  Future<bool> getProStatus() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyIsPro) ?? false;
  }
}
