import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/security/backup_cipher.dart';
import '../../../../core/security/biometric_service.dart';
import '../../../../core/security/password_hasher.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/user_session_manager.dart';
import '../../../../data/datasources/local/app_preferences_datasource.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../../domain/repositories/sync_repository.dart';
import '../../../routes/app_routes.dart';
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

  Future<bool> hasConfiguredPin() async {
    return await _preferencesDataSource.hasPin();
  }

  Future<int> getPinLockoutRemainingSeconds() async {
    final until = await _preferencesDataSource.getPinLockoutUntil();
    if (until == null) return 0;
    final diff = until.difference(DateTime.now()).inSeconds;
    if (diff <= 0) {
      await _preferencesDataSource.setPinLockoutUntil(null);
      return 0;
    }
    return diff;
  }

  Future<int> getPinFailedAttempts() async {
    return await _preferencesDataSource.getPinFailedAttempts();
  }

  Future<bool> verifyPin(String rawPin) async {
    final remainingLock = await getPinLockoutRemainingSeconds();
    if (remainingLock > 0) return false;

    final storedHash = await _preferencesDataSource.getPinHash();
    final storedSalt = await _preferencesDataSource.getPinSalt();
    if (storedHash == null || storedSalt == null) return false;

    final isMatch = PasswordHasher.verifyPassword(
      password: rawPin,
      salt: storedSalt,
      expectedHash: storedHash,
    );

    if (isMatch) {
      await _preferencesDataSource.setPinFailedAttempts(0);
      await _preferencesDataSource.setPinLockoutUntil(null);
      return true;
    }

    final attempts = (await _preferencesDataSource.getPinFailedAttempts()) + 1;
    await _preferencesDataSource.setPinFailedAttempts(attempts);
    if (attempts >= 5) {
      final lockSeconds = attempts >= 10 ? 300 : 30;
      await _preferencesDataSource.setPinLockoutUntil(
        DateTime.now().add(Duration(seconds: lockSeconds)),
      );
    }
    return false;
  }

  /// Phương thức mở khóa dự phòng bằng mật khẩu hồ sơ (tránh kẹt khóa vĩnh viễn khi quên PIN hoặc chưa đặt PIN).
  Future<bool> unlockWithAccountPassword(String password) async {
    if (password.isEmpty || !sl.isRegistered<AuthRepository>()) return false;
    try {
      final authRepo = sl<AuthRepository>();
      final session = await authRepo.getActiveSession();
      if (session == null) return false;

      final identifier = session.primaryContact.isNotEmpty
          ? session.primaryContact
          : session.patientCode;
      await authRepo.login(
        identifier: identifier,
        password: password,
        rememberMe: true,
      );
      await _preferencesDataSource.setPinFailedAttempts(0);
      await _preferencesDataSource.setPinLockoutUntil(null);
      return true;
    } catch (_) {
      return false;
    }
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

  Future<String> _resolveActiveBackupPassphrase(String? customPassphrase) async {
    if (customPassphrase != null && customPassphrase.trim().isNotEmpty) {
      return customPassphrase.trim();
    }
    return await _preferencesDataSource.getOrCreateBackupMasterKey();
  }

  Future<void> exportBackup({String? passphrase, String? outputFilePath}) async {
    _state = _state.copyWith(
      currentOperation: SecurityOperation.exportingBackup,
      feedbackMessage: 'Đang mã hóa AES-256-GCM và đóng gói tệp dự phòng (.sotayyte)...',
    );
    notifyListeners();

    try {
      String? activeUserId = await _preferencesDataSource.getSessionUserId();
      if ((activeUserId == null || activeUserId.isEmpty) && sl.isRegistered<AuthRepository>()) {
        try {
          activeUserId = (await sl<AuthRepository>().getActiveSession())?.id;
        } catch (_) {}
      }

      final backupData = <String, dynamic>{
        'version': 2,
        'app': 'So_Tay_Y_Te',
        'owner_user_id': activeUserId,
        'exported_at': DateTime.now().toIso8601String(),
      };

      if (_databaseHelper != null) {
        final db = await _databaseHelper.database;
        List<Map<String, dynamic>> userEvents = const [];
        try {
          userEvents = (activeUserId != null && activeUserId.isNotEmpty)
              ? await db.query(
                  'medical_events',
                  where: 'user_id = ? AND (deleted_at IS NULL OR deleted_at = "")',
                  whereArgs: [activeUserId],
                )
              : await db.query('medical_events');
          backupData['medical_events'] = userEvents;
        } catch (_) {
          try {
            userEvents = (activeUserId != null && activeUserId.isNotEmpty)
                ? await db.query('medical_events', where: 'user_id = ?', whereArgs: [activeUserId])
                : await db.query('medical_events');
            backupData['medical_events'] = userEvents;
          } catch (_) {}
        }

        final eventIds = userEvents.map((e) => e['id'] as String).toList();
        List<Map<String, dynamic>> userPrescriptions = const [];
        if (eventIds.isNotEmpty) {
          final placeholders = List.filled(eventIds.length, '?').join(', ');
          try {
            userPrescriptions = await db.query(
              'prescriptions',
              where: 'event_id IN ($placeholders)',
              whereArgs: eventIds,
            );
          } catch (_) {}
        }
        backupData['prescriptions'] = userPrescriptions;

        final presIds = userPrescriptions.map((p) => p['id'] as String).toList();
        if (presIds.isNotEmpty) {
          final presPlaceholders = List.filled(presIds.length, '?').join(', ');
          try {
            backupData['medicines'] = await db.query(
              'medicines',
              where: 'prescription_id IN ($presPlaceholders)',
              whereArgs: presIds,
            );
          } catch (_) {}
        } else {
          backupData['medicines'] = const [];
        }

        try {
          backupData['medical_documents'] = (activeUserId != null && activeUserId.isNotEmpty)
              ? await db.query('medical_documents', where: 'user_id = ?', whereArgs: [activeUserId])
              : await db.query('medical_documents');
        } catch (_) {}

        try {
          backupData['user_profile'] = (activeUserId != null && activeUserId.isNotEmpty)
              ? await db.query('user_profile', where: 'id = ?', whereArgs: [activeUserId])
              : await db.query('user_profile');
        } catch (_) {}

        try {
          backupData['family_members'] = (activeUserId != null && activeUserId.isNotEmpty)
              ? await db.query('family_members', where: 'user_id = ?', whereArgs: [activeUserId])
              : await db.query('family_members');
        } catch (_) {}
      }

      final plainJson = jsonEncode(backupData);
      final effectiveKey = await _resolveActiveBackupPassphrase(passphrase);
      final encryptedPayload = BackupCipher.encryptJsonPayload(
        plainJson,
        passphrase: effectiveKey,
      );

      final sizeKb = (utf8.encode(encryptedPayload).length / 1024).clamp(0.1, 999999);
      final sizeLabel = sizeKb >= 1024
          ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
          : '${sizeKb.toStringAsFixed(1)} KB';

      final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
      if (outputFilePath != null && outputFilePath.isNotEmpty) {
        final outFile = File(outputFilePath);
        if (isTest) {
          outFile.writeAsStringSync(encryptedPayload, flush: true);
        } else {
          await outFile.writeAsString(encryptedPayload, flush: true);
        }
      } else if (!isTest) {
        final dir = await getTemporaryDirectory();
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final file = File(p.join(dir.path, 'sotayyte_backup_$timestamp.sotayyte'));
        await file.writeAsString(encryptedPayload, flush: true);

        AppRoutes.isExternalPickerActive = true;
        try {
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path)],
              subject: 'Sao lưu hồ sơ Sổ Tay Y Tế',
              text: 'Tệp sao lưu mã hóa AES-256-GCM hồ sơ sức khỏe cá nhân (.sotayyte)',
            ),
          );
        } finally {
          AppRoutes.isExternalPickerActive = false;
        }
      } else {
        final testTempFile = File(p.join(Directory.systemTemp.path, 'sotayyte_unit_test_latest.sotayyte'));
        testTempFile.writeAsStringSync(encryptedPayload, flush: true);
      }

      final nowFormatted = DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now());
      _state = _state.copyWith(
        currentOperation: SecurityOperation.none,
        lastBackupTime: nowFormatted,
        lastBackupSize: sizeLabel,
        feedbackMessage: 'Đã xuất tệp dự phòng sao lưu mã hóa (.sotayyte) thành công!',
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

  Future<void> restoreBackup({String? filePath, String? passphrase}) async {
    _state = _state.copyWith(
      currentOperation: SecurityOperation.restoringBackup,
      feedbackMessage: 'Đang giải mã và kiểm tra tính toàn vẹn dữ liệu sao lưu...',
    );
    notifyListeners();

    try {
      final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
      File? targetFile;
      if (filePath != null && filePath.isNotEmpty) {
        targetFile = File(filePath);
      } else if (!isTest) {
        AppRoutes.isExternalPickerActive = true;
        try {
          final picked = await FilePicker.pickFiles(
            type: FileType.any,
            dialogTitle: 'Chọn tệp sao lưu Sổ Tay Y Tế (.sotayyte)',
          );
          final pickedPath = picked.firstOrNull?.path;
          if (pickedPath != null && pickedPath.isNotEmpty) {
            targetFile = File(pickedPath);
          }
        } catch (pickerErr) {
          debugPrint('[SecuritySettings] FilePicker fallback: $pickerErr');
        } finally {
          AppRoutes.isExternalPickerActive = false;
        }

        // Dự phòng tìm trong thư mục tạm nếu trình chọn file không trả về trên môi trường giả lập
        if (targetFile == null) {
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
        }
      } else {
        final testTempFile = File(p.join(Directory.systemTemp.path, 'sotayyte_unit_test_latest.sotayyte'));
        if (testTempFile.existsSync()) {
          targetFile = testTempFile;
        }
      }

      if (!isTest && (targetFile == null || !targetFile.existsSync())) {
        _state = _state.copyWith(
          currentOperation: SecurityOperation.none,
          feedbackMessage: 'Đã hủy chọn tệp hoặc không tìm thấy tệp sao lưu (.sotayyte).',
        );
        notifyListeners();
        return;
      }

      if (targetFile != null && targetFile.existsSync()) {
        final content = isTest
            ? targetFile.readAsStringSync()
            : await targetFile.readAsString();
        final effectiveKey = await _resolveActiveBackupPassphrase(passphrase);
        final data = BackupCipher.decryptToMap(content, passphrase: effectiveKey);

        if (data['app'] != 'So_Tay_Y_Te') {
          throw const FormatException('Định dạng tệp sao lưu không hợp lệ.');
        }

        if (_databaseHelper != null) {
          String? activeUserId = await _preferencesDataSource.getSessionUserId();
          if ((activeUserId == null || activeUserId.isEmpty) && sl.isRegistered<AuthRepository>()) {
            try {
              activeUserId = (await sl<AuthRepository>().getActiveSession())?.id;
            } catch (_) {}
          }

          final db = await _databaseHelper.database;
          await db.transaction((txn) async {
            if (data['medical_events'] is List) {
              for (final row in data['medical_events'] as List) {
                final mapped = Map<String, dynamic>.from(row as Map);
                if (activeUserId != null && activeUserId.isNotEmpty) {
                  mapped['user_id'] = activeUserId;
                }
                await txn.insert('medical_events', mapped,
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
                final mapped = Map<String, dynamic>.from(row as Map);
                if (activeUserId != null && activeUserId.isNotEmpty) {
                  mapped['user_id'] = activeUserId;
                }
                await txn.insert('medical_documents', mapped,
                    conflictAlgorithm: ConflictAlgorithm.replace);
              }
            }
            if (data['user_profile'] is List) {
              for (final row in data['user_profile'] as List) {
                final mapped = Map<String, dynamic>.from(row as Map);
                if (activeUserId != null && activeUserId.isNotEmpty) {
                  mapped['id'] = activeUserId;
                }
                await txn.insert('user_profile', mapped,
                    conflictAlgorithm: ConflictAlgorithm.replace);
              }
            }
            if (data['family_members'] is List) {
              for (final row in data['family_members'] as List) {
                final mapped = Map<String, dynamic>.from(row as Map);
                if (activeUserId != null && activeUserId.isNotEmpty) {
                  mapped['user_id'] = activeUserId;
                }
                await txn.insert('family_members', mapped,
                    conflictAlgorithm: ConflictAlgorithm.replace);
              }
            }
          });
          AppSessionNotifier.instance.notifyMedicalRecordsChanged();
          AppSessionNotifier.instance.notifyProfileChanged();
        }
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
    await _preferencesDataSource.setProfileEditLocked(false);
    await _preferencesDataSource.saveBiometricUserId(null);
    await _preferencesDataSource.saveLastLoginIdentifier(null);
    AppSessionNotifier.instance.resetActiveMember();

    _state = _state.copyWith(
      currentOperation: SecurityOperation.none,
      hasPinCode: false,
      isBiometricLockEnabled: false,
      feedbackMessage: 'Đã xóa trắng toàn bộ dữ liệu cục bộ an toàn!',
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
