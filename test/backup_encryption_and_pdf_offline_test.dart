import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_tay_y_te/core/security/backup_cipher.dart';
import 'package:so_tay_y_te/core/services/pdf_report_service.dart';
import 'package:so_tay_y_te/domain/entities/medical_event.dart';
import 'package:so_tay_y_te/domain/entities/medicine.dart';
import 'package:so_tay_y_te/domain/entities/prescription.dart';
import 'package:so_tay_y_te/domain/entities/user_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AES-256-GCM Backup Encryption & Offline Vietnamese PDF Tests', () {
    test('BackupCipher encrypts sensitive medical JSON into STYT_ENC_V2 ciphertext without leaking plaintext', () {
      final rawMap = <String, dynamic>{
        'version': 2,
        'app': 'So_Tay_Y_Te',
        'owner_user_id': 'usr_secure_01',
        'medical_events': [
          {
            'id': '99999999-1111-4222-8333-444444444444',
            'title': 'Xét nghiệm HIV/Viêm gan B bảo mật',
            'diagnosis': 'Âm tính - Hồ sơ nhạy cảm',
          },
        ],
      };

      final encryptedEnvelope = BackupCipher.encryptJsonPayload(
        jsonEncode(rawMap),
        passphrase: 'MatKhauSaoLuuCucManh@2026',
      );

      // Không được lộ chuỗi nhạy cảm dưới dạng plaintext trong file xuất ra
      expect(encryptedEnvelope.contains('Xét nghiệm HIV'), isFalse);
      expect(encryptedEnvelope.contains('Âm tính - Hồ sơ nhạy cảm'), isFalse);

      final parsedEnvelope = jsonDecode(encryptedEnvelope) as Map<String, dynamic>;
      expect(parsedEnvelope['magic'], equals(BackupCipher.envelopeMagic));
      expect(parsedEnvelope['alg'], equals('AES-256-GCM'));

      // Giải mã đúng mật khẩu trả về nguyên vẹn dữ liệu
      final decrypted = BackupCipher.decryptToMap(
        encryptedEnvelope,
        passphrase: 'MatKhauSaoLuuCucManh@2026',
      );
      expect(decrypted['owner_user_id'], equals('usr_secure_01'));
      final events = decrypted['medical_events'] as List<dynamic>;
      expect((events.first as Map<String, dynamic>)['title'], equals('Xét nghiệm HIV/Viêm gan B bảo mật'));
    });

    test('BackupCipher rejects wrong passphrase and tampered ciphertext', () {
      final encryptedEnvelope = BackupCipher.encryptJsonPayload(
        jsonEncode({'app': 'So_Tay_Y_Te', 'secret': 'Dữ liệu y tế'}),
        passphrase: 'CorrectPassword#123',
      );

      // Sai mật khẩu -> ném FormatException
      expect(
        () => BackupCipher.decryptToMap(
          encryptedEnvelope,
          passphrase: 'WrongPassword#999',
        ),
        throwsA(isA<FormatException>()),
      );

      // Giả mạo byte trong ciphertext -> GCM authentication tag phát hiện và từ chối
      final map = jsonDecode(encryptedEnvelope) as Map<String, dynamic>;
      final cipherBytes = base64Decode(map['ciphertext'] as String);
      cipherBytes[0] ^= 0xFF;
      map['ciphertext'] = base64Encode(cipherBytes);

      expect(
        () => BackupCipher.decryptToMap(
          jsonEncode(map),
          passphrase: 'CorrectPassword#123',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('PdfReportServiceImpl generates valid PDF offline using bundled Roboto TTF fonts with Vietnamese diacritics', () async {
      final pdfService = PdfReportServiceImpl();
      final sampleEvent = MedicalEvent(
        id: '77777777-8888-4999-8000-111111111111',
        title: 'Khám Chuyên Khoa Tiêu Hóa — Bệnh Viện Đại Học Y Dược',
        description: 'Đau thượng vị âm ỉ, ợ chua sau ăn tối.',
        date: DateTime(2026, 8, 19, 9, 30),
        type: MedicalEventType.generalCheckup,
        facilityName: 'Bệnh viện Đại học Y Dược TP.HCM',
        doctorName: 'PGS.TS Nguyễn Văn Hiếu',
        diagnosis: 'Trào ngược dạ dày thực quản độ A (GERD)',
        bloodPressure: '118/76',
        heartRate: '72',
        spo2: '99',
        temperature: '36.6',
        prescription: Prescription(
          id: 'rx_pdf_1',
          doctorName: 'PGS.TS Nguyễn Văn Hiếu',
          issuedDate: DateTime(2026, 8, 19),
          durationDays: 14,
          medicines: const [
            Medicine(
              id: 'm1',
              name: 'Nexium Mups 40mg',
              dosage: '1 viên',
              frequency: 'Uống sáng trước ăn 30 phút',
            ),
          ],
        ),
      );

      final profile = UserProfile(
        id: 'usr_pdf',
        fullName: 'Đào Thanh Tùng',
        dateOfBirth: DateTime(1995, 4, 15),
        bloodType: 'O+',
      );

      final pdfBytes = await pdfService.generateMedicalRecordPdf(
        record: sampleEvent,
        patientProfile: profile,
      );

      // Kiểm tra header magic %PDF- và kích thước nhúng font TTF tiếng Việt hợp lệ
      expect(pdfBytes.length, greaterThan(2000));
      final headerAscii = ascii.decode(pdfBytes.sublist(0, 5), allowInvalid: true);
      expect(headerAscii, equals('%PDF-'));
    });
  });
}
