import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../di/injection_container.dart';
import '../security/secure_storage_helper.dart';
import '../../data/datasources/local/app_preferences_datasource.dart';
import '../../domain/entities/medical_event.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/medical_record_repository.dart';
import 'user_session_manager.dart';

enum AssistantReplySource {
  localDatabase,
  geminiAi,
  localSymptomFallback,
}

enum AssistantQuickRoute {
  timeline,
  prescriptions,
  profile,
  documents,
  vitalReports,
}

class AssistantReply {
  final String text;
  final AssistantReplySource source;
  final AssistantQuickRoute? suggestedRoute;
  final String? suggestedRouteLabel;

  const AssistantReply({
    required this.text,
    required this.source,
    this.suggestedRoute,
    this.suggestedRouteLabel,
  });
}

class LocalHealthSnapshot {
  final String memberId;
  final String memberDisplayName;
  final bool isPrimaryMember;
  final String patientCode;
  final String dob;
  final String gender;
  final String bloodType;
  final String height;
  final String weight;
  final String bmiText;
  final List<String> allergies;
  final List<String> chronicConditions;
  final String emergencyContact;
  final bool isPro;
  final int familyMemberCount;
  final int totalEvents;
  final int currentYearEvents;
  final int totalDocuments;
  final Map<MedicalEventType, int> eventsByType;
  final MedicalEvent? latestEvent;
  final int totalPrescriptions;
  final int activePrescriptions;
  final List<String> activeMedicineSummaries;
  final int takenDosesToday;

  const LocalHealthSnapshot({
    required this.memberId,
    required this.memberDisplayName,
    required this.isPrimaryMember,
    required this.patientCode,
    required this.dob,
    required this.gender,
    required this.bloodType,
    required this.height,
    required this.weight,
    required this.bmiText,
    required this.allergies,
    required this.chronicConditions,
    required this.emergencyContact,
    required this.isPro,
    required this.familyMemberCount,
    required this.totalEvents,
    required this.currentYearEvents,
    required this.totalDocuments,
    required this.eventsByType,
    required this.latestEvent,
    required this.totalPrescriptions,
    required this.activePrescriptions,
    required this.activeMedicineSummaries,
    required this.takenDosesToday,
  });

  /// Ngữ cảnh y khoa ĐÃ ẨN DANH (không chứa họ tên, SĐT, mã bệnh nhân, địa chỉ) để gửi kèm khi hỏi triệu chứng.
  String toAnonymizedClinicalContext() {
    final parts = <String>[];
    if (gender.isNotEmpty && gender != 'Chưa rõ') {
      parts.add('Giới tính: $gender');
    }
    if (dob.isNotEmpty && dob != 'Chưa cập nhật' && dob != 'Chưa rõ') {
      // Chỉ trích năm sinh để tính nhóm tuổi, không gửi ngày tháng sinh chi tiết
      final yearMatch = RegExp(r'(19|20)\d{2}').firstMatch(dob);
      if (yearMatch != null) {
        final birthYear = int.tryParse(yearMatch.group(0)!);
        if (birthYear != null) {
          final age = DateTime.now().year - birthYear;
          if (age >= 0 && age <= 120) {
            parts.add('Độ tuổi khoảng: $age tuổi');
          }
        }
      }
    }
    if (bloodType.isNotEmpty && bloodType != 'Chưa rõ') {
      parts.add('Nhóm máu: $bloodType');
    }
    if (allergies.isNotEmpty) {
      parts.add('Tiền sử dị ứng cần lưu ý: ${allergies.join(", ")}');
    }
    if (chronicConditions.isNotEmpty) {
      parts.add('Bệnh nền đang theo dõi: ${chronicConditions.join(", ")}');
    }
    return parts.isEmpty
        ? 'Chưa ghi nhận tiền sử dị ứng hay bệnh nền đặc biệt.'
        : parts.join(' | ');
  }
}

typedef GeminiRequester = Future<String> Function({
  required String apiKey,
  required String model,
  required String systemInstruction,
  required List<Map<String, dynamic>> contents,
});

