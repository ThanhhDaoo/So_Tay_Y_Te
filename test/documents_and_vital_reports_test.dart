import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_tay_y_te/core/di/injection_container.dart';
import 'package:so_tay_y_te/core/services/ocr_service.dart';
import 'package:so_tay_y_te/domain/entities/medical_event.dart';
import 'package:so_tay_y_te/domain/entities/medicine.dart';
import 'package:so_tay_y_te/domain/entities/prescription.dart';
import 'package:so_tay_y_te/domain/entities/user_account.dart';
import 'package:so_tay_y_te/domain/repositories/auth_repository.dart';
import 'package:so_tay_y_te/domain/repositories/medical_record_repository.dart';
import 'package:so_tay_y_te/presentation/features/documents/view/documents_screen.dart';
import 'package:so_tay_y_te/presentation/features/documents/view/widgets/ai_ocr_scanner_modal.dart';
import 'package:so_tay_y_te/presentation/features/documents/viewmodel/documents_state.dart';
import 'package:so_tay_y_te/presentation/features/documents/viewmodel/documents_viewmodel.dart';
import 'package:so_tay_y_te/presentation/features/vital_reports/viewmodel/vital_reports_viewmodel.dart';

class MockTestOcrService implements OcrService {
  @override
  Future<String?> pickImage({required ImageSource source}) async => 'assets/images/img_doc_blood_test.png';

  @override
  Future<ParsedPrescriptionResult?> processPrescriptionImage(String imagePath) async {
    return parseText('Bệnh viện Bạch Mai\nBS. Nguyễn Hoàng Nam\nChẩn đoán: Viêm loét dạ dày\n1. Panadol 500mg 2 viên/ngày\n2. Cefuroxim 500mg 2 viên/ngày');
  }

  @override
  ParsedPrescriptionResult parseText(String text, {String? imagePath}) {
    return const ParsedPrescriptionResult(
      rawText: 'Mock OCR Text',
      doctorName: 'BS. Nguyễn Hoàng Nam',
      hospital: 'Bệnh viện Bạch Mai',
      diagnosis: 'Viêm loét dạ dày',
      medicines: [
        ParsedMedicineItem(name: 'Panadol 500mg', dosage: '500mg', instruction: '2 viên/ngày'),
        ParsedMedicineItem(name: 'Cefuroxim 500mg', dosage: '500mg', instruction: '2 viên/ngày'),
      ],
      imagePath: 'assets/images/img_doc_blood_test.png',
    );
  }

  @override
  Future<void> dispose() async {}
}

class MockMedicalRepoWithData implements MedicalRecordRepository {
  final List<MedicalEvent> events = [];

  MockMedicalRepoWithData() {
    events.add(
      MedicalEvent(
        id: 'rec_01',
        title: 'Khám Dạ Dày',
        description: 'Đau bụng sau ăn',
        date: DateTime(2024, 4, 18),
        type: MedicalEventType.generalCheckup,
        facilityName: 'BV Vinmec Central Park',
        doctorName: 'BS. Hùng',
        bloodPressure: '125/82',
        heartRate: '75',
        attachments: const ['assets/images/img_doc_endoscopy.png'],
        prescription: Prescription(
          id: 'rx_01',
          doctorName: 'BS. Hùng',
          hospital: 'BV Vinmec',
          issuedDate: DateTime(2024, 4, 18),
          medicines: const [
            Medicine(id: 'm1', name: 'Nexium 40mg', dosage: '40mg', frequency: '1 viên/ngày'),
          ],
        ),
      ),
    );
    events.add(
      MedicalEvent(
        id: 'rec_02',
        title: 'Tái Khám Huyết Áp',
        description: 'Theo dõi chỉ số',
        date: DateTime(2024, 4, 25),
        type: MedicalEventType.generalCheckup,
        facilityName: 'BV Bạch Mai',
        doctorName: 'BS. Tuấn',
        bloodPressure: '118/76',
        heartRate: '70',
        attachments: const ['assets/images/img_doc_blood_test.png'],
      ),
    );
  }

  @override
  Future<void> saveMedicalEvent(MedicalEvent event) async {
    events.add(event);
  }

  @override
  Future<MedicalEvent?> getMedicalEventById(String id) async {
    return events.firstWhere((e) => e.id == id, orElse: () => events.first);
  }

  @override
  Future<List<MedicalEvent>> getMedicalTimeline({String? userId, String? memberId}) async => events;

