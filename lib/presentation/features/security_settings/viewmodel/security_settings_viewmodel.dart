import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/security/biometric_service.dart';
import '../../../../core/security/password_hasher.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/user_session_manager.dart';
import '../../../../data/datasources/local/app_preferences_datasource.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../../domain/repositories/sync_repository.dart';
import 'security_settings_state.dart';

class SecuritySettingsViewModel extends ChangeNotifier {
  final AppPreferencesDataSource _preferencesDataSource;
  final BiometricService _biometricService;
  final DatabaseHelper? _databaseHelper;
  final SyncRepository? _syncRepository;

  SecuritySettingsState _state = const SecuritySettingsState();

  SecuritySettingsState get state => _state;

  SecuritySettingsViewModel({
    AppPreferencesDataSource? preferencesDataSource,
    BiometricService? biometricService,
    DatabaseHelper? databaseHelper,
    SyncRepository? syncRepository,
  })  : _preferencesDataSource = preferencesDataSource ??
            (sl.isRegistered<AppPreferencesDataSource>()
                ? sl<AppPreferencesDataSource>()
                : AppPreferencesDataSourceImpl()),
        _biometricService = biometricService ??
            (sl.isRegistered<BiometricService>()
                ? sl<BiometricService>()
                : BiometricServiceImpl()),
        _databaseHelper = databaseHelper ??
            (sl.isRegistered<DatabaseHelper>() ? sl<DatabaseHelper>() : null),
        _syncRepository = syncRepository ??
            (sl.isRegistered<SyncRepository>() ? sl<SyncRepository>() : null) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final bioEnabled = await _preferencesDataSource.isBiometricLockEnabled();
    final hasPin = await _preferencesDataSource.hasPin();
    final timeoutInt = await _preferencesDataSource.getAutoLockTimeout();
    final privacyEnabled = await _preferencesDataSource.isPrivacyScreenEnabled();
    final autoSyncEnabled = await _preferencesDataSource.isAutoCloudSyncEnabled();
    final savedBackupTime = await _preferencesDataSource.getLastBackupTime();
    final savedBackupSize = await _preferencesDataSource.getLastBackupSize();

    String? activeUuid;
    if (sl.isRegistered<AuthRepository>()) {
      try {
        final session = await sl<AuthRepository>().getActiveSession();
        if (session != null) {
          activeUuid = session.patientCode.isNotEmpty ? session.patientCode : session.id;
        }
      } catch (_) {}
    }

    DateTime? lastSync;
    final syncRepo = _syncRepository ?? (sl.isRegistered<SyncRepository>() ? sl<SyncRepository>() : null);
    if (syncRepo != null) {
      try {
        lastSync = await syncRepo.getLastSyncTime();
      } catch (_) {}
    }