class MedicalAssistantService {
  static const String _envApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  static const String _envModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.6-flash',
  );

  static const String _secureKeyGeminiApi = 'assistant_gemini_api_key';
  static const String _secureKeyGeminiModel = 'assistant_gemini_model';

  static const List<String> supportedModels = [
    'gemini-3.6-flash',
    'gemini-3.8-flash',
    'gemini-3.5-flash',
    'gemini-2.5-flash',
  ];

  static const String medicalSystemInstruction = '''
Bạn là Trợ lý Sức khỏe thông minh trong ứng dụng "Sổ Tay Y Tế".
NGUYÊN TẮC AN TOÀN Y KHOA BẮT BUỘC:
1. TUYỆT ĐỐI KHÔNG khẳng định chẩn đoán chính xác một bệnh cụ thể từ triệu chứng người dùng mô tả. Luôn giải thích rõ rằng cùng một triệu chứng có thể xuất hiện ở nhiều tình trạng sức khỏe khác nhau.
2. Chỉ nêu 2-4 nhóm nguyên nhân phổ biến mang tính THAM KHẢO để người dùng hiểu và chuẩn bị thông tin khi đi khám.
3. KHÔNG tự ý kê đơn thuốc đặc trị, kháng sinh, corticoid hay liều lượng thuốc kê đơn. Nếu ngữ cảnh có tiền sử dị ứng hoặc bệnh nền, hãy nhắc người dùng lưu ý báo cho bác sĩ/dược sĩ.
4. Hướng dẫn cách theo dõi triệu chứng tại nhà an toàn (nghỉ ngơi, bù nước, đo nhiệt độ/huyết áp...) và đặt 1-2 câu hỏi làm rõ (thời gian khởi phát, mức độ, triệu chứng đi kèm).
5. LUÔN liệt kê mục "⚠️ Dấu hiệu cần đi khám/cấp cứu ngay" (Red Flags) phù hợp với triệu chứng đó.
6. Trình bày bằng tiếng Việt ngắn gọn, rõ ràng, chia gạch đầu dòng dễ đọc trên điện thoại. Kết thúc bằng một câu nhắc ngắn: thông tin chỉ mang tính tham khảo, không thay thế chẩn đoán của bác sĩ.
''';

  final SecureStorageHelper _secureStorage;
  final GeminiRequester? customRequester;

  MedicalAssistantService({
    SecureStorageHelper? secureStorage,
    this.customRequester,
  }) : _secureStorage = secureStorage ??
            (sl.isRegistered<SecureStorageHelper>()
                ? sl<SecureStorageHelper>()
                : SecureStorageHelperImpl());

  Future<String> getConfiguredApiKey() async {
    final saved = await _secureStorage.read(_secureKeyGeminiApi);
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim();
    }
    return _envApiKey.trim();
  }

  Future<bool> hasApiKey() async {
    final key = await getConfiguredApiKey();
    return key.isNotEmpty;
  }

  Future<void> saveApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      await _secureStorage.delete(_secureKeyGeminiApi);
    } else {
      await _secureStorage.write(_secureKeyGeminiApi, trimmed);
    }
  }

  Future<String> getSelectedModel() async {
    final saved = await _secureStorage.read(_secureKeyGeminiModel);
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim();
    }
    return _envModel;
  }

  Future<void> saveSelectedModel(String model) async {
    final trimmed = model.trim();
    if (trimmed.isNotEmpty) {
      await _secureStorage.write(_secureKeyGeminiModel, trimmed);
    }
  }

  /// Đọc dữ liệu trực tiếp từ SQLite & Preferences của chủ tài khoản / thành viên đang chọn.
  Future<LocalHealthSnapshot> loadLocalSnapshot() async {
    final activeMemberId = AppSessionNotifier.instance.activeMemberId;
    final isPrimary = activeMemberId == 'primary';

    String userId = '';
    String memberName = AppSessionNotifier.instance.activeMemberName ??
        AppSessionNotifier.instance.fullName ??
        'Chủ tài khoản';
    String patientCode = 'Chưa cấp mã';
    String dob = 'Chưa cập nhật';
    String gender = 'Chưa rõ';
    String bloodType = 'Chưa rõ';
    String height = '--';
    String weight = '--';
    String bmiText = 'Chưa tính';
    List<String> allergies = [];
    List<String> chronicConditions = [];
    String emergencyContact = 'Chưa cài đặt';
    bool isPro = AppSessionNotifier.instance.isPro;
    int familyCount = 1;
    int totalDocs = 0;
    int takenToday = 0;

    if (sl.isRegistered<AppPreferencesDataSource>()) {
      try {
        final prefs = sl<AppPreferencesDataSource>();
        userId = await prefs.getSessionUserId() ?? '';
        isPro = await prefs.getProStatus();
        final now = DateTime.now();
        final todayKey =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        takenToday = (await prefs.getTakenDoseSlotsForDate(todayKey)).length;
      } catch (_) {}
    }

    if (sl.isRegistered<AuthRepository>()) {
      try {
        final authRepo = sl<AuthRepository>();
        final session = await authRepo.getActiveSession();
        if (session != null) {
          userId = session.id;
          patientCode = session.patientCode;
          if (isPrimary) {
            if (session.fullName.trim().isNotEmpty) {
              memberName = session.fullName.trim();
            }
            if (session.dateOfBirth != null && session.dateOfBirth!.isNotEmpty) {
              dob = _formatDob(session.dateOfBirth!);
            }
            if (session.bloodType != null && session.bloodType!.isNotEmpty) {
              bloodType = session.bloodType!;
            }
            final details = await authRepo.getUserProfileDetails(session.id);
            if (details != null) {
              gender = (details['gender'] as String?)?.trim().isNotEmpty == true
                  ? details['gender'] as String
                  : 'Chưa rõ';
              final rawAllergies = details['allergies'] as String?;
              if (rawAllergies != null &&
                  rawAllergies.trim().isNotEmpty &&
                  rawAllergies != 'Không có') {
                allergies = rawAllergies
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
              }
              final rawConditions = details['chronic_conditions'] as String?;
              if (rawConditions != null &&
                  rawConditions.trim().isNotEmpty &&
                  rawConditions != 'Không có') {
                chronicConditions = rawConditions
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
              }
              final rawIce = details['emergency_contact'] as String?;
              if (rawIce != null &&
                  rawIce.trim().isNotEmpty &&
                  !rawIce.contains('@')) {
                emergencyContact = rawIce.trim();
              }
              final h = (details['height'] as String?)?.trim() ?? '';
              final w = (details['weight'] as String?)?.trim() ?? '';
              if (h.isNotEmpty) height = '$h cm';
              if (w.isNotEmpty) weight = '$w kg';
              bmiText = _computeBmiText(h, w);
            }
          }
        }
      } catch (_) {}
    }

    if (sl.isRegistered<DatabaseHelper>()) {
      try {
        final db = await sl<DatabaseHelper>().database;
        final famRows = userId.isNotEmpty
            ? await db.query(
                'family_members',
                where: 'user_id = ?',
                whereArgs: [userId],
              )
            : await db.query('family_members');
        familyCount = 1 + famRows.length;

        if (!isPrimary) {
          final match = famRows.where((r) => r['id'] == activeMemberId).toList();
          if (match.isNotEmpty) {
            final row = match.first;
            memberName = (row['name'] as String?) ?? memberName;
            dob = (row['dob'] as String?)?.isNotEmpty == true
                ? _formatDob(row['dob'] as String)
                : 'Chưa rõ';
            gender = (row['gender'] as String?) ?? 'Chưa rõ';
            bloodType = (row['blood_type'] as String?) ?? 'Chưa rõ';
            final rawAllergies = (row['allergies'] as String?) ?? '';
            if (rawAllergies.trim().isNotEmpty && rawAllergies != 'Không có') {
              allergies = rawAllergies
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
            }
            final rawConditions = (row['chronic_conditions'] as String?) ?? '';
            if (rawConditions.trim().isNotEmpty && rawConditions != 'Không có') {
              chronicConditions = rawConditions
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
            }
            final h = (row['height'] as String?)?.trim() ?? '';
            final w = (row['weight'] as String?)?.trim() ?? '';
            if (h.isNotEmpty) height = '$h cm';
            if (w.isNotEmpty) weight = '$w kg';
            bmiText = _computeBmiText(h, w);
          }
        }

        final docArgs = <Object?>[];
        final docWhere = <String>[];
        if (userId.isNotEmpty) {
          docWhere.add('user_id = ?');
          docArgs.add(userId);
        }
        if (isPrimary) {
          docWhere.add('(member_id IS NULL OR member_id = "" OR member_id = ?)');
          docArgs.add('primary');
        } else {
          docWhere.add('member_id = ?');
          docArgs.add(activeMemberId);
        }
        totalDocs = Sqflite.firstIntValue(
              await db.rawQuery(
                'SELECT COUNT(*) FROM medical_documents${docWhere.isEmpty ? "" : " WHERE ${docWhere.join(" AND ")}"}',
                docArgs,
              ),
            ) ??
            0;
      } catch (_) {}
    }

    List<MedicalEvent> events = [];
    if (sl.isRegistered<MedicalRecordRepository>()) {
      try {
        events = await sl<MedicalRecordRepository>().getMedicalTimeline(
          userId: userId.isNotEmpty ? userId : null,
          memberId: activeMemberId,
        );
      } catch (_) {}
    }

    events.sort((a, b) => b.date.compareTo(a.date));
    final nowYear = DateTime.now().year;
    final currentYearEvents = events.where((e) => e.date.year == nowYear).length;

    final byType = <MedicalEventType, int>{};
    int totalRx = 0;
    int activeRx = 0;
    final activeMeds = <String>[];

    for (final e in events) {
      byType[e.type] = (byType[e.type] ?? 0) + 1;
      final rx = e.prescription;
      if (rx != null && rx.medicines.isNotEmpty) {
        totalRx++;
        if (!rx.isExpiredByDuration) {
          activeRx++;
          for (final med in rx.medicines) {
            activeMeds.add('${med.name} (${med.dosage} • ${med.frequency})');
          }
        }
      }
    }

    return LocalHealthSnapshot(
      memberId: activeMemberId,
      memberDisplayName: memberName,
      isPrimaryMember: isPrimary,
      patientCode: patientCode,
      dob: dob,
      gender: gender,
      bloodType: bloodType,
      height: height,
      weight: weight,
      bmiText: bmiText,
      allergies: allergies,
      chronicConditions: chronicConditions,
      emergencyContact: emergencyContact,
      isPro: isPro,
      familyMemberCount: familyCount,
      totalEvents: events.length,
      currentYearEvents: currentYearEvents,
      totalDocuments: totalDocs,
      eventsByType: byType,
      latestEvent: events.isNotEmpty ? events.first : null,
      totalPrescriptions: totalRx,
      activePrescriptions: activeRx,
      activeMedicineSummaries: activeMeds,
      takenDosesToday: takenToday,
    );
  }

  static String _formatDob(String raw) {
    final parts = raw.split('-');
    if (parts.length == 3 && parts[0].length == 4) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return raw;
  }

  static String _computeBmiText(String h, String w) {
    final hNum = double.tryParse(h);
    final wNum = double.tryParse(w);
    if (hNum == null || wNum == null || hNum <= 0) return 'Chưa tính';
    final bmi = wNum / ((hNum / 100) * (hNum / 100));
    final status = bmi < 18.5
        ? 'Thiếu cân'
        : (bmi < 24.9 ? 'Bình thường' : (bmi < 29.9 ? 'Tiền béo phì' : 'Béo phì'));
    return '${bmi.toStringAsFixed(1)} ($status)';
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Phân loại ý định người dùng: câu hỏi quản lý dữ liệu cá nhân (chạy Local 100%) hay câu hỏi triệu chứng/sức khỏe.
  Future<AssistantReply> answerUserQuery(
    String rawMessage, {
    List<Map<String, String>> previousTurns = const [],
  }) async {
    final query = rawMessage.trim();
    final q = query.toLowerCase();
    final snap = await loadLocalSnapshot();

    // 1. Nếu câu hỏi rõ ràng về triệu chứng -> ưu tiên luồng Tham khảo Triệu chứng (AI / Local Fallback)
    final isSymptomIntent = _matchesAny(q, const [
      'triệu chứng',
      'bị sốt',
      'sốt cao',
      'sốt nhẹ',
      'đau đầu',
      'nhức đầu',
      'chóng mặt',
      'đau bụng',
      'đau dạ dày',
      'đau bao tử',
      'đau quặn',
      'tiêu chảy',
      'đi cầu lỏng',
      'đi ngoài',
      'táo bón',
      'đầy hơi',
      'khó tiêu',
      'buồn nôn',
      'ói',
      'nôn mửa',
      'đau họng',
      'viêm họng',
      'ho khan',
      'ho có đờm',
      'bị ho',
      'khó thở',
      'tức ngực',
      'đau ngực',
      'mệt mỏi',
      'mất ngủ',
      'nổi mẩn',
      'phát ban',
      'ngứa',
      'đau lưng',
      'đau khớp',
      'cảm cúm',
      'sổ mũi',
      'nghẹt mũi',
      'bệnh gì',
      'có sao không',
      'nguy hiểm không',
    ]);

    if (!isSymptomIntent) {
      final localReply = _tryBuildLocalDataReply(q, snap);
      if (localReply != null) {
        return localReply;
      }
    }

    // 2. Gọi Gemini API nếu đã cấu hình API Key
    final apiKey = await getConfiguredApiKey();
    if (apiKey.isNotEmpty) {
      final preferredModel = await getSelectedModel();
      try {
        final aiText = await _callGeminiWithFallback(
          apiKey: apiKey,
          preferredModel: preferredModel,
          userQuery: query,
          snapshot: snap,
          previousTurns: previousTurns,
        );
        return AssistantReply(
          text: aiText,
          source: AssistantReplySource.geminiAi,
        );
      } catch (e) {
        debugPrint('[MedicalAssistantService] Gemini API error: $e');
        final fallback = _buildOfflineSymptomFallback(
          query,
          snap,
          apiErrorHint: _friendlyApiError(e),
        );
        return fallback;
      }
    }

    // 3. Chưa gắn API Key -> trả lời bằng bộ hướng dẫn tham khảo an toàn offline
    return _buildOfflineSymptomFallback(query, snap);
  }

  AssistantReply? _tryBuildLocalDataReply(String q, LocalHealthSnapshot snap) {
    final asksRecords = _matchesAny(q, const [
      'bệnh án',
      'hồ sơ khám',
      'lần khám',
      'đợt khám',
      'lịch sử khám',
      'khám gần nhất',
      'thống kê',
      'bao nhiêu bệnh',
      'số lượng',
      'tài liệu',
    ]);

    final asksPrescriptions = _matchesAny(q, const [
      'đơn thuốc',
      'toa thuốc',
      'thuốc đang uống',
      'uống thuốc',
      'bao nhiêu thuốc',
      'cữ thuốc',
      'thuốc hôm nay',
    ]);

    final asksProfile = _matchesAny(q, const [
      'thông tin cá nhân',
      'chủ tài khoản',
      'tài khoản của tôi',
      'nhóm máu',
      'dị ứng',
      'bệnh nền',
      'chiều cao',
      'cân nặng',
      'bmi',
      'gia đình',
      'thành viên',
      'người thân',
      'khẩn cấp',
      'hồ sơ của tôi',
      'tôi là ai',
      'gói pro',
      'vault pro',
    ]);

    final asksVitals = _matchesAny(q, const [
      'huyết áp',
      'nhịp tim',
      'spo2',
      'nhiệt độ',
      'sinh hiệu',
      'chỉ số',
    ]);

    // Nếu hỏi tổng hợp cả bệnh án + đơn thuốc + thông tin
    if ((asksRecords && asksPrescriptions) || q.contains('tổng quan')) {
      return AssistantReply(
        text: _formatOverviewSummary(snap),
        source: AssistantReplySource.localDatabase,
        suggestedRoute: AssistantQuickRoute.timeline,
        suggestedRouteLabel: 'Xem Dòng thời gian',
      );
    }

    if (asksPrescriptions) {
      return AssistantReply(
        text: _formatPrescriptionSummary(snap),
        source: AssistantReplySource.localDatabase,
        suggestedRoute: AssistantQuickRoute.prescriptions,
        suggestedRouteLabel: 'Mở Đơn thuốc',
      );
    }

    if (asksRecords) {
      return AssistantReply(
        text: _formatRecordsSummary(snap),
        source: AssistantReplySource.localDatabase,
        suggestedRoute: AssistantQuickRoute.timeline,
        suggestedRouteLabel: 'Mở Bệnh án',
      );
    }

    if (asksVitals) {
      return AssistantReply(
        text: _formatVitalsSummary(snap),
        source: AssistantReplySource.localDatabase,
        suggestedRoute: AssistantQuickRoute.vitalReports,
        suggestedRouteLabel: 'Xem Biểu đồ sinh hiệu',
      );
    }

    if (asksProfile) {
      return AssistantReply(
        text: _formatProfileSummary(snap),
        source: AssistantReplySource.localDatabase,
        suggestedRoute: AssistantQuickRoute.profile,
        suggestedRouteLabel: 'Mở Hồ sơ cá nhân',
      );
    }

    return null;
  }

  String _formatRecordsSummary(LocalHealthSnapshot s) {
    final buf = StringBuffer();
    buf.writeln('📊 **Thống kê bệnh án — ${s.memberDisplayName}**');
    buf.writeln('• Tổng số đợt khám / bệnh án: **${s.totalEvents}** hồ sơ');
    buf.writeln('• Trong năm ${DateTime.now().year}: **${s.currentYearEvents}** đợt khám');
    buf.writeln('• Tài liệu / ảnh xét nghiệm lưu trữ: **${s.totalDocuments}** tệp');

    if (s.eventsByType.isNotEmpty) {
      final parts = <String>[];
      s.eventsByType.forEach((type, count) {
        parts.add('${_eventTypeName(type)}: $count');
      });
      buf.writeln('• Phân loại: ${parts.join(" | ")}');
    }

    if (s.latestEvent != null) {
      final latest = s.latestEvent!;
      buf.writeln('\n🩺 **Lần khám gần nhất (${_formatDate(latest.date)}):**');
      buf.writeln('• Tiêu đề: ${latest.title}');
      if (latest.diagnosis != null && latest.diagnosis!.trim().isNotEmpty) {
        buf.writeln('• Chẩn đoán: ${latest.diagnosis}');
      }
      if (latest.facilityName != null && latest.facilityName!.trim().isNotEmpty) {
        buf.writeln('• Cơ sở y tế: ${latest.facilityName}');
      }
    } else {
      buf.writeln('\nHiện chưa có bản ghi bệnh án nào cho hồ sơ này. Bạn có thể bấm nút "+" ở màn hình Bệnh án để thêm mới.');
    }
    return buf.toString().trim();
  }

  String _formatPrescriptionSummary(LocalHealthSnapshot s) {
    final buf = StringBuffer();
    buf.writeln('💊 **Quản lý đơn thuốc — ${s.memberDisplayName}**');
    buf.writeln('• Tổng số đơn thuốc đã lưu: **${s.totalPrescriptions}** đơn');
    buf.writeln('• Đơn thuốc đang trong đợt uống: **${s.activePrescriptions}** đơn');
    buf.writeln('• Số cữ thuốc đã đánh dấu uống hôm nay: **${s.takenDosesToday}** cữ');

    if (s.activeMedicineSummaries.isNotEmpty) {
      buf.writeln('\n📋 **Danh sách thuốc đang hoạt động:**');
      for (final med in s.activeMedicineSummaries.take(8)) {
        buf.writeln('• $med');
      }
      if (s.activeMedicineSummaries.length > 8) {
        buf.writeln('• ... và ${s.activeMedicineSummaries.length - 8} thuốc khác.');
      }
    } else {
      buf.writeln('\nHiện không có đơn thuốc nào đang trong đợt điều trị.');
    }

    if (s.allergies.isNotEmpty) {
      buf.writeln('\n⚠️ **Cảnh báo dị ứng trong hồ sơ:** ${s.allergies.join(", ")}');
    }
    return buf.toString().trim();
  }

  String _formatProfileSummary(LocalHealthSnapshot s) {
    final buf = StringBuffer();
    final roleLabel = s.isPrimaryMember ? 'Chủ tài khoản (Hồ sơ gốc)' : 'Thành viên gia đình';
    buf.writeln('👤 **Thông tin y tế — ${s.memberDisplayName}**');
    buf.writeln('• Vai trò: $roleLabel');
    if (s.isPrimaryMember) {
      buf.writeln('• Mã hồ sơ: `${s.patientCode}` | Gói: **${s.isPro ? "Vault Pro VIP" : "Gói Free"}**');
      buf.writeln('• Tổng số hồ sơ trong gia đình: **${s.familyMemberCount}** thành viên');
    }
    buf.writeln('• Ngày sinh: ${s.dob} | Giới tính: ${s.gender}');
    buf.writeln('• Nhóm máu: **${s.bloodType}**');
    buf.writeln('• Thể trạng: Cao ${s.height} • Nặng ${s.weight} • BMI: ${s.bmiText}');
    buf.writeln(
      '• Dị ứng ghi nhận: **${s.allergies.isEmpty ? "Chưa ghi nhận" : s.allergies.join(", ")}**',
    );
    buf.writeln(
      '• Bệnh nền đang theo dõi: **${s.chronicConditions.isEmpty ? "Chưa ghi nhận" : s.chronicConditions.join(", ")}**',
    );
    if (s.isPrimaryMember) {
      buf.writeln('• Liên hệ khẩn cấp (ICE): ${s.emergencyContact}');
    }
    return buf.toString().trim();
  }

  String _formatVitalsSummary(LocalHealthSnapshot s) {
    final buf = StringBuffer();
    buf.writeln('❤️ **Chỉ số sinh hiệu gần nhất — ${s.memberDisplayName}**');
    final latest = s.latestEvent;
    if (latest == null) {
      buf.writeln('Chưa có đợt khám nào ghi nhận chỉ số sinh hiệu.');
      return buf.toString().trim();
    }
    buf.writeln('• Ngày đo gần nhất: ${_formatDate(latest.date)}');
    buf.writeln('• Huyết áp: **${latest.bloodPressure?.isNotEmpty == true ? latest.bloodPressure : "Chưa đo"}**');
    buf.writeln('• Nhịp tim: **${latest.heartRate?.isNotEmpty == true ? "${latest.heartRate} bpm" : "Chưa đo"}**');
    buf.writeln('• SpO2: **${latest.spo2?.isNotEmpty == true ? "${latest.spo2}%" : "Chưa đo"}**');
    buf.writeln('• Nhiệt độ: **${latest.temperature?.isNotEmpty == true ? "${latest.temperature} °C" : "Chưa đo"}**');
    return buf.toString().trim();
  }

  String _formatOverviewSummary(LocalHealthSnapshot s) {
    return '${_formatProfileSummary(s)}\n\n${_formatRecordsSummary(s)}\n\n${_formatPrescriptionSummary(s)}';
  }

  static String _eventTypeName(MedicalEventType type) {
    switch (type) {
      case MedicalEventType.generalCheckup:
        return 'Khám bệnh';
      case MedicalEventType.emergency:
        return 'Cấp cứu';
      case MedicalEventType.symptomLog:
        return 'Triệu chứng';
      case MedicalEventType.vaccination:
        return 'Tiêm chủng';
      case MedicalEventType.surgery:
        return 'Phẫu thuật';
    }
  }

  Future<String> _callGeminiWithFallback({
    required String apiKey,
    required String preferredModel,
    required String userQuery,
    required LocalHealthSnapshot snapshot,
    required List<Map<String, String>> previousTurns,
  }) async {
    final anonymizedContext = snapshot.toAnonymizedClinicalContext();
    final contents = <Map<String, dynamic>>[];

    for (final turn in previousTurns.reversed.take(4).toList().reversed) {
      final role = turn['role'] == 'assistant' ? 'model' : 'user';
      final text = turn['text'] ?? '';
      if (text.isNotEmpty) {
        contents.add({
          'role': role,
          'parts': [
            {'text': text},
          ],
        });
      }
    }

    final contextualizedPrompt = '''
[Ngữ cảnh y tế ẩn danh từ hồ sơ hiện tại: $anonymizedContext]
[Thống kê tóm tắt: ${snapshot.totalEvents} bệnh án, ${snapshot.activePrescriptions} đơn thuốc đang dùng]

Câu hỏi của người dùng: $userQuery
''';

    contents.add({
      'role': 'user',
      'parts': [
        {'text': contextualizedPrompt},
      ],
    });

    final modelsToTry = <String>{
      preferredModel,
      'gemini-3.6-flash',
      'gemini-3.8-flash',
      'gemini-3.5-flash',
      'gemini-2.5-flash',
    }.toList();

    Object? lastError;
    for (final model in modelsToTry) {
      try {
        final requester = customRequester ?? _defaultGeminiHttpRequest;
        return await requester(
          apiKey: apiKey,
          model: model,
          systemInstruction: medicalSystemInstruction,
          contents: contents,
        );
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('Không thể kết nối Gemini API.');
  }

  static Future<String> _defaultGeminiHttpRequest({
    required String apiKey,
    required String model,
    required String systemInstruction,
    required List<Map<String, dynamic>> contents,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
    );
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      request.headers.set('x-goog-api-key', apiKey);
      final payload = jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': systemInstruction},
          ],
        },
        'contents': contents,
        'generationConfig': {
          'temperature': 0.35,
          'maxOutputTokens': 4096,
          'thinkingConfig': {
            'thinkingBudget': 256,
          },
        },
      });
      request.add(utf8.encode(payload));
      final response = await request.close().timeout(const Duration(seconds: 25));
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String errMsg = 'HTTP ${response.statusCode}';
        try {
          final parsed = jsonDecode(body) as Map<String, dynamic>;
          final errObj = parsed['error'] as Map<String, dynamic>?;
          if (errObj != null && errObj['message'] != null) {
            errMsg = errObj['message'].toString();
          }
        } catch (_) {}
        throw Exception(errMsg);
      }

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('Gemini không trả về nội dung phù hợp.');
      }
      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final buffer = StringBuffer();
      if (parts != null) {
        for (final p in parts) {
          final partMap = p as Map<String, dynamic>;
          if (partMap['thought'] == true) continue;
          final t = partMap['text'] as String?;
          if (t != null) buffer.write(t);
        }
      }
      final result = buffer.toString().trim();
      if (result.isEmpty) {
        throw Exception('Phản hồi từ Gemini rỗng.');
      }
      return result;
    } finally {
      client.close(force: true);
    }
  }

  AssistantReply _buildOfflineSymptomFallback(
    String query,
    LocalHealthSnapshot snap, {
    String? apiErrorHint,
  }) {
    final q = query.toLowerCase();
    final buf = StringBuffer();

    buf.writeln('🩺 **Tham khảo triệu chứng sơ bộ (Không phải chẩn đoán xác định)**');
    buf.writeln(
      'Lưu ý: Các triệu chứng bên dưới có thể gặp ở nhiều bệnh lý khác nhau, không thể kết luận chính xác một bệnh nếu chưa thăm khám lâm sàng.\n',
    );

    if (_matchesAny(q, const ['khó thở', 'tức ngực', 'đau ngực'])) {
      buf.writeln('• **Nhóm nguyên nhân có thể gặp:** Tình trạng tim mạch, hô hấp (co thắt phế quản, viêm phổi), trào ngược dạ dày thực quản hoặc căng thẳng cấp.');
      buf.writeln('• **⚠️ Dấu hiệu CẤP CỨU ngay (115):** Đau thắt ngực lan lên hàm/tay trái, khó thở tăng nhanh, tím tái, vã mồ hôi lạnh hoặc choáng váng.');
    } else if (_matchesAny(q, const ['sốt', 'ho', 'đau họng', 'sổ mũi', 'cảm'])) {
      buf.writeln('• **Nhóm nguyên nhân thường gặp (tham khảo):** Nhiễm siêu vi đường hô hấp trên (cảm lạnh, cúm), viêm họng/amidan, sốt xuất huyết (nếu sốt cao đột ngột) hoặc kích ứng thời tiết.');
      buf.writeln('• **Theo dõi tại nhà:** Nghỉ ngơi, uống đủ nước/oresol, đo thân nhiệt định kỳ, không tự ý dùng kháng sinh khi chưa có chỉ định bác sĩ.');
      buf.writeln('• **⚠️ Cần đi khám ngay nếu:** Sốt cao > 39°C không hạ, sốt kéo dài quá 48–72 giờ, khó thở, lừ đừ, xuất huyết dưới da hoặc đau đầu dữ dội.');
    } else if (_matchesAny(q, const [
      'đau bụng',
      'đau dạ dày',
      'đau bao tử',
      'đau quặn',
      'tiêu chảy',
      'đi cầu lỏng',
      'đi ngoài',
      'đầy hơi',
      'khó tiêu',
      'buồn nôn',
      'ói',
      'nôn',
    ])) {
      buf.writeln('• **Nhóm nguyên nhân thường gặp (tham khảo):** Rối loạn tiêu hóa, nhiễm khuẩn/siêu vi đường ruột, ngộ độc thực phẩm, viêm dạ dày - đại tràng hoặc viêm ruột thừa (nếu đau khu trú tăng dần).');
      buf.writeln('• **Theo dõi tại nhà:** Bù nước và điện giải (Oresol) từng ngụm nhỏ, ăn thức ăn mềm dễ tiêu, nghỉ ngơi; không tự ý uống thuốc cầm tiêu chảy hoặc giảm đau mạnh làm che lấp triệu chứng bụng ngoại khoa.');
      buf.writeln('• **⚠️ Cần đi khám ngay nếu:** Đau quặn bụng dữ dội hoặc đau khu trú hố chậu phải, bụng cứng, đi ngoài phân có máu/nhầy mủ hoặc phân đen, nôn liên tục không bù được nước, sốt cao > 38.5°C.');
    } else if (_matchesAny(q, const ['đau đầu', 'nhức đầu', 'chóng mặt', 'mất ngủ'])) {
      buf.writeln('• **Nhóm nguyên nhân thường gặp (tham khảo):** Đau đầu căng cơ (stress, thiếu ngủ), đau nửa đầu (Migraine), thay đổi huyết áp, thiếu nước hoặc viêm xoang.');
      buf.writeln('• **Theo dõi tại nhà:** Nghỉ ngơi nơi yên tĩnh, đo kiểm tra huyết áp, hạn chế màn hình và thức uống chứa caffeine.');
      buf.writeln('• **⚠️ Cần đi khám ngay nếu:** Đau đầu sét đánh đột ngột dữ dội, kèm yếu tê tay chân, nói đớ, nhìn mờ, cứng gáy hoặc sốt cao.');
    } else {
      buf.writeln('• Với mô tả hiện tại, triệu chứng có thể liên quan đến nhiều nguyên nhân khác nhau nên chưa thể định hướng cụ thể.');
      buf.writeln('• Bạn nên ghi nhận thêm: **thời điểm bắt đầu**, **mức độ nặng nhẹ**, **nhiệt độ/huyết áp** vào mục **Thêm Bệnh Án** để trình bác sĩ khi thăm khám.');
      buf.writeln('• **⚠️ Cần đi khám sớm nếu:** Triệu chứng tiến triển nặng nhanh, sốt cao, khó thở, đau dữ dội hoặc ảnh hưởng sinh hoạt.');
    }

    if (snap.allergies.isNotEmpty || snap.chronicConditions.isNotEmpty) {
      buf.writeln('\n📋 **Lưu ý từ hồ sơ của bạn:**');
      if (snap.allergies.isNotEmpty) {
        buf.writeln('• Dị ứng ghi nhận: **${snap.allergies.join(", ")}** (cần báo cho bác sĩ/dược sĩ trước khi dùng thuốc).');
      }
      if (snap.chronicConditions.isNotEmpty) {
        buf.writeln('• Bệnh nền: **${snap.chronicConditions.join(", ")}**.');
      }
    }

    if (apiErrorHint != null) {
      buf.writeln('\n(Tạm thời hiển thị hướng dẫn tham khảo nội bộ do kết nối AI gián đoạn: $apiErrorHint).');
    } else {
      buf.writeln('\nThông tin trên chỉ mang tính tham khảo ban đầu, không thay thế việc thăm khám trực tiếp với bác sĩ.');
    }

    return AssistantReply(
      text: buf.toString().trim(),
      source: AssistantReplySource.localSymptomFallback,
    );
  }

  static String _friendlyApiError(Object e) {
    final msg = e.toString().replaceFirst('Exception: ', '');
    if (msg.contains('API_KEY_INVALID') || msg.contains('API key not valid')) {
      return 'API Key không hợp lệ';
    }
    if (msg.contains('429') || msg.toLowerCase().contains('quota')) {
      return 'Vượt giới hạn lượt gọi miễn phí trong phút, hãy thử lại sau ít giây';
    }
    if (msg.contains('SocketException')) {
      return 'Không có kết nối mạng';
    }
    return msg.length > 90 ? '${msg.substring(0, 90)}...' : msg;
  }

  static String _normalizeVietnamese(String input) {
    var str = input.toLowerCase();
    const vietnameseMap = <String, String>{
      'à': 'a', 'á': 'a', 'ạ': 'a', 'ả': 'a', 'ã': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ậ': 'a', 'ẩ': 'a', 'ẫ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ặ': 'a', 'ẳ': 'a', 'ẵ': 'a',
      'è': 'e', 'é': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ệ': 'e', 'ể': 'e', 'ễ': 'e',
      'ì': 'i', 'í': 'i', 'ị': 'i', 'ỉ': 'i', 'ĩ': 'i',
      'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ỏ': 'o', 'õ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ộ': 'o', 'ổ': 'o', 'ỗ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ợ': 'o', 'ở': 'o', 'ỡ': 'o',
      'ù': 'u', 'ú': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ự': 'u', 'ử': 'u', 'ữ': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỵ': 'y', 'ỷ': 'y', 'ỹ': 'y',
      'đ': 'd',
    };
    final buffer = StringBuffer();
    for (final rune in str.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(vietnameseMap[ch] ?? ch);
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _matchesAny(String text, List<String> keywords) {
    final lower = text.toLowerCase();
    final normalizedText = ' ${_normalizeVietnamese(lower)} ';
    for (final kw in keywords) {
      if (lower.contains(kw)) return true;
      final normalizedKw = _normalizeVietnamese(kw);
      if (normalizedKw.isNotEmpty &&
          normalizedText.contains(' $normalizedKw ')) {
        return true;
      }
    }
    return false;
  }
}
