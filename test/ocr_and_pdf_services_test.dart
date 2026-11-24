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

  @override
  Future<void> dispose() async {}
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

    test('parseText correctly binds multi-line instructions to the preceding medicine', () {
      const sampleMultiLine = '''
BỆNH VIỆN BẠCH MAI
Khoa Tim Mạch
Bác sĩ điều trị: PGS.TS Nguyễn Quang Tuấn
Chẩn đoán: Tăng huyết áp độ 2, Rối loạn lipid máu
1. Amlodipine 5mg
   Uống 1 viên vào buổi sáng sau ăn no. SL: 30 viên
2. Atorvastatin 20mg
   Tối 1 viên trước khi đi ngủ. SL: 30 viên
3. Aspirin 81mg
   Ngày uống 1 viên sau ăn trưa
      ''';

      final result = ocrService.parseText(sampleMultiLine);

      expect(result.hospital, contains('BỆNH VIỆN BẠCH MAI'));
      expect(result.doctorName, contains('Nguyễn Quang Tuấn'));
      expect(result.diagnosis, contains('Tăng huyết áp'));
      expect(result.medicines.length, equals(3));

      expect(result.medicines[0].name, contains('Amlodipine'));
      expect(result.medicines[0].dosage, contains('5mg'));
      expect(result.medicines[0].instruction, contains('buổi sáng sau ăn no'));

      expect(result.medicines[1].name, contains('Atorvastatin'));
      expect(result.medicines[1].dosage, contains('20mg'));
      expect(result.medicines[1].instruction, contains('trước khi đi ngủ'));

      expect(result.medicines[2].name, contains('Aspirin'));
      expect(result.medicines[2].dosage, contains('81mg'));
      expect(result.medicines[2].instruction, contains('sau ăn trưa'));
    });

    test('parseText accurately parses real BHYT hospital table & pharmacy prescriptions', () {
      const realBhytPrescription = '''
SỞ Y TẾ TP. HỒ CHÍ MINH   Mã số: 019283
BỆNH VIỆN ĐẠI HỌC Y DƯỢC
ĐƠN THUỐC BHYT
Họ và tên: NGUYỄN VĂN AN   Tuổi: 45   Giới tính: Nam
Cân nặng: 62 kg   Số thẻ BHYT: DN4797912345678
Chẩn đoán: J02 - Viêm họng cấp; K21 - Trào ngược dạ dày thực quản
Thuốc điều trị:
1/ Augmentin 1g   14 Viên
Ngày uống 2 lần, mỗi lần 1 viên sau ăn
2/ Alpha Choay 5mg
SL: 20 Viên
Ngày ngậm dưới lưỡi 4 viên chia 2 lần
3/ Gaviscon Dual Action 10ml   15 Gói
Uống 1 gói sau ăn trưa, tối và khi đau
Cộng khoản: 03 khoản
Lời dặn: Kiêng đồ chua cay, tái khám sau 7 ngày.
Ngày 24 tháng 11 năm 2026
Bác sĩ khám bệnh
(Ký, ghi rõ họ tên)
ThS.BS Trần Minh Hoàng
      ''';

      final result = ocrService.parseText(realBhytPrescription);

      expect(result.hospital, equals('BỆNH VIỆN ĐẠI HỌC Y DƯỢC'));
      expect(result.prescriptionType, equals('ĐƠN THUỐC BHYT'));
      expect(result.diagnosis, contains('Viêm họng cấp'));
      expect(result.doctorName, equals('Trần Minh Hoàng'));
      expect(result.advice, contains('Kiêng đồ chua cay'));
      expect(result.medicines.length, equals(3));

      expect(result.medicines[0].name, equals('Augmentin 1g'));
      expect(result.medicines[0].dosage, contains('14 Viên'));
      expect(result.medicines[0].instruction, contains('Ngày uống 2 lần'));

      expect(result.medicines[1].name, equals('Alpha Choay 5mg'));
      expect(result.medicines[1].dosage, contains('20 Viên'));
      expect(result.medicines[1].instruction, contains('ngậm dưới lưỡi'));

      expect(result.medicines[2].name, equals('Gaviscon Dual Action 10ml'));
      expect(result.medicines[2].dosage, contains('15 Gói'));
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
