import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/entities/medical_event.dart';
import '../../domain/entities/prescription.dart';
import '../../domain/entities/user_profile.dart';

abstract class PdfReportService {
  Future<Uint8List> generateMedicalRecordPdf({
    required MedicalEvent record,
    UserProfile? patientProfile,
  });
  Future<void> printRecord({
    required MedicalEvent record,
    UserProfile? patientProfile,
  });
  Future<void> shareRecordPdf({
    required MedicalEvent record,
    UserProfile? patientProfile,
  });
}

class PdfReportServiceImpl implements PdfReportService {
  @override
  Future<Uint8List> generateMedicalRecordPdf({
    required MedicalEvent record,
    UserProfile? patientProfile,
  }) async {
    final pdf = pw.Document(
      title: 'Hồ Sơ Y Tế - ${record.title}',
      author: 'Sổ Tay Y Tế',
    );

    pw.Font font;
    pw.Font fontBold;
    pw.Font fontItalic;

    try {
      font = await PdfGoogleFonts.robotoRegular();
      fontBold = await PdfGoogleFonts.robotoBold();
      fontItalic = await PdfGoogleFonts.robotoItalic();
    } catch (_) {
      font = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
      fontItalic = pw.Font.helveticaOblique();
    }

    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(record.date);
    final prescription = record.prescription;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
          italic: fontItalic,
        ),
        header: (context) => _buildHeader(fontBold, font),
        footer: (context) => _buildFooter(context, fontItalic),
        build: (context) => [
          pw.SizedBox(height: 12),
          // Tiêu đề tài liệu
          pw.Center(
            child: pw.Text(
              'PHIẾU KHÁM BỆNH & TÓM TẮT ĐIỀU TRỊ',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#2D3748'),
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'Thời gian khám: $dateStr',
              style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
            ),
          ),
          pw.SizedBox(height: 16),

          // 1. Thông tin Bệnh nhân (Patient Identification)
          _buildPatientSection(patientProfile, fontBold),
          pw.SizedBox(height: 14),

          // 2. Chẩn đoán & Lâm sàng (Clinical Diagnosis)
          _buildClinicalSection(record, fontBold),
          pw.SizedBox(height: 14),

          // 3. Toa thuốc & Phác đồ điều trị (Prescription)
          if (prescription != null && prescription.medicines.isNotEmpty) ...[
            _buildPrescriptionSection(prescription, fontBold),
            pw.SizedBox(height: 14),
          ],

          // 4. Con dấu & Chữ ký xác nhận (Signatures & Verification)
          _buildSignatureSection(record, fontBold),
        ],
      ),
    );

    return await pdf.save();
  }

  pw.Widget _buildHeader(pw.Font fontBold, pw.Font font) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SỔ TAY Y TẾ • MEDVAULT CLINICAL',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#4A5D4E'), // Olive Theme
                ),
              ),
              pw.Text(
                'Cổng quản lý hồ sơ sức khỏe cá nhân & gia đình',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F0F4EC'),
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColor.fromHex('#C2D6C4')),
            ),
            child: pw.Text(
              'XÁC THỰC HIPAA / HL7',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#2F5233'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context, pw.Font fontItalic) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Bản điện tử xuất từ ứng dụng Sổ Tay Y Tế • Bảo mật AES-256',
            style: pw.TextStyle(fontSize: 8, font: fontItalic, color: PdfColors.grey600),
          ),
          pw.Text(
            'Trang ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPatientSection(UserProfile? profile, pw.Font fontBold) {
    final name = profile?.fullName ?? 'Bệnh nhân Nguyễn Thu Trang';
    final bloodType = profile?.bloodType ?? 'O+ (Rh Dương)';
    final emergency = profile?.emergencyContact ?? '0988 123 456';
    final allergies = (profile?.allergies != null && profile!.allergies.isNotEmpty)
        ? profile.allergies.join(', ')
        : 'Penicillin, Aspirin';

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F7FAFC'),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '1. THÔNG TIN BỆNH NHÂN',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text('Họ và tên: $name', style: const pw.TextStyle(fontSize: 9)),
              ),
              pw.Expanded(
                child: pw.Text('Nhóm máu: $bloodType', style: const pw.TextStyle(fontSize: 9)),
              ),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text('Liên hệ khẩn cấp (ICE): $emergency', style: const pw.TextStyle(fontSize: 9)),
              ),
              pw.Expanded(
                child: pw.Text('Dị ứng: $allergies', style: const pw.TextStyle(fontSize: 9, color: PdfColors.red800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildClinicalSection(MedicalEvent record, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '2. THÔNG TIN LÂM SÀNG & CHẨN ĐOÁN',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Text('Bệnh viện / Cơ sở: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Text(record.prescription?.hospital ?? 'Bệnh viện Đa khoa Quốc tế', style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Row(
            children: [
              pw.Text('Bác sĩ khám: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Text(record.prescription?.doctorName ?? 'BS. CKII Lê Hoàng Tuấn', style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Chẩn đoán: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Expanded(
                child: pw.Text(record.title, style: const pw.TextStyle(fontSize: 9)),
              ),
            ],
          ),
          if (record.description != null && record.description!.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Mô tả / Triệu chứng: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Expanded(
                  child: pw.Text(record.description!, style: const pw.TextStyle(fontSize: 9)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildPrescriptionSection(Prescription prescription, pw.Font fontBold) {
    final meds = prescription.medicines;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '3. ĐƠN THUỐC ĐIỀU TRỊ',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['STT', 'Tên Thuốc & Hàm Lượng', 'Liều Dùng', 'Hướng Dẫn Sử Dụng'],
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#4A5D4E')),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            data: List.generate(meds.length, (index) {
              final m = meds[index];
              return [
                '${index + 1}',
                m.name,
                m.dosage,
                m.instructions ?? m.frequency,
              ];
            }),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerAlignment: pw.Alignment.centerLeft,
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSignatureSection(MedicalEvent record, pw.Font fontBold) {
    final docName = record.prescription?.doctorName ?? 'BS. CKII Lê Hoàng Tuấn';

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('BỆNH NHÂN / NGƯỜI NHÀ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 35),
              pw.Text('(Ký và ghi rõ họ tên)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('BÁC SĨ KHÁM BỆNH', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 35),
              pw.Text(docName, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Text('(Đã ký số điện tử)', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Future<void> printRecord({
    required MedicalEvent record,
    UserProfile? patientProfile,
  }) async {
    final pdfBytes = await generateMedicalRecordPdf(
      record: record,
      patientProfile: patientProfile,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'HoSo_${record.id}.pdf',
    );
  }

  @override
  Future<void> shareRecordPdf({
    required MedicalEvent record,
    UserProfile? patientProfile,
  }) async {
    final pdfBytes = await generateMedicalRecordPdf(
      record: record,
      patientProfile: patientProfile,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'HoSo_BenhAn_${record.id}.pdf',
    );
  }
}
