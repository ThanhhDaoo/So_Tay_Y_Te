import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/security/secure_storage_helper.dart';

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
  Future<void> saveProSubscriptionInfo({
    required String planId,
    required String paymentMethod,
    required String transactionCode,
    required DateTime activatedAt,
    DateTime? expiresAt,
    String? userId,
  });
  Future<Map<String, String?>> getProSubscriptionInfo({String? userId});
  Future<void> clearProSubscriptionInfo({String? userId});
  Future<void> setBiometricLockEnabled(bool enabled);
  Future<bool> isBiometricLockEnabled();
  Future<void> savePin({required String pinHash, required String salt});
  Future<String?> getPinHash();
  Future<String?> getPinSalt();
  Future<bool> hasPin();
  Future<void> clearPin();
  Future<int> getPinFailedAttempts();
  Future<void> setPinFailedAttempts(int count);
  Future<DateTime?> getPinLockoutUntil();
  Future<void> setPinLockoutUntil(DateTime? lockoutUntil);
  Future<void> setAutoLockTimeout(int minutes);
  Future<int> getAutoLockTimeout();
  Future<void> setPrivacyScreenEnabled(bool enabled);
  Future<bool> isPrivacyScreenEnabled();
  Future<void> setProfileEditLocked(bool locked);
  Future<bool> isProfileEditLocked();
  Future<String> getOrCreateBackupMasterKey();
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
  static const String _keyPinFailedAttempts = 'security_pin_failed_attempts';
  static const String _keyPinLockoutUntil = 'security_pin_lockout_until';
  static const String _keyAutoLockTimeout = 'security_auto_lock_timeout';
  static const String _keyPrivacyScreen = 'security_privacy_screen';
  static const String _keyProfileEditLocked = 'security_profile_edit_locked';
  static const String _keyBackupMasterKey = 'security_backup_master_key';
  static const String _keyAutoCloudSync = 'security_auto_cloud_sync';
  static const String _keyLastBackupTime = 'security_last_backup_time';
  static const String _keyLastBackupSize = 'security_last_backup_size';

  final SecureStorageHelper _secureStorage;

  AppPreferencesDataSourceImpl({SecureStorageHelper? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorageHelperImpl();

  Future<SharedPreferences> get _prefs async {
    try {
      if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
        return await SharedPreferences.getInstance()
            .timeout(const Duration(milliseconds: 50));
      }
      return await SharedPreferences.getInstance();
    } catch (_) {
      // Fallback an toàn cho các Widget Test chưa gọi setMockInitialValues để tránh treo FakeAsync
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      return await SharedPreferences.getInstance();
    }
  }

  @override
  Future<void> saveToken(String token) async {
    await _secureStorage.write(_keyToken, token);
    final prefs = await _prefs;
    await prefs.remove(_keyToken);
  }

  @override
  Future<String?> getToken() async {
    final secureToken = await _secureStorage.read(_keyToken);
    if (secureToken != null && secureToken.isNotEmpty) return secureToken;
    final prefs = await _prefs;
    final legacy = prefs.getString(_keyToken);
    if (legacy != null && legacy.isNotEmpty) {
      await _secureStorage.write(_keyToken, legacy);
      await prefs.remove(_keyToken);
    }
    return legacy;
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
    await _secureStorage.delete(_keyToken);
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

  String _proMetaKey(String field, String? effectiveUser) {
    if (effectiveUser != null && effectiveUser.isNotEmpty) {
      return 'pro_meta_${field}_$effectiveUser';
    }
    return 'pro_meta_$field';
  }

  @override
  Future<void> saveProSubscriptionInfo({
    required String planId,
    required String paymentMethod,
    required String transactionCode,
    required DateTime activatedAt,
    DateTime? expiresAt,
    String? userId,
  }) async {
    final prefs = await _prefs;
    final effectiveUser = userId ?? prefs.getString(_keyUserId);
    await prefs.setString(_proMetaKey('plan_id', effectiveUser), planId);
    await prefs.setString(_proMetaKey('method', effectiveUser), paymentMethod);
    await prefs.setString(_proMetaKey('tx_code', effectiveUser), transactionCode);
    await prefs.setString(
      _proMetaKey('activated_at', effectiveUser),
      activatedAt.toIso8601String(),
    );
    if (expiresAt != null) {
      await prefs.setString(
        _proMetaKey('expires_at', effectiveUser),
        expiresAt.toIso8601String(),
      );
    } else {
      await prefs.remove(_proMetaKey('expires_at', effectiveUser));
    }
  }

  @override
  Future<Map<String, String?>> getProSubscriptionInfo({String? userId}) async {
    final prefs = await _prefs;
    final effectiveUser = userId ?? prefs.getString(_keyUserId);
    return {
      'planId': prefs.getString(_proMetaKey('plan_id', effectiveUser)),
      'paymentMethod': prefs.getString(_proMetaKey('method', effectiveUser)),
      'transactionCode': prefs.getString(_proMetaKey('tx_code', effectiveUser)),
      'activatedAt': prefs.getString(_proMetaKey('activated_at', effectiveUser)),
      'expiresAt': prefs.getString(_proMetaKey('expires_at', effectiveUser)),
    };
  }

  @override
  Future<void> clearProSubscriptionInfo({String? userId}) async {
    final prefs = await _prefs;
    final effectiveUser = userId ?? prefs.getString(_keyUserId);
    await prefs.remove(_proMetaKey('plan_id', effectiveUser));
    await prefs.remove(_proMetaKey('method', effectiveUser));
    await prefs.remove(_proMetaKey('tx_code', effectiveUser));
    await prefs.remove(_proMetaKey('activated_at', effectiveUser));
    await prefs.remove(_proMetaKey('expires_at', effectiveUser));
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
    await _secureStorage.write(_keyPinHash, pinHash);
    await _secureStorage.write(_keyPinSalt, salt);
    final prefs = await _prefs;
    await prefs.remove(_keyPinHash);
    await prefs.remove(_keyPinSalt);
    await prefs.remove(_keyPinFailedAttempts);
    await prefs.remove(_keyPinLockoutUntil);
  }

  @override
  Future<String?> getPinHash() async {
    final secureHash = await _secureStorage.read(_keyPinHash);
    if (secureHash != null && secureHash.isNotEmpty) return secureHash;
    final prefs = await _prefs;
    final legacyHash = prefs.getString(_keyPinHash);
    if (legacyHash != null && legacyHash.isNotEmpty) {
      await _secureStorage.write(_keyPinHash, legacyHash);
      await prefs.remove(_keyPinHash);
    }
    return legacyHash;
  }

  @override
  Future<String?> getPinSalt() async {
    final secureSalt = await _secureStorage.read(_keyPinSalt);
    if (secureSalt != null && secureSalt.isNotEmpty) return secureSalt;
    final prefs = await _prefs;
    final legacySalt = prefs.getString(_keyPinSalt);
    if (legacySalt != null && legacySalt.isNotEmpty) {
      await _secureStorage.write(_keyPinSalt, legacySalt);
      await prefs.remove(_keyPinSalt);
    }
    return legacySalt;
  }

  @override
  Future<bool> hasPin() async {
    final hash = await getPinHash();
    return hash != null && hash.isNotEmpty;
  }

  @override
  Future<void> clearPin() async {
    await _secureStorage.delete(_keyPinHash);
    await _secureStorage.delete(_keyPinSalt);
    final prefs = await _prefs;
    await prefs.remove(_keyPinHash);
    await prefs.remove(_keyPinSalt);
    await prefs.remove(_keyPinFailedAttempts);
    await prefs.remove(_keyPinLockoutUntil);
  }

  @override
  Future<int> getPinFailedAttempts() async {
    final prefs = await _prefs;
    return prefs.getInt(_keyPinFailedAttempts) ?? 0;
  }

  @override
  Future<void> setPinFailedAttempts(int count) async {
    final prefs = await _prefs;
    if (count <= 0) {
      await prefs.remove(_keyPinFailedAttempts);
    } else {
      await prefs.setInt(_keyPinFailedAttempts, count);
    }
  }

  @override
  Future<DateTime?> getPinLockoutUntil() async {
    final prefs = await _prefs;
    final iso = prefs.getString(_keyPinLockoutUntil);
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }

  @override
  Future<void> setPinLockoutUntil(DateTime? lockoutUntil) async {
    final prefs = await _prefs;
    if (lockoutUntil == null) {
      await prefs.remove(_keyPinLockoutUntil);
    } else {
      await prefs.setString(_keyPinLockoutUntil, lockoutUntil.toIso8601String());
    }
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
  Future<void> setProfileEditLocked(bool locked) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyProfileEditLocked, locked);
  }

  @override
  Future<bool> isProfileEditLocked() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyProfileEditLocked) ?? false;
  }

  @override
  Future<String> getOrCreateBackupMasterKey() async {
    final existing = await _secureStorage.read(_keyBackupMasterKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    final generated = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await _secureStorage.write(_keyBackupMasterKey, generated);
    return generated;
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
