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
  Future<void> saveBiometricUserId(String? userId);
  Future<String?> getBiometricUserId();
  Future<void> saveLastLoginIdentifier(String? identifier);
  Future<String?> getLastLoginIdentifier();
  Future<void> setProStatus(bool isPro, {String? userId});
  Future<bool> getProStatus({String? userId});
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
  Future<void> setAutoCloudSyncEnabled(bool enabled);
  Future<bool> isAutoCloudSyncEnabled();
  Future<void> saveLastBackupMetadata({required String timeLabel, required String sizeLabel});
  Future<String?> getLastBackupTime();
  Future<String?> getLastBackupSize();
  Future<List<String>> getTakenDoseSlotsForDate(String dateKey);
  Future<void> saveTakenDoseSlotsForDate(String dateKey, List<String> slotIds);
}

class AppPreferencesDataSourceImpl implements AppPreferencesDataSource {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyPatientCode = 'auth_patient_code';
  static const String _keyContact = 'auth_contact';
  static const String _keyRememberMe = 'auth_remember_me';
  static const String _keyBiometricUserId = 'auth_biometric_user_id';
  static const String _keyLastLoginIdentifier = 'auth_last_login_identifier';
  static const String _keyIsPro = 'is_pro_member';
  static const String _keyBiometricEnabled = 'security_biometric_enabled';
  static const String _keyPinHash = 'security_pin_hash';
  static const String _keyPinSalt = 'security_pin_salt';
  static const String _keyAutoLockTimeout = 'security_auto_lock_timeout';
  static const String _keyPrivacyScreen = 'security_privacy_screen';
  static const String _keyAutoCloudSync = 'security_auto_cloud_sync';
  static const String _keyLastBackupTime = 'security_last_backup_time';
  static const String _keyLastBackupSize = 'security_last_backup_size';

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
  Future<void> saveBiometricUserId(String? userId) async {
    final prefs = await _prefs;
    if (userId == null || userId.isEmpty) {
      await prefs.remove(_keyBiometricUserId);
    } else {
      await prefs.setString(_keyBiometricUserId, userId);
    }
  }

  @override
  Future<String?> getBiometricUserId() async {
    final prefs = await _prefs;
    return prefs.getString(_keyBiometricUserId);
  }

  @override
  Future<void> saveLastLoginIdentifier(String? identifier) async {
    final prefs = await _prefs;
    if (identifier == null || identifier.trim().isEmpty) {
      await prefs.remove(_keyLastLoginIdentifier);
    } else {
      await prefs.setString(_keyLastLoginIdentifier, identifier.trim());
    }
  }

  @override
  Future<String?> getLastLoginIdentifier() async {
    final prefs = await _prefs;
    return prefs.getString(_keyLastLoginIdentifier);
  }

  @override
  Future<void> setProStatus(bool isPro, {String? userId}) async {
    final prefs = await _prefs;
    final effectiveUser = userId ?? prefs.getString(_keyUserId);
    if (effectiveUser != null && effectiveUser.isNotEmpty) {
      await prefs.setBool('${_keyIsPro}_$effectiveUser', isPro);
    } else {
      await prefs.setBool(_keyIsPro, isPro);
    }
  }

  @override
  Future<bool> getProStatus({String? userId}) async {
    final prefs = await _prefs;
    final effectiveUser = userId ?? prefs.getString(_keyUserId);
    if (effectiveUser != null && effectiveUser.isNotEmpty) {
      return prefs.getBool('${_keyIsPro}_$effectiveUser') ?? false;
    }
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

  @override
  Future<void> setAutoCloudSyncEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyAutoCloudSync, enabled);
  }

  @override
  Future<bool> isAutoCloudSyncEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyAutoCloudSync) ?? true;
  }

  @override
  Future<void> saveLastBackupMetadata({
    required String timeLabel,
    required String sizeLabel,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_keyLastBackupTime, timeLabel);
    await prefs.setString(_keyLastBackupSize, sizeLabel);
  }

  @override
  Future<String?> getLastBackupTime() async {
    final prefs = await _prefs;
    return prefs.getString(_keyLastBackupTime);
  }

  @override
  Future<String?> getLastBackupSize() async {
    final prefs = await _prefs;
    return prefs.getString(_keyLastBackupSize);
  }

  @override
  Future<List<String>> getTakenDoseSlotsForDate(String dateKey) async {
    final prefs = await _prefs;
    final uid = prefs.getString(_keyUserId) ?? 'default';
    return prefs.getStringList('rx_taken_${uid}_$dateKey') ?? const [];
  }

  @override
  Future<void> saveTakenDoseSlotsForDate(String dateKey, List<String> slotIds) async {
    final prefs = await _prefs;
    final uid = prefs.getString(_keyUserId) ?? 'default';
    await prefs.setStringList('rx_taken_${uid}_$dateKey', slotIds);
  }
}
