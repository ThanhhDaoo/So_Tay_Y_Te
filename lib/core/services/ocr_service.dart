import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class ParsedMedicineItem {
  final String name;
  final String dosage;
  final String instruction;

  const ParsedMedicineItem({
    required this.name,
    required this.dosage,
    required this.instruction,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'dosage': dosage,
        'instruction': instruction,
      };
}

class ParsedPrescriptionResult {
  final String rawText;
  final String? doctorName;
  final String? hospital;
  final String? diagnosis;
  final List<ParsedMedicineItem> medicines;
  final String? imagePath;

  const ParsedPrescriptionResult({
    required this.rawText,
    this.doctorName,
    this.hospital,
    this.diagnosis,
    required this.medicines,
    this.imagePath,
  });
}

abstract class OcrService {
  Future<String?> pickImage({required ImageSource source});
  Future<ParsedPrescriptionResult?> processPrescriptionImage(String imagePath);
  ParsedPrescriptionResult parseText(String text, {String? imagePath});
}

class OcrServiceImpl implements OcrService {
  final ImagePicker _picker;
  TextRecognizer? _textRecognizer;

  OcrServiceImpl({ImagePicker? picker, TextRecognizer? textRecognizer})
      : _picker = picker ?? ImagePicker() {
    _textRecognizer = textRecognizer;
  }

  TextRecognizer get _recognizer {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizer!;
  }

  @override
  Future<String?> pickImage({required ImageSource source}) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1920,
      );
      return pickedFile?.path;
    } catch (e) {
      debugPrint('OcrServiceImpl.pickImage error: $e');
      return null;
    }
  }

  @override
  Future<ParsedPrescriptionResult?> processPrescriptionImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      final recognizedText = await _recognizer.processImage(inputImage);
      return parseText(recognizedText.text, imagePath: imagePath);
    } catch (e) {
      debugPrint('OcrServiceImpl.processPrescriptionImage error: $e');
      return null;
    }
  }

  @override
  ParsedPrescriptionResult parseText(String text, {String? imagePath}) {
    String? hospital;
    String? doctor;
    String? diagnosis;
    final medicines = <ParsedMedicineItem>[];

    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final lower = line.toLowerCase();

      // 1. Nhận diện Bệnh viện / Phòng khám
      if (hospital == null &&
          (lower.contains('bệnh viện') ||
              lower.contains('phòng khám') ||
              lower.contains('trung tâm y tế') ||
              lower.contains('sở y tế') ||
              lower.startsWith('bv ') ||
              lower.startsWith('pk ') ||
              lower.contains('hospital') ||
              lower.contains('clinic'))) {
        hospital = line;
        i++;
        continue;
      }

      // 2. Nhận diện Bác sĩ
      if (doctor == null &&
          (lower.contains('bác sĩ') ||
              lower.contains('bác sỹ') ||
              lower.contains('bs.') ||
              lower.contains('dr.') ||
              lower.contains('bs ') ||
              lower.contains('ths.bs') ||
              lower.contains('ts.bs') ||
              lower.contains('bs.ck'))) {
        doctor = line.replaceAll(RegExp(r'^(bác sĩ điều trị|bác sĩ|bác sỹ|bs\.|dr\.|bs|ths\.bs|ts\.bs|bs\.ck\w*)[:\s]*', caseSensitive: false), '').trim();
        i++;
        continue;
      }

      // 3. Nhận diện Chẩn đoán
      if (diagnosis == null &&
          (lower.contains('chẩn đoán') ||
              lower.contains('kết luận') ||
              lower.contains('bệnh chính') ||
              lower.contains('diagnosis'))) {
        diagnosis = line.replaceAll(RegExp(r'^(chẩn đoán xác định|chẩn đoán sơ bộ|chẩn đoán|kết luận|bệnh chính|diagnosis)[:\s]*', caseSensitive: false), '').trim();
        i++;
        continue;
      }

      // 4. Bỏ qua các dòng tiêu đề hành chính không phải thuốc
      final isHeaderOrAdmin = lower.contains('cộng hòa xã hội') ||
          lower.contains('độc lập - tự do') ||
          lower.contains('đơn thuốc') ||
          lower.contains('toa thuốc') ||
          lower.contains('phiếu khám') ||
          lower.contains('họ và tên') ||
          lower.contains('họ tên') ||
          lower.contains('năm sinh') ||
          lower.contains('tuổi:') ||
          lower.contains('địa chỉ:') ||
          lower.contains('số thẻ bhyt') ||
          lower.contains('lời dặn') ||
          lower.contains('tái khám') ||
          lower.contains('chữ ký');

      if (isHeaderOrAdmin) {
        i++;
        continue;
      }

      // 5. Nhận diện thuốc:
      // Bắt đầu bằng 1., 2), 3/ hoặc dấu -, *, • hoặc chứa hàm lượng (500mg, 40mg...)
      final hasBullet = RegExp(r'^(\d+[\.\)\/]|[\-\*\•])\s+').hasMatch(line);
      final hasDosageUnit = RegExp(r'\b(\d+\s*(mg|g|ml|mcg|iu|viên|gói|ống))\b', caseSensitive: false).hasMatch(line);

      if (hasBullet || hasDosageUnit) {
        // Tách bỏ bullet đầu dòng
        String rawMed = line.replaceFirst(RegExp(r'^(\d+[\.\)\/]|[\-\*\•])\s*'), '').trim();

        String name = rawMed;
        String dosage = '1 viên';
        String instruction = 'Uống sau bữa ăn';

        // Nếu dòng hiện tại có chứa ':' hoặc ' - ' tách trực tiếp
        if (rawMed.contains(':')) {
          final parts = rawMed.split(':');
          name = parts[0].trim();
          instruction = parts.sublist(1).join(':').trim();
        } else if (rawMed.contains(' - ') && !rawMed.toLowerCase().contains('bệnh viện')) {
          final parts = rawMed.split(' - ');
          name = parts[0].trim();
          instruction = parts.sublist(1).join(' - ').trim();
        }

        // Bóc tách hàm lượng nếu có trong tên thuốc (VD: 500mg, 40mg, 1g)
        final dosageMatch = RegExp(r'(\d+\s*(mg|g|ml|mcg|iu))\b', caseSensitive: false).firstMatch(name);
        if (dosageMatch != null) {
          dosage = dosageMatch.group(0)!;
        }

        // Tách số lượng nếu có ở cuối (VD: "x 14 viên", "SL: 20 viên", "(14 viên)")
        final qtyMatch = RegExp(r'(\(?(sl|số lượng|x)?\s*\d+\s*(viên|gói|ống|chai|hộp)\)?)', caseSensitive: false).firstMatch(name);
        if (qtyMatch != null && !name.toLowerCase().startsWith('uống')) {
          final qtyStr = qtyMatch.group(0)!;
          if (dosage == '1 viên') {
            dosage = qtyStr;
          }
          name = name.replaceAll(qtyStr, '').trim();
        }

        // Kiểm tra dòng TIẾP THEO (i+1): nếu là dòng hướng dẫn uống thuốc
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1];
          final nextLower = nextLine.toLowerCase();
          final nextIsBullet = RegExp(r'^(\d+[\.\)\/]|[\-\*\•])\s+').hasMatch(nextLine);
          final nextIsInstruction = !nextIsBullet && (
            nextLower.startsWith('uống') ||
            nextLower.startsWith('ngày') ||
            nextLower.startsWith('sáng') ||
            nextLower.startsWith('trưa') ||
            nextLower.startsWith('chiều') ||
            nextLower.startsWith('tối') ||
            nextLower.startsWith('mỗi lần') ||
            nextLower.startsWith('ngậm') ||
            nextLower.startsWith('thoa') ||
            nextLower.startsWith('nhỏ') ||
            nextLower.startsWith('tiêm') ||
            nextLower.contains('viên/ngày') ||
            nextLower.contains('lần/ngày') ||
            nextLower.contains('trước ăn') ||
            nextLower.contains('sau ăn') ||
            nextLower.contains('khi sốt') ||
            nextLower.contains('sl:') ||
            nextLower.contains('số lượng:')
          );

          if (nextIsInstruction) {
            instruction = instruction == 'Uống sau bữa ăn' ? nextLine : '$instruction · $nextLine';
            i++; // Bỏ qua dòng hướng dẫn này để không bị parse thành thuốc mới!
          }
        }

        medicines.add(ParsedMedicineItem(
          name: name,
          dosage: dosage,
          instruction: instruction,
        ));
      }

      i++;
    }

    // Nếu không tách được thuốc nào qua regex cứng, thử heuristic dự phòng
    if (medicines.isEmpty && text.trim().isNotEmpty) {
      medicines.add(const ParsedMedicineItem(
        name: 'Đơn thuốc quét bằng AI',
        dosage: 'Theo chỉ dẫn',
        instruction: 'Tuân thủ đúng liều lượng bác sĩ kê đơn',
      ));
    }

    return ParsedPrescriptionResult(
      rawText: text,
      hospital: hospital ?? 'Bệnh viện / Phòng khám',
      doctorName: doctor ?? 'Bác sĩ điều trị',
      diagnosis: diagnosis ?? 'Theo dõi điều trị ngoại trú',
      medicines: medicines,
      imagePath: imagePath,
    );
  }
}
