import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:so_tay_y_te/core/services/ocr_service.dart';
import 'package:so_tay_y_te/core/services/pdf_report_service.dart';
import 'package:so_tay_y_te/domain/entities/medical_event.dart';
import 'package:so_tay_y_te/domain/entities/medicine.dart';
import 'package:so_tay_y_te/domain/entities/prescription.dart';
import 'package:so_tay_y_te/domain/entities/user_profile.dart';
import 'package:so_tay_y_te/presentation/features/prescriptions/view/widgets/prescription_ocr_result_modal.dart';
import 'package:so_tay_y_te/presentation/features/record_detail/view/record_detail_screen.dart';

class MockOcrService implements OcrService {
  @override
  Future<String?> pickImage({required ImageSource source}) async => '/mock/prescription.jpg';

  @override
  Future<ParsedPrescriptionResult?> processPrescriptionImage(String imagePath) async {
    return parseText(
      'BỆNH VIỆN BẠCH MAI\n'
      'Bác sĩ: GS.TS Nguyễn Lân Việt\n'
      'Chẩn đoán: Tăng huyết áp nguyên phát độ 2\n'
      '1. Amlodipine 5mg: 1 viên uống buổi sáng\n'
      '2. Losartan 50mg: 1 viên uống sau ăn\n',
      imagePath: imagePath,
    );
  }

  @override
  ParsedPrescriptionResult parseText(String text, {String? imagePath}) {
    final service = OcrServiceImpl();
    return service.parseText(text, imagePath: imagePath);
  }
}

class MockPdfReportService implements PdfReportService {
  bool printCalled = false;
  bool shareCalled = false;

