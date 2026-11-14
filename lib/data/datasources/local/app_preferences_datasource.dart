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
  Future<void> setBiometricLockEnabled(bool enabled);
  Future<bool> isBiometricLockEnabled();
  Future<void> savePin({required String pinHash, required String salt});
  Future<String?> getPinHash();
  Future<String?> getPinSalt();
  Future<bool> hasPin();
  Future<void> clearPin();
  Future<void> setAutoLockTimeout(int minutes);
  Future<int> getAutoLockTimeout();
  Future<void> setPrivacyScreenEnabled(bool enabled);
  Future<bool> isPrivacyScreenEnabled();
}

class AppPreferencesDataSourceImpl implements AppPreferencesDataSource {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyPatientCode = 'auth_patient_code';
  static const String _keyContact = 'auth_contact';
  static const String _keyRememberMe = 'auth_remember_me';
  static const String _keyIsPro = 'is_pro_member';
  static const String _keyBiometricEnabled = 'security_biometric_enabled';
  static const String _keyPinHash = 'security_pin_hash';
  static const String _keyPinSalt = 'security_pin_salt';
  static const String _keyAutoLockTimeout = 'security_auto_lock_timeout';
  static const String _keyPrivacyScreen = 'security_privacy_screen';

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

  @override
  Future<void> setBiometricLockEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyBiometricEnabled, enabled);
  }

  @override
  Future<bool> isBiometricLockEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  @override
  Future<void> savePin({required String pinHash, required String salt}) async {
    final prefs = await _prefs;
    await prefs.setString(_keyPinHash, pinHash);
    await prefs.setString(_keyPinSalt, salt);
  }

  @override
  Future<String?> getPinHash() async {
    final prefs = await _prefs;
    return prefs.getString(_keyPinHash);
  }

  @override
  Future<String?> getPinSalt() async {
    final prefs = await _prefs;
    return prefs.getString(_keyPinSalt);
  }

  @override
  Future<bool> hasPin() async {
    final prefs = await _prefs;
    return prefs.containsKey(_keyPinHash) && prefs.getString(_keyPinHash) != null;
  }

  @override
  Future<void> clearPin() async {
    final prefs = await _prefs;
    await prefs.remove(_keyPinHash);
    await prefs.remove(_keyPinSalt);
  }

  @override
  Future<void> setAutoLockTimeout(int minutes) async {
    final prefs = await _prefs;
    await prefs.setInt(_keyAutoLockTimeout, minutes);
  }

  @override
  Future<int> getAutoLockTimeout() async {
    final prefs = await _prefs;
    return prefs.getInt(_keyAutoLockTimeout) ?? 0; // 0 = immediate
  }

  @override
  Future<void> setPrivacyScreenEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyPrivacyScreen, enabled);
  }

  @override
  Future<bool> isPrivacyScreenEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyPrivacyScreen) ?? true;
  }
}
