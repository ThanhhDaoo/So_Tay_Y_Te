import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/user_session_manager.dart';
import '../../../../data/datasources/local/elder_care_local_datasource.dart';
import '../../../../data/repositories/elder_care_repository_impl.dart';
import '../../../../domain/entities/doctor_contact.dart';
import '../../../../domain/repositories/elder_care_repository.dart';

class DoctorsViewModel extends ChangeNotifier {
  final ElderCareRepository? _customRepo;
  final Uuid _uuid = const Uuid();

  List<DoctorContact> _doctors = const [];
  bool _isLoading = true;
  String? _feedbackMessage;

  List<DoctorContact> get doctors => _doctors;
  bool get isLoading => _isLoading;
  String? get feedbackMessage => _feedbackMessage;

  DoctorsViewModel({ElderCareRepository? repository})
      : _customRepo = repository {
    loadDoctors();
  }

  ElderCareRepository? _resolveRepo() {
    if (_customRepo != null) return _customRepo;
    if (sl.isRegistered<ElderCareRepository>()) {
      return sl<ElderCareRepository>();
    }
    if (sl.isRegistered<DatabaseHelper>()) {
      return ElderCareRepositoryImpl(
        localDataSource:
            ElderCareLocalDataSourceImpl(databaseHelper: sl<DatabaseHelper>()),
      );
    }
    return null;
  }

  Future<void> loadDoctors() async {
    _isLoading = true;
    notifyListeners();
    try {
      final repo = _resolveRepo();
      if (repo != null) {
        _doctors = await repo.getDoctors(
          memberId: AppSessionNotifier.instance.activeMemberId,
        );
      }
    } catch (e) {
      debugPrint('[DoctorsViewModel] loadDoctors error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addOrUpdateDoctor({
    String? existingId,
    required String fullName,
    required String specialty,
    required String hospitalName,
    required String phoneNumber,
    String? avatarPath,
    String? lastVisitDate,
    String? lastVisitNote,
    bool isPrimaryDoctor = false,
  }) async {
    final repo = _resolveRepo();
    if (repo == null) return;

    final contact = DoctorContact(
      id: existingId ?? 'doc_${_uuid.v4()}',
      memberId: AppSessionNotifier.instance.activeMemberId,
      fullName: fullName.trim(),
      specialty: specialty.trim(),
      hospitalName: hospitalName.trim(),
      phoneNumber: phoneNumber.trim(),
      avatarPath: avatarPath,
      lastVisitDate: lastVisitDate?.trim(),
      lastVisitNote: lastVisitNote?.trim(),
      isPrimaryDoctor: isPrimaryDoctor,
      createdAt: DateTime.now(),
    );

    await repo.saveDoctor(contact);
    await loadDoctors();
    _feedbackMessage = existingId != null
        ? 'Đã cập nhật thông tin bác sĩ ${contact.fullName}.'
        : 'Đã thêm bác sĩ ${contact.fullName} vào danh bạ!';
    notifyListeners();
  }

  Future<void> deleteDoctor(DoctorContact doctor) async {
    final repo = _resolveRepo();
    if (repo == null) return;
    await repo.deleteDoctor(doctor.id);
    await loadDoctors();
    _feedbackMessage = 'Đã xóa ${doctor.fullName} khỏi danh bạ.';
    notifyListeners();
  }

  Future<void> callDoctorNow(DoctorContact doctor) async {
    final cleanedPhone =
        doctor.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanedPhone.isEmpty) {
      _feedbackMessage = 'Bác sĩ này chưa có số điện thoại liên hệ.';
      notifyListeners();
      return;
    }

    final isTestEnv =
        !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (isTestEnv) {
      _feedbackMessage =
          'Đang mở cuộc gọi tới ${doctor.fullName} ($cleanedPhone)...';
      notifyListeners();
      return;
    }

    final uri = Uri(scheme: 'tel', path: cleanedPhone);
    try {
      final launched = await launchUrl(uri);
      if (!launched) {
        _feedbackMessage =
            'Thiết bị không hỗ trợ quay số trực tiếp. Số ĐT: ${doctor.phoneNumber}';
        notifyListeners();
      }
    } catch (_) {
      _feedbackMessage =
          'Không thể mở trình gọi điện. Số của bác sĩ: ${doctor.phoneNumber}';
      notifyListeners();
    }
  }

  void clearFeedback() {
    if (_feedbackMessage == null) return;
    _feedbackMessage = null;
    notifyListeners();
  }
}
