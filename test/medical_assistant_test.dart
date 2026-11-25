import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_tay_y_te/core/di/injection_container.dart';
import 'package:so_tay_y_te/core/security/secure_storage_helper.dart';
import 'package:so_tay_y_te/core/services/medical_assistant_service.dart';
import 'package:so_tay_y_te/core/services/user_session_manager.dart';
import 'package:so_tay_y_te/data/datasources/local/app_preferences_datasource.dart';
import 'package:so_tay_y_te/domain/entities/medical_event.dart';
import 'package:so_tay_y_te/domain/entities/medicine.dart';
import 'package:so_tay_y_te/domain/entities/prescription.dart';
import 'package:so_tay_y_te/domain/repositories/medical_record_repository.dart';
import 'package:so_tay_y_te/presentation/features/assistant/view/medical_assistant_sheet.dart';
import 'package:so_tay_y_te/presentation/features/assistant/viewmodel/medical_assistant_viewmodel.dart';

class _FakeMedicalRecordRepository implements MedicalRecordRepository {
  final List<MedicalEvent> events;

  _FakeMedicalRecordRepository(this.events);

  @override
  Future<List<MedicalEvent>> getMedicalTimeline({
    String? userId,
    String? memberId,
  }) async {
    return events
        .where((e) => memberId == null || e.memberId == memberId)
        .toList();
  }

  @override
  Future<MedicalEvent?> getMedicalEventById(String id) async => null;

  @override
  Future<void> saveMedicalEvent(MedicalEvent event) async {}

  @override
  Future<void> deleteMedicalEvent(String id) async {}

  @override
  Future<String> exportHealthPdf() async => '';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureStorageHelper secureStorage;
  late AppPreferencesDataSource prefs;
  late _FakeMedicalRecordRepository fakeMedicalRepo;

  final sampleEvents = [
    MedicalEvent(
      id: 'ev_1',
      memberId: 'primary',
      title: 'Khám Nội Tổng Quát',
      date: DateTime(2026, 10, 15),
      type: MedicalEventType.generalCheckup,
      facilityName: 'BV Đại Học Y Dược',
      doctorName: 'BS. Minh',
      diagnosis: 'Viêm mũi dị ứng thời tiết',
      bloodPressure: '118/76',
      heartRate: '74',
      spo2: '98',
      temperature: '36.7',
      prescription: Prescription(
        id: 'rx_1',
        doctorName: 'BS. Minh',
        hospital: 'BV Đại Học Y Dược',
        issuedDate: DateTime.now(),
        durationDays: 14,
        medicines: const [
          Medicine(
            id: 'm_1',
            name: 'Loratadine',
            dosage: '10mg',
            frequency: '1 viên/sáng',
          ),
          Medicine(
            id: 'm_2',
            name: 'Vitamin C',
            dosage: '500mg',
            frequency: '1 viên/trưa',
          ),
        ],
      ),
    ),
    MedicalEvent(
      id: 'ev_2',
      memberId: 'primary',
      title: 'Tiêm Vắc Xin Cúm Mùa',
      date: DateTime(2026, 5, 10),
      type: MedicalEventType.vaccination,
      facilityName: 'VNVC',
      diagnosis: 'Tiêm phòng định kỳ',
    ),
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();

    secureStorage = SecureStorageHelperImpl();
    prefs = AppPreferencesDataSourceImpl(secureStorage: secureStorage);
    fakeMedicalRepo = _FakeMedicalRecordRepository(sampleEvents);

    sl.registerSingleton<SecureStorageHelper>(secureStorage);
    sl.registerSingleton<AppPreferencesDataSource>(prefs);
    sl.registerSingleton<MedicalRecordRepository>(fakeMedicalRepo);

    AppSessionNotifier.instance.resetActiveMember();
    AppSessionNotifier.instance.updateSession(fullName: 'Nguyễn Văn An');
  });

  tearDown(() async {
    await sl.reset();
  });

  group('MedicalAssistantService Hybrid Routing & Privacy Tests', () {
    test('Answers medical record count and latest visit locally offline', () async {
      final service = MedicalAssistantService(secureStorage: secureStorage);
      final reply = await service.answerUserQuery(
        'Thống kê số lượng bệnh án của tôi',
      );

      expect(reply.source, equals(AssistantReplySource.localDatabase));
      expect(reply.suggestedRoute, equals(AssistantQuickRoute.timeline));
      expect(reply.text, contains('2'));
      expect(reply.text, contains('Viêm mũi dị ứng thời tiết'));
      expect(reply.text, contains('BV Đại Học Y Dược'));
    });

    test('Answers active prescriptions and medicines locally offline', () async {
      final service = MedicalAssistantService(secureStorage: secureStorage);
      final reply = await service.answerUserQuery(
        'Đơn thuốc đang uống của tôi gồm những gì?',
      );

      expect(reply.source, equals(AssistantReplySource.localDatabase));
      expect(reply.suggestedRoute, equals(AssistantQuickRoute.prescriptions));
      expect(reply.text, contains('Loratadine'));
      expect(reply.text, contains('Vitamin C'));
    });

    test('Anonymizes PII before calling Gemini API for symptom reference', () async {
      String? capturedSystemPrompt;
      String? capturedUserPayload;

      final service = MedicalAssistantService(
        secureStorage: secureStorage,
        customRequester: ({
          required apiKey,
          required model,
          required systemInstruction,
          required contents,
        }) async {
          capturedSystemPrompt = systemInstruction;
          capturedUserPayload = contents.last['parts'][0]['text'] as String;
          return 'Đây là thông tin tham khảo cho triệu chứng sốt nhẹ và đau họng, không thay thế chẩn đoán bác sĩ.';
        },
      );

      await service.saveApiKey('AIzaTestKey123456');
      await service.saveSelectedModel('gemini-3.8-flash');

      final reply = await service.answerUserQuery(
        'Mình bị sốt nhẹ và đau họng 2 ngày nay thì có sao không?',
      );

      expect(reply.source, equals(AssistantReplySource.geminiAi));
      expect(reply.text, contains('tham khảo'));
      expect(capturedSystemPrompt, contains('TUYỆT ĐỐI KHÔNG khẳng định chẩn đoán'));
      // Verify personal name is NEVER leaked to Gemini API
      expect(capturedUserPayload, isNot(contains('Nguyễn Văn An')));
    });

    test('Uses safe non-diagnostic fallback when Gemini API key is absent', () async {
      final service = MedicalAssistantService(secureStorage: secureStorage);
      final reply = await service.answerUserQuery(
        'Mình bị đau đầu chóng mặt từ sáng',
      );

      expect(reply.source, equals(AssistantReplySource.localSymptomFallback));
      expect(reply.text, contains('Không phải chẩn đoán xác định'));
      expect(reply.text, contains('Cần đi khám ngay nếu'));
    });
  });

  group('MedicalAssistantSheet Widget Tests', () {
    testWidgets('Renders cleanly on narrow screen and handles quick prompt tap', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = MedicalAssistantService(secureStorage: secureStorage);
      final vm = MedicalAssistantViewModel(service: service);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MedicalAssistantSheet(viewModel: vm),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trợ Lý Sổ Tay Y Tế'), findsOneWidget);
      expect(
        find.textContaining('không phải chẩn đoán xác định'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      // Tap quick prompt chip for prescription summary
      final rxChip = find.text('💊 Đơn thuốc đang uống');
      await tester.ensureVisible(rxChip);
      await tester.pumpAndSettle();
      await tester.tap(rxChip);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Loratadine', findRichText: true),
        findsWidgets,
      );
      expect(find.text('Mở Đơn thuốc'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
