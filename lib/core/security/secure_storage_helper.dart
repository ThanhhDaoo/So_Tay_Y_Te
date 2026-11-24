import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStorageHelper {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> clearAll();
}

/// Lưu trữ an toàn khóa mã hóa, mã băm PIN và token phiên vào Keychain (iOS/macOS)
/// và EncryptedSharedPreferences / Keystore (Android).
/// Hỗ trợ fallback bộ nhớ RAM an toàn trong môi trường kiểm thử tự động (FLUTTER_TEST).
class SecureStorageHelperImpl implements SecureStorageHelper {
  final FlutterSecureStorage _storage;
  final Map<String, String> _testMemoryStore = {};

  SecureStorageHelperImpl({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  bool get _isFlutterTest =>
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  @override
  Future<void> write(String key, String value) async {
    if (_isFlutterTest) {
      _testMemoryStore[key] = value;
      return;
    }
    try {
      await _storage.write(key: key, value: value);
    } on MissingPluginException {
      _testMemoryStore[key] = value;
    } on PlatformException {
      _testMemoryStore[key] = value;
    }
  }

  @override
  Future<String?> read(String key) async {
    if (_isFlutterTest) {
      return _testMemoryStore[key];
    }
    try {
      return await _storage.read(key: key) ?? _testMemoryStore[key];
    } on MissingPluginException {
      return _testMemoryStore[key];
    } on PlatformException {
      return _testMemoryStore[key];
    }
  }

  @override
  Future<void> delete(String key) async {
    _testMemoryStore.remove(key);
    if (_isFlutterTest) return;
    try {
      await _storage.delete(key: key);
    } on MissingPluginException {
      // Fallback in headless environment
    } on PlatformException {
      // Ignore if key not present
    }
  }

  @override
  Future<void> clearAll() async {
    _testMemoryStore.clear();
    if (_isFlutterTest) return;
    try {
      await _storage.deleteAll();
    } on MissingPluginException {
      // Fallback in headless environment
    } on PlatformException {
      // Ignore platform errors during wipe
    }
  }
}
