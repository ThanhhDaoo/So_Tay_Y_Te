import 'package:flutter/foundation.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/user_session_manager.dart';
import '../../../../core/widgets/safe_avatar_image.dart';
import '../../../../data/datasources/local/elder_care_local_datasource.dart';
import '../../../../data/repositories/elder_care_repository_impl.dart';
import '../../../../domain/entities/daily_health_task.dart';
import '../../../../domain/entities/medication_popup_reminder.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../../domain/repositories/elder_care_repository.dart';
import '../../../../domain/repositories/medical_record_repository.dart';
import 'home_state.dart';

class HomeViewModel extends ChangeNotifier {
  /// Chỉ tự động bật Popup nhắc thuốc tối đa 1 lần mỗi phiên mở ứng dụng để không làm phiền người lớn tuổi.
  static bool hasAutoShownMedicationPopupThisSession = false;

  final ElderCareRepository? _customElderRepo;
  final AuthRepository? _customAuthRepo;
  final MedicalRecordRepository? _customMedicalRepo;

  HomeState _state = const HomeState(isLoading: true);
  int _lastRecordsVer = AppSessionNotifier.instance.medicalRecordsVersion;
  int _lastProfileVer = AppSessionNotifier.instance.profileVersion;

  HomeState get state => _state;

  HomeViewModel({
    ElderCareRepository? elderCareRepository,
    AuthRepository? authRepository,
    MedicalRecordRepository? medicalRecordRepository,
  })  : _customElderRepo = elderCareRepository,
        _customAuthRepo = authRepository,
        _customMedicalRepo = medicalRecordRepository {
    loadDashboard();
    AppSessionNotifier.instance.addListener(_onGlobalSessionChanged);
  }

  void _onGlobalSessionChanged() {
    final recVer = AppSessionNotifier.instance.medicalRecordsVersion;
    final profVer = AppSessionNotifier.instance.profileVersion;
    if (recVer != _lastRecordsVer || profVer != _lastProfileVer) {
      _lastRecordsVer = recVer;
      _lastProfileVer = profVer;
      loadDashboard();
    }
  }

  @override
  void dispose() {
    AppSessionNotifier.instance.removeListener(_onGlobalSessionChanged);
    super.dispose();
  }

  ElderCareRepository? _resolveElderRepo() {
    if (_customElderRepo != null) return _customElderRepo;
    if (sl.isRegistered<ElderCareRepository>()) {
      return sl<ElderCareRepository>();
    }
    if (sl.isRegistered<DatabaseHelper>()) {
      return ElderCareRepositoryImpl(
        localDataSource:
            ElderCareLocalDataSourceImpl(databaseHelper: sl<DatabaseHelper>()),
        medicalRecordRepository: sl.isRegistered<MedicalRecordRepository>()
            ? sl<MedicalRecordRepository>()
            : null,
      );
    }
    return null;
  }

  static String _computeAgeLabel(String? rawDob) {
    if (rawDob == null || rawDob.trim().isEmpty || rawDob == 'Chưa rõ') {
      return '55+ tuổi';
    }
    final yearMatch = RegExp(r'(19|20)\d{2}').firstMatch(rawDob);
    if (yearMatch != null) {
      final birthYear = int.tryParse(yearMatch.group(0)!);
      if (birthYear != null) {
        final age = DateTime.now().year - birthYear;
        if (age > 0 && age <= 120) {
          return '$age tuổi';
        }
      }
    }
    return '55+ tuổi';
  }

  static String _computeBmiSummary(String? hRaw, String? wRaw) {
    final h = double.tryParse((hRaw ?? '').replaceAll(RegExp(r'[^0-9.]'), ''));
    final w = double.tryParse((wRaw ?? '').replaceAll(RegExp(r'[^0-9.]'), ''));
    if (h == null || w == null || h <= 0) return 'Chưa tính BMI';
    final bmi = w / ((h / 100) * (h / 100));
    final label = bmi < 18.5
        ? 'Hơi gầy'
        : (bmi < 24.9 ? 'Cân đối tốt' : (bmi < 29.9 ? 'Hơi thừa cân' : 'Thừa cân'));
    return 'BMI ${bmi.toStringAsFixed(1)} ($label)';
  }

