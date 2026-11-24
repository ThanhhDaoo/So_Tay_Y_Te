import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../core/di/injection_container.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/pdf_report_service.dart';
import '../../core/services/user_session_manager.dart';
import '../../domain/entities/medical_event.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/medical_record_repository.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/local/app_preferences_datasource.dart';
import '../datasources/local/medical_local_datasource.dart';
import '../models/medical_event_model.dart';

class MedicalRecordRepositoryImpl implements MedicalRecordRepository {
  final MedicalLocalDataSource localDataSource;
  final SyncRepository? syncRepository;

  MedicalRecordRepositoryImpl({
    required this.localDataSource,
    this.syncRepository,
  });

  Future<String?> _resolveActiveUserId() async {
    if (!sl.isRegistered<AppPreferencesDataSource>()) return null;
    try {
      return await sl<AppPreferencesDataSource>().getSessionUserId();
    } catch (_) {
      return null;
    }
  }

  Future<bool> _isAutoSyncAllowed() async {
    if (!sl.isRegistered<AppPreferencesDataSource>()) return true;
    try {
      return await sl<AppPreferencesDataSource>().isAutoCloudSyncEnabled();
    } catch (_) {
      return true;
    }
  }

  @override
  Future<List<MedicalEvent>> getMedicalTimeline({String? userId}) async {
    final effectiveUserId = userId ?? await _resolveActiveUserId();
    final models = await localDataSource.getAllEvents(userId: effectiveUserId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<MedicalEvent?> getMedicalEventById(String id) async {
    final model = await localDataSource.getEventById(id);
    return model?.toEntity();
  }

  @override
  Future<void> saveMedicalEvent(MedicalEvent event) async {
    final resolvedUserId = (event.userId != null && event.userId!.isNotEmpty)
        ? event.userId
        : await _resolveActiveUserId();

    final model = MedicalEventModel(
      id: event.id,
      userId: resolvedUserId,
      title: event.title,
      description: event.description,
      date: event.date,
      type: event.type,
      facilityName: event.facilityName,
      doctorName: event.doctorName,
      department: event.department,
      diagnosis: event.diagnosis,
      bloodPressure: event.bloodPressure,
      heartRate: event.heartRate,
      prescription: event.prescription,
      attachments: event.attachments,
      hospitalFee: event.hospitalFee,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
    );
    await localDataSource.insertOrUpdateEvent(model);
    AppSessionNotifier.instance.notifyMedicalRecordsChanged();

    if (syncRepository != null && await _isAutoSyncAllowed()) {
      syncRepository!.syncLocalToCloud().catchError((e) {
        debugPrint('[AutoCloudSync] Sync in background failed: $e');
      });
    }
  }

  @override
  Future<void> deleteMedicalEvent(String id) async {
    await localDataSource.deleteEvent(id);
    AppSessionNotifier.instance.notifyMedicalRecordsChanged();

    if (syncRepository != null && await _isAutoSyncAllowed()) {
      syncRepository!.deleteRemoteEvent(id).catchError((e) {
        debugPrint('[AutoCloudSync] Remote delete in background failed: $e');
      });
    }

    try {
      if (sl.isRegistered<NotificationService>() && sl.isRegistered<DatabaseHelper>()) {
        final db = await sl<DatabaseHelper>().database;
        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM medicines'),
        ) ?? 0;
        if (count == 0) {
          final notif = sl<NotificationService>();
          await notif.cancelAllReminders();
        }
      }
    } catch (e) {
      debugPrint('[MedicalRecordRepository] Notification cleanup error: $e');
    }
  }

  @override
  Future<String> exportHealthPdf() async {
    final events = await getMedicalTimeline();
    final latestEvent = events.isNotEmpty
        ? events.first
        : MedicalEvent(
            id: 'SUMMARY-${DateTime.now().millisecondsSinceEpoch}',
            title: 'Tóm Tắt Hồ Sơ Sức Khỏe Cá Nhân',
            description: 'Báo cáo tổng hợp từ Sổ Tay Y Tế.',
            date: DateTime.now(),
            type: MedicalEventType.generalCheckup,
          );

    UserProfile? patientProfile;
    if (sl.isRegistered<AuthRepository>()) {
      try {
        final authRepo = sl<AuthRepository>();
        final session = await authRepo.getActiveSession();
        if (session != null) {
          final details = await authRepo.getUserProfileDetails(session.id);
          final rawAllergies = details?['allergies']?.toString().trim() ?? '';
          final rawIce = details?['emergency_contact']?.toString().trim();
          patientProfile = UserProfile(
            id: session.id,
            fullName: session.fullName,
            bloodType: session.bloodType,
            emergencyContact: (rawIce != null && rawIce.isNotEmpty && !rawIce.contains('@'))
                ? rawIce
                : (!session.primaryContact.contains('@') ? session.primaryContact : null),
            allergies: rawAllergies.isNotEmpty
                ? rawAllergies.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
                : const [],
          );
        } else {
          patientProfile = await authRepo.getCurrentUser();
        }
      } catch (_) {}
    }

    final pdfService = sl.isRegistered<PdfReportService>()
        ? sl<PdfReportService>()
        : PdfReportServiceImpl();
    final bytes = await pdfService.generateMedicalRecordPdf(
      record: latestEvent,
      patientProfile: patientProfile,
    );

    Directory outDir;
    try {
      outDir = await getTemporaryDirectory();
    } catch (_) {
      outDir = Directory.systemTemp;
    }
    final outFile = File('${outDir.path}/health_summary_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await outFile.writeAsBytes(bytes, flush: true);
    return outFile.path;
  }
}