  @override
  Future<void> deleteMedicalEvent(String id) async {
    events.removeWhere((e) => e.id == id);
  }

  @override
  Future<String> exportHealthPdf() async => 'dummy.pdf';
}

class MockAuthRepoForVitals implements AuthRepository {
  final UserAccount user = UserAccount(
    id: 'usr_vital_test',
    patientCode: 'STYT-998877',
    fullName: 'Lê Minh Quân',
    primaryContact: '0912345678',
    passwordHash: '',
    salt: '',
    dateOfBirth: '1988-12-10',
    bloodType: 'B+',
    createdAt: DateTime.now(),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<UserAccount?> getActiveSession() async => user;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  group('Phase 2: Medical Documents Vault Tests', () {
    test('DocumentsViewModel loads documents from medical events attachments and updates storage', () async {
      final mockRepo = MockMedicalRepoWithData();
      final vm = DocumentsViewModel(repository: mockRepo);
      await vm.loadDocuments();

      expect(vm.state.totalDocCount, equals(2));
      expect(vm.state.usedStorageMb, equals(4));
      expect(vm.state.documents.length, equals(2));

      // Test category selection
      vm.selectCategory(DocumentCategory.endoscopy);
      expect(vm.state.selectedCategory, equals(DocumentCategory.endoscopy));

      // Test viewer tip dismissal
      expect(vm.state.showViewerTip, isTrue);
      vm.dismissViewerTip();
      expect(vm.state.showViewerTip, isFalse);
    });

    testWidgets('DocumentsScreen renders storage banner, filters, and dynamic cards', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DocumentsScreen(showBottomNav: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kho Tài Liệu'), findsOneWidget);
      expect(find.text('Quét Toa Thuốc Thông Minh'), findsOneWidget);
      expect(find.text('PHÂN LOẠI TÀI LIỆU'), findsOneWidget);
      expect(find.text('Tài Liệu Gần Đây'), findsOneWidget);
    });

    testWidgets('AiOcrScannerModal triggers scan with OcrService and displays extracted findings', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool completed = false;
      final ocrService = MockTestOcrService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  AiOcrScannerModal.show(
                    ctx,
                    ocrService: ocrService,
                    onScanComplete: () => completed = true,
                  );
                },
                child: const Text('Open Scanner'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap to open modal
      await tester.tap(find.text('Open Scanner'));
      await tester.pumpAndSettle();

      expect(find.text('AI OCR Scanner Pro'), findsOneWidget);
      expect(find.text('Chụp Quét'), findsOneWidget);
      expect(find.text('Chọn từ album'), findsOneWidget);

      // Trigger scan from album
      await tester.tap(find.text('Chọn từ album'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('Trích Xuất Thành Công (100%)'), findsOneWidget);
      expect(find.text('Lưu Vào Kho Tài Liệu'), findsOneWidget);

      // Tap save
      await tester.tap(find.text('Lưu Vào Kho Tài Liệu'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });
  });

  group('Phase 2: Vital Reports & Telemetry Chart Tests', () {
    test('VitalReportsViewModel loads dynamic vitals and patient profile from repository', () async {
      final mockRepo = MockMedicalRepoWithData();
      final mockAuth = MockAuthRepoForVitals();

      final vm = VitalReportsViewModel(
        repository: mockRepo,
        authRepository: mockAuth,
      );
      await vm.loadClinicalData();

      expect(vm.state.patientName, equals('Lê Minh Quân'));
      expect(vm.state.patientNationalId, equals('STYT-998877'));
      expect(vm.state.patientBloodGroup, contains('B+'));

      // Verify vitals chart points parsed from real events (125/82 and 118/76)
      expect(vm.state.chartPoints.length, equals(2));
      expect(vm.state.chartPoints.last.systolic, equals(118));
      expect(vm.state.chartPoints.last.diastolic, equals(76));
      expect(vm.state.latestValue, equals('118/76'));

      // Verify active prescriptions summary loaded from prescription
      expect(vm.state.activePrescriptions.length, equals(1));
      expect(vm.state.activePrescriptions.first.name, equals('Nexium 40mg'));

      // Verify actions
      await vm.exportPdf();
      expect(vm.state.notificationMessage, contains('thành công'));

      await vm.printAirPrint();
      expect(vm.state.notificationMessage, contains('thành công'));

      await vm.sendDoctor();
      expect(vm.state.notificationMessage, contains('Bác sĩ'));

      vm.clearNotification();
      expect(vm.state.notificationMessage, isNull);
    });
  });
}