  @override
  Future<Uint8List> generateMedicalRecordPdf({
    required MedicalEvent record,
    UserProfile? patientProfile,
  }) async {
    // Return standard dummy PDF header bytes
    return Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]);
  }

  @override
  Future<void> printRecord({
    required MedicalEvent record,
    UserProfile? patientProfile,
  }) async {
    printCalled = true;
  }

  @override
  Future<void> shareRecordPdf({
    required MedicalEvent record,
    UserProfile? patientProfile,
  }) async {
    shareCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Module 4: AI OCR Prescription Parser Tests', () {
    late OcrService ocrService;

    setUp(() {
      ocrService = OcrServiceImpl();
    });

    test('parseText correctly extracts hospital, doctor, diagnosis and medication list', () {
      const sampleOcrText = '''
BỆNH VIỆN ĐA KHOA QUỐC TẾ VINMEC
Khoa Nội Tổng Hợp
Bác sĩ: BS. CKII Lê Hoàng Tuấn
Chẩn đoán: Viêm loét dạ dày tá tràng Hp dương tính
Đơn thuốc điều trị:
1. Nexium Mups 40mg: 1 viên uống trước ăn sáng 30 phút
2. Amoxicillin 500mg: 2 viên uống sau ăn no
3. Klacid (Clarithromycin) 500mg: 1 viên uống sau ăn tối
      ''';

      final result = ocrService.parseText(sampleOcrText);

      expect(result.hospital, contains('BỆNH VIỆN ĐA KHOA QUỐC TẾ VINMEC'));
      expect(result.doctorName, contains('Lê Hoàng Tuấn'));
      expect(result.diagnosis, contains('Viêm loét dạ dày tá tràng'));
      expect(result.medicines.length, equals(3));

      expect(result.medicines[0].name, contains('Nexium Mups'));
      expect(result.medicines[0].dosage, contains('40mg'));
      expect(result.medicines[0].instruction, contains('uống trước ăn sáng'));

      expect(result.medicines[1].name, contains('Amoxicillin'));
      expect(result.medicines[1].dosage, contains('500mg'));

      expect(result.medicines[2].name, contains('Klacid'));
      expect(result.medicines[2].dosage, contains('500mg'));
    });

    testWidgets('PrescriptionOcrResultModal triggers scanning and displays parsed medicines',
        (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      ParsedPrescriptionResult? capturedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrescriptionOcrResultModal(
              ocrService: MockOcrService(),
              onApplyResult: (r) => capturedResult = r,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quét Toa Thuốc Bằng AI'), findsOneWidget);
      expect(find.text('Chụp Camera'), findsOneWidget);
      expect(find.text('Chọn Ảnh'), findsOneWidget);

      // Tap Chụp Camera
      await tester.tap(find.text('Chụp Camera'));
      await tester.pumpAndSettle();

      // Verify extracted contents
      expect(find.text('BỆNH VIỆN BẠCH MAI'), findsOneWidget);
      expect(find.textContaining('Nguyễn Lân Việt'), findsOneWidget);
      expect(find.textContaining('Amlodipine'), findsOneWidget);
      expect(find.textContaining('Losartan'), findsOneWidget);
      expect(find.text('Lưu Vào Lịch Uống Thuốc'), findsOneWidget);

      // Tap confirm button
      await tester.tap(find.text('Lưu Vào Lịch Uống Thuốc'));
      await tester.pumpAndSettle();

      expect(capturedResult, isNotNull);
      expect(capturedResult!.medicines.length, equals(2));
    });
  });

  group('Module 5: Medical PDF Generation & Print Service Tests', () {
    late PdfReportService realPdfService;
    late MockPdfReportService mockPdfService;

    setUp(() {
      realPdfService = PdfReportServiceImpl();
      mockPdfService = MockPdfReportService();
    });

    test('generateMedicalRecordPdf produces valid A4 PDF binary with %PDF- header', () async {
      final sampleRecord = MedicalEvent(
        id: 'REC-TEST-001',
        title: 'Khám Sức Khỏe Định Kỳ Doanh Nghiệp',
        description: 'Tất cả chỉ số lâm sàng bình thường, men gan hơi cao nhẹ.',
        date: DateTime(2024, 4, 18),
        type: MedicalEventType.generalCheckup,
        prescription: Prescription(
          id: 'RX-TEST-001',
          doctorName: 'BS. CKII Lê Hoàng Tuấn',
          hospital: 'Bệnh viện Vinmec',
          issuedDate: DateTime(2024, 4, 18),
          medicines: const [
            Medicine(id: '1', name: 'Boganic Forte', dosage: '2 viên/ngày', frequency: 'Sau ăn no'),
          ],
        ),
      );

      final sampleProfile = const UserProfile(
        id: 'P-01',
        fullName: 'Nguyễn Thu Trang',
        bloodType: 'O+',
        emergencyContact: '0988 123 456',
        allergies: ['Penicillin'],
      );

      final pdfBytes = await realPdfService.generateMedicalRecordPdf(
        record: sampleRecord,
        patientProfile: sampleProfile,
      );

      expect(pdfBytes.length, greaterThan(100));
      // Standard PDF magic header: %PDF-
      expect(pdfBytes[0], equals(0x25)); // '%'
      expect(pdfBytes[1], equals(0x50)); // 'P'
      expect(pdfBytes[2], equals(0x44)); // 'D'
      expect(pdfBytes[3], equals(0x46)); // 'F'
    });

    testWidgets('RecordDetailScreen buttons trigger PDF printing and sharing', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: RecordDetailScreen(
            recordId: 'REC-2024-0418',
            pdfReportService: mockPdfService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Test top PDF icon button
      final pdfIconBtn = find.byIcon(Icons.picture_as_pdf_outlined);
      expect(pdfIconBtn, findsOneWidget);
      await tester.tap(pdfIconBtn);
      await tester.pumpAndSettle();
      expect(mockPdfService.printCalled, isTrue);

      // 2. Test top Share button
      final shareIconBtn = find.byIcon(Icons.share_outlined);
      expect(shareIconBtn, findsOneWidget);
      await tester.tap(shareIconBtn);
      await tester.pumpAndSettle();
      expect(mockPdfService.shareCalled, isTrue);

      // 3. Test bottom "Xuất Bản PDF" button
      final bottomExportBtn = find.text('Xuất Bản PDF');
      expect(bottomExportBtn, findsOneWidget);
      mockPdfService.printCalled = false; // Reset
      await tester.tap(bottomExportBtn);
      await tester.pumpAndSettle();
      expect(mockPdfService.printCalled, isTrue);
    });
  });
}