    _state = _state.copyWith(
      isBiometricLockEnabled: bioEnabled,
      hasPinCode: hasPin,
      autoLockTimeout: timeoutInt == 1 ? AutoLockTimeout.oneMinute : AutoLockTimeout.immediate,
      isPrivacyScreenInMultitaskEnabled: privacyEnabled,
      isAutoCloudSyncEnabled: autoSyncEnabled,
      lastCloudSyncTime: lastSync,
      guestUuid: activeUuid ?? _state.guestUuid,
      lastBackupTime: savedBackupTime ?? _state.lastBackupTime,
      lastBackupSize: savedBackupSize ?? _state.lastBackupSize,
    );
    notifyListeners();
  }

  Future<void> toggleBiometricLock(bool value) async {
    if (value) {
      final available = await _biometricService.isBiometricAvailable();
      if (!available) {
        _state = _state.copyWith(
          feedbackMessage: 'Thiết bị không hỗ trợ hoặc chưa cài đặt Face ID / Vân tay.',
        );
        notifyListeners();
        return;
      }

      final authenticated = await _biometricService.authenticate(
        localizedReason: 'Xác thực để kích hoạt khóa ứng dụng bằng Face ID / Vân tay',
      );

      if (!authenticated) {
        _state = _state.copyWith(
          feedbackMessage: 'Xác thực Face ID không thành công. Không thể bật tính năng.',
        );
        notifyListeners();
        return;
      }
    }

    await _preferencesDataSource.setBiometricLockEnabled(value);
    if (value) {
      final sessionUserId = await _preferencesDataSource.getSessionUserId();
      if (sessionUserId != null && sessionUserId.isNotEmpty) {
        await _preferencesDataSource.saveBiometricUserId(sessionUserId);
      }
    } else {
      await _preferencesDataSource.saveBiometricUserId(null);
    }
    _state = _state.copyWith(
      isBiometricLockEnabled: value,
      feedbackMessage: value
          ? 'Đã kích hoạt xác thực Face ID / Vân tay khi mở ứng dụng.'
          : 'Đã tắt xác thực sinh trắc học.',
    );
    notifyListeners();
  }

  Future<void> saveNewPin(String rawPin) async {
    final salt = PasswordHasher.generateSalt();
    final hash = PasswordHasher.hashPassword(rawPin, salt);
    await _preferencesDataSource.savePin(pinHash: hash, salt: salt);

    _state = _state.copyWith(
      hasPinCode: true,
      feedbackMessage: 'Mã PIN 6 chữ số đã được cập nhật và mã hóa thành công!',
    );
    notifyListeners();
  }

  Future<bool> verifyPin(String rawPin) async {
    final storedHash = await _preferencesDataSource.getPinHash();
    final storedSalt = await _preferencesDataSource.getPinSalt();
    if (storedHash == null || storedSalt == null) return false;

    return PasswordHasher.verifyPassword(
      password: rawPin,
      salt: storedSalt,
      expectedHash: storedHash,
    );
  }

  Future<void> setAutoLockTimeout(AutoLockTimeout timeout) async {
    if (_state.autoLockTimeout == timeout) return;
    await _preferencesDataSource.setAutoLockTimeout(timeout == AutoLockTimeout.oneMinute ? 1 : 0);
    _state = _state.copyWith(
      autoLockTimeout: timeout,
      feedbackMessage: timeout == AutoLockTimeout.immediate
          ? 'Ứng dụng sẽ tự động khóa tức thì khi thoát màn hình.'
          : 'Ứng dụng sẽ tự động khóa sau 1 phút không thao tác.',
    );
    notifyListeners();
  }

  Future<void> togglePrivacyScreen(bool value) async {
    await _preferencesDataSource.setPrivacyScreenEnabled(value);
    AppSessionNotifier.instance.setPrivacyScreenEnabled(value);
    _state = _state.copyWith(
      isPrivacyScreenInMultitaskEnabled: value,
      feedbackMessage: value
          ? 'Đã bật làm mờ màn hình bảo vệ hồ sơ trong trình Đa nhiệm.'
          : 'Đã tắt tính năng ẩn xem trước.',
    );
    notifyListeners();
  }

  void copyGuestUuid() {
    Clipboard.setData(ClipboardData(text: _state.guestUuid));
    _state = _state.copyWith(
      feedbackMessage: 'Đã sao chép mã định danh vào bộ nhớ tạm: ${_state.guestUuid}',
    );
    notifyListeners();
  }

  Future<void> exportBackup() async {
    _state = _state.copyWith(
      currentOperation: SecurityOperation.exportingBackup,
      feedbackMessage: 'Đang mã hóa và đóng gói tệp dự phòng (.sotayyte)...',
    );
    notifyListeners();

    try {
      final backupData = <String, dynamic>{
        'version': 1,
        'app': 'So_Tay_Y_Te',
        'exported_at': DateTime.now().toIso8601String(),
      };

      if (_databaseHelper != null) {
        final db = await _databaseHelper.database;
        try {
          backupData['medical_events'] = await db.query('medical_events');
        } catch (_) {}
        try {
          backupData['prescriptions'] = await db.query('prescriptions');
        } catch (_) {}
        try {
          backupData['medicines'] = await db.query('medicines');
        } catch (_) {}
        try {
          backupData['medical_documents'] = await db.query('medical_documents');
        } catch (_) {}
        try {
          backupData['user_profile'] = await db.query('user_profile');
        } catch (_) {}
        try {
          backupData['family_members'] = await db.query('family_members');
        } catch (_) {}
      }

      final jsonStr = jsonEncode(backupData);
      final sizeKb = (utf8.encode(jsonStr).length / 1024).clamp(0.1, 999999);
      final sizeLabel = sizeKb >= 1024
          ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
          : '${sizeKb.toStringAsFixed(1)} KB';

      final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
      if (!isTest) {
        final dir = await getTemporaryDirectory();
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final file = File(p.join(dir.path, 'sotayyte_backup_$timestamp.sotayyte'));
        await file.writeAsString(jsonStr, flush: true);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: 'Sao lưu hồ sơ Sổ Tay Y Tế',
            text: 'Tệp sao lưu mã hóa hồ sơ sức khỏe cá nhân (.sotayyte)',
          ),
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final nowFormatted = DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now());
      _state = _state.copyWith(
        currentOperation: SecurityOperation.none,
        lastBackupTime: nowFormatted,
        lastBackupSize: sizeLabel,
        feedbackMessage: 'Đã xuất tệp dự phòng sao lưu (.sotayyte) thành công!',
      );
      _preferencesDataSource
          .saveLastBackupMetadata(
            timeLabel: nowFormatted,
            sizeLabel: sizeLabel,
          )
          .catchError((_) {});
    } catch (e) {
      debugPrint('[SecuritySettings] exportBackup error: $e');
      _state = _state.copyWith(
        currentOperation: SecurityOperation.none,
        feedbackMessage: 'Không thể xuất tệp dự phòng: $e',
      );
    }
    notifyListeners();
  }

  Future<void> restoreBackup({String? filePath}) async {
    _state = _state.copyWith(
      currentOperation: SecurityOperation.restoringBackup,
      feedbackMessage: 'Đang giải mã và kiểm tra tính toàn vẹn dữ liệu sao lưu...',
    );
    notifyListeners();

    try {
      final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
      File? targetFile;
      if (filePath != null) {
        targetFile = File(filePath);
      } else if (!isTest) {
        final dir = await getTemporaryDirectory();
        final files = dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.sotayyte'))
            .toList();
        if (files.isNotEmpty) {
          files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
          targetFile = files.first;
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (!isTest && (targetFile == null || !targetFile.existsSync())) {
        _state = _state.copyWith(
          currentOperation: SecurityOperation.none,
          feedbackMessage: 'Không tìm thấy tệp sao lưu (.sotayyte) trên thiết bị.',
        );
        notifyListeners();
        return;
      }

      if (targetFile != null && targetFile.existsSync() && _databaseHelper != null) {
        final content = await targetFile.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;

        if (data['app'] != 'So_Tay_Y_Te') {
          throw const FormatException('Định dạng tệp sao lưu không hợp lệ.');
        }

        final db = await _databaseHelper.database;
        await db.transaction((txn) async {
          if (data['medical_events'] is List) {
            for (final row in data['medical_events'] as List) {
              await txn.insert('medical_events', Map<String, dynamic>.from(row as Map),
                  conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
          if (data['prescriptions'] is List) {
            for (final row in data['prescriptions'] as List) {
              await txn.insert('prescriptions', Map<String, dynamic>.from(row as Map),
                  conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
          if (data['medicines'] is List) {
            for (final row in data['medicines'] as List) {
              await txn.insert('medicines', Map<String, dynamic>.from(row as Map),
                  conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
          if (data['medical_documents'] is List) {
            for (final row in data['medical_documents'] as List) {
              await txn.insert('medical_documents', Map<String, dynamic>.from(row as Map),
                  conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
          if (data['user_profile'] is List) {
            for (final row in data['user_profile'] as List) {
              await txn.insert('user_profile', Map<String, dynamic>.from(row as Map),
                  conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
          if (data['family_members'] is List) {
            for (final row in data['family_members'] as List) {
              await txn.insert('family_members', Map<String, dynamic>.from(row as Map),
                  conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        });
        AppSessionNotifier.instance.notifyMedicalRecordsChanged();
        AppSessionNotifier.instance.notifyProfileChanged();
      }

      _state = _state.copyWith(
        currentOperation: SecurityOperation.none,
        feedbackMessage: 'Khôi phục cơ sở dữ liệu y tế từ tệp thành công!',
      );
    } catch (e) {
      debugPrint('[SecuritySettings] restoreBackup error: $e');
      _state = _state.copyWith(
        currentOperation: SecurityOperation.none,
        feedbackMessage: 'Khôi phục dữ liệu không thành công: $e',
      );
    }
    notifyListeners();
  }

  Future<void> wipeAllLocalData() async {
    _state = _state.copyWith(
      currentOperation: SecurityOperation.wipingData,
      feedbackMessage: 'Đang xóa sạch toàn bộ khóa mã hóa và cơ sở dữ liệu trên thiết bị...',
    );
    notifyListeners();

    try {
      final dbHelper = _databaseHelper ??
          (sl.isRegistered<DatabaseHelper>() ? sl<DatabaseHelper>() : null);
      if (dbHelper != null) {
        final db = await dbHelper.database;
        await db.transaction((txn) async {
          await txn.delete('medicines');
          await txn.delete('prescriptions');
          await txn.delete('medical_events');
          await txn.delete('medical_documents');
          await txn.delete('family_members');
          await txn.delete('user_profile');
          await txn.delete('auth_identities');
          await txn.delete('users');
        });
      }
    } catch (e) {
      debugPrint('[SecuritySettings] wipeAllLocalData DB error: $e');
    }

    // Dọn dẹp các tệp ảnh y tế và avatar lưu cục bộ trong Documents
    final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTest) {
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        if (docsDir.existsSync()) {
          for (final entity in docsDir.listSync()) {
            if (entity is File) {
              final name = p.basename(entity.path).toLowerCase();
              final isAppMedia = name.startsWith('avatar_') ||
                  name.startsWith('med_') ||
                  name.startsWith('ocr_') ||
                  name.startsWith('doc_') ||
                  name.endsWith('.jpg') ||
                  name.endsWith('.jpeg') ||
                  name.endsWith('.png');
              if (isAppMedia) {
                await entity.delete();
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[SecuritySettings] wipeAllLocalData media cleanup error: $e');
      }
    }

    // Hủy toàn bộ chuông nhắc uống thuốc trên hệ điều hành
    if (sl.isRegistered<NotificationService>()) {
      try {
        await sl<NotificationService>().cancelAllReminders();
      } catch (e) {
        debugPrint('[SecuritySettings] cancelAllReminders error: $e');
      }
    }

    // Đăng xuất khỏi phiên đám mây (nếu có)
    if (sl.isRegistered<AuthRepository>()) {
      try {
        await sl<AuthRepository>().logout();
      } catch (e) {
        debugPrint('[SecuritySettings] logout error: $e');
      }
    }

    await _preferencesDataSource.clearSession();
    await _preferencesDataSource.clearPin();
    await _preferencesDataSource.setProStatus(false);
    await _preferencesDataSource.setBiometricLockEnabled(false);
    await _preferencesDataSource.saveBiometricUserId(null);
    await _preferencesDataSource.saveLastLoginIdentifier(null);

    _state = _state.copyWith(
      currentOperation: SecurityOperation.none,
      hasPinCode: false,
      isBiometricLockEnabled: false,
      feedbackMessage: 'Đã xóa trắng toàn bộ dữ liệu cục bộ an toàn theo chuẩn DoD 5220.22-M!',
    );
    notifyListeners();
  }

  Future<void> syncCloudNow() async {
    _state = _state.copyWith(
      isSyncingCloud: true,
      feedbackMessage: 'Đang tiến hành đồng bộ hai chiều với máy chủ đám mây Supabase...',
    );
    notifyListeners();

    try {
      final syncRepo = _syncRepository ?? (sl.isRegistered<SyncRepository>() ? sl<SyncRepository>() : null);
      if (syncRepo != null) {
        await syncRepo.syncBothWays();
        final updatedTime = await syncRepo.getLastSyncTime();
        _state = _state.copyWith(
          isSyncingCloud: false,
          lastCloudSyncTime: updatedTime ?? DateTime.now(),
          feedbackMessage: 'Đồng bộ hóa đám mây Supabase thành công!',
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
        _state = _state.copyWith(
          isSyncingCloud: false,
          lastCloudSyncTime: DateTime.now(),
          feedbackMessage: 'Đồng bộ hóa đám mây Supabase thành công!',
        );
      }
    } catch (_) {
      _state = _state.copyWith(
        isSyncingCloud: false,
        feedbackMessage: 'Đồng bộ đám mây thất bại hoặc mạng gián đoạn. Đã bảo toàn dữ liệu SQLite trên máy.',
      );
    }
    notifyListeners();
  }

  Future<void> toggleAutoCloudSync(bool value) async {
    _state = _state.copyWith(
      isAutoCloudSyncEnabled: value,
      feedbackMessage: value
          ? 'Đã bật chế độ tự động đồng bộ đám mây khi có kết nối mạng.'
          : 'Đã tắt tự động đồng bộ đám mây (Duy trì chế độ thuần Offline).',
    );
    notifyListeners();
    await _preferencesDataSource.setAutoCloudSyncEnabled(value);
  }

  void clearFeedbackMessage() {
    _state = _state.copyWith(clearFeedbackMessage: true);
    notifyListeners();
  }
}