  Future<void> loadDashboard() async {
    try {
      final activeMemberId = AppSessionNotifier.instance.activeMemberId;
      final isPrimary = activeMemberId == 'primary';

      String userId = '';
      String displayName = AppSessionNotifier.instance.activeMemberName ??
          AppSessionNotifier.instance.fullName ??
          'Chủ hồ sơ sức khỏe';
      String ageLabel = '55+ tuổi';
      String genderLabel = 'Chưa rõ';
      String? avatarPath = AppSessionNotifier.instance.avatarUrl;
      String bloodType = 'Chưa rõ';
      String heightStr = '';
      String weightStr = '';
      List<String> conditions = [];
      List<String> allergies = [];

      final authRepo = _customAuthRepo ??
          (sl.isRegistered<AuthRepository>() ? sl<AuthRepository>() : null);
      if (authRepo != null) {
        final session = await authRepo.getActiveSession();
        if (session != null) {
          userId = session.id;
          if (isPrimary) {
            if (session.fullName.trim().isNotEmpty) {
              displayName = session.fullName.trim();
            }
            ageLabel = _computeAgeLabel(session.dateOfBirth);
            if (session.gender != null && session.gender!.trim().isNotEmpty) {
              genderLabel = session.gender!.trim();
            }
            if (session.bloodType != null && session.bloodType!.trim().isNotEmpty) {
              bloodType = session.bloodType!.trim();
            }
            if (session.avatarUrl != null && session.avatarUrl!.isNotEmpty) {
              avatarPath = SafeAvatarHelper.resolveImagePath(session.avatarUrl);
            }
            final details = await authRepo.getUserProfileDetails(session.id);
            if (details != null) {
              final g = (details['gender'] as String?)?.trim() ?? '';
              if (g.isNotEmpty && g != 'Chưa rõ') genderLabel = g;
              heightStr = (details['height'] as String?)?.trim() ?? '';
              weightStr = (details['weight'] as String?)?.trim() ?? '';
              final rawCond = (details['chronic_conditions'] as String?)?.trim() ?? '';
              if (rawCond.isNotEmpty && rawCond != 'Không có') {
                conditions = rawCond
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
              }
              final rawAllergy = (details['allergies'] as String?)?.trim() ?? '';
              if (rawAllergy.isNotEmpty && rawAllergy != 'Không có') {
                allergies = rawAllergy
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
              }
            }
          }
        }
      }

      if (!isPrimary && sl.isRegistered<DatabaseHelper>()) {
        final db = await sl<DatabaseHelper>().database;
        final famRows = await db.query(
          'family_members',
          where: 'id = ?',
          whereArgs: [activeMemberId],
          limit: 1,
        );
        if (famRows.isNotEmpty) {
          final r = famRows.first;
          displayName = (r['name'] as String?) ?? displayName;
          ageLabel = _computeAgeLabel(r['dob'] as String?);
          genderLabel = (r['gender'] as String?) ?? 'Chưa rõ';
          bloodType = (r['blood_type'] as String?) ?? 'Chưa rõ';
          avatarPath = SafeAvatarHelper.resolveImagePath(r['avatar_asset'] as String?);
          heightStr = (r['height'] as String?)?.trim() ?? '';
          weightStr = (r['weight'] as String?)?.trim() ?? '';
          final rawCond = (r['chronic_conditions'] as String?)?.trim() ?? '';
          if (rawCond.isNotEmpty && rawCond != 'Không có') {
            conditions = rawCond
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }
          final rawAllergy = (r['allergies'] as String?)?.trim() ?? '';
          if (rawAllergy.isNotEmpty && rawAllergy != 'Không có') {
            allergies = rawAllergy
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }
        }
      }

      String latestCheckupSummary = 'Chưa có hồ sơ khám bệnh gần đây.';
      final medRepo = _customMedicalRepo ??
          (sl.isRegistered<MedicalRecordRepository>()
              ? sl<MedicalRecordRepository>()
              : null);
      if (medRepo != null) {
        final events = await medRepo.getMedicalTimeline(
          userId: userId.isNotEmpty ? userId : null,
          memberId: activeMemberId,
        );
        if (events.isNotEmpty) {
          final latest = events.first;
          final dStr =
              '${latest.date.day.toString().padLeft(2, '0')}/${latest.date.month.toString().padLeft(2, '0')}/${latest.date.year}';
          latestCheckupSummary =
              '${latest.diagnosis?.isNotEmpty == true ? latest.diagnosis! : latest.title} ($dStr)';
        }
      }

      final elderRepo = _resolveElderRepo();
      var bpComparison = _state.bpComparison;
      var medProgress = _state.medicationProgress;
      var tasks = _state.todayTasks;

      if (elderRepo != null) {
        bpComparison = await elderRepo.getYesterdayTodayBpComparison(
          userId: userId,
          memberId: activeMemberId,
        );
        medProgress = await elderRepo.getTodayMedicationProgress(
          userId: userId,
          memberId: activeMemberId,
        );
        tasks = await elderRepo.getOrCreateTodayTasks(
          userId: userId,
          memberId: activeMemberId,
        );
      }

      final hwParts = <String>[
        if (heightStr.isNotEmpty) 'Cao $heightStr cm',
        if (weightStr.isNotEmpty) 'Nặng $weightStr kg',
      ];

      final shouldPrompt = !hasAutoShownMedicationPopupThisSession &&
          medProgress.nextPendingSlot != null;

      _state = _state.copyWith(
        isLoading: false,
        fullName: displayName,
        ageLabel: ageLabel,
        genderLabel: genderLabel,
        avatarPath: avatarPath,
        memberRoleLabel: isPrimary ? 'Hồ sơ của tôi' : 'Người thân gia đình',
        bpComparison: bpComparison,
        medicationProgress: medProgress,
        todayTasks: tasks,
        shouldAutoPromptMedication: shouldPrompt,
        healthOverview: HomeHealthOverviewSummary(
          bloodType: bloodType,
          heightWeightText: hwParts.isNotEmpty
              ? hwParts.join(' • ')
              : 'Chưa cập nhật chiều cao / cân nặng',
          bmiStatusText: _computeBmiSummary(heightStr, weightStr),
          chronicConditions: conditions,
          allergies: allergies,
          latestCheckupSummary: latestCheckupSummary,
        ),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('[HomeViewModel] loadDashboard error: $e');
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  void markAutoPromptHandled() {
    hasAutoShownMedicationPopupThisSession = true;
    if (_state.shouldAutoPromptMedication) {
      _state = _state.copyWith(shouldAutoPromptMedication: false);
    }
  }

  Future<void> saveManualBloodPressure({
    required int systolic,
    required int diastolic,
    int? heartRate,
    String? note,
  }) async {
    final elderRepo = _resolveElderRepo();
    if (elderRepo == null) return;
    final saved = await elderRepo.saveDailyBloodPressure(
      systolic: systolic,
      diastolic: diastolic,
      heartRate: heartRate,
      source: 'manual',
      note: note,
    );
    await loadDashboard();
    _state = _state.copyWith(
      feedbackMessage:
          'Đã lưu huyết áp hôm nay: ${saved.formattedBp} mmHg (${saved.statusLabelVi})!',
    );
    notifyListeners();
  }

  Future<void> toggleTask(DailyHealthTask task) async {
    final elderRepo = _resolveElderRepo();
    if (elderRepo == null) return;
    await elderRepo.toggleHealthTask(task: task);
    await loadDashboard();
  }

  Future<void> addCustomTask(String title, {String? timeLabel}) async {
    final elderRepo = _resolveElderRepo();
    if (elderRepo == null || title.trim().isEmpty) return;
    await elderRepo.addCustomHealthTask(
      title: title,
      timeLabel: timeLabel,
    );
    await loadDashboard();
    _state = _state.copyWith(
      feedbackMessage: 'Đã thêm công việc mới vào danh sách hôm nay.',
    );
    notifyListeners();
  }

  Future<void> markPopupMedicationTaken(MedicationPopupReminder reminder) async {
    final elderRepo = _resolveElderRepo();
    if (elderRepo == null) return;
    await elderRepo.markMedicationSlotTaken(
      slotId: reminder.slotId,
      isTaken: true,
    );
    await loadDashboard();
    _state = _state.copyWith(
      feedbackMessage:
          'Tuyệt vời! Đã ghi nhận uống xong ${reminder.slotTitle} (${reminder.timeLabel}).',
    );
    notifyListeners();
  }

  Future<void> snoozePopupMedication(MedicationPopupReminder reminder) async {
    final elderRepo = _resolveElderRepo();
    await elderRepo?.snoozeMedicationSlot(reminder: reminder);
    _state = _state.copyWith(
      feedbackMessage:
          'Đã hẹn nhắc lại ${reminder.slotTitle} sau 15 phút nữa.',
    );
    notifyListeners();
  }

  void clearFeedback() {
    if (_state.feedbackMessage == null) return;
    _state = _state.copyWith(clearFeedback: true);
    notifyListeners();
  }
}
