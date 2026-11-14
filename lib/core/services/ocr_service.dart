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

    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lower = line.toLowerCase();

      // 1. Nhận diện Bệnh viện / Phòng khám
      if (hospital == null &&
          (lower.contains('bệnh viện') ||
              lower.contains('phòng khám') ||
              lower.contains('trung tâm y tế') ||
              lower.contains('hospital') ||
              lower.contains('clinic'))) {
        hospital = line;
      }

      // 2. Nhận diện Bác sĩ
      if (doctor == null &&
          (lower.contains('bác sĩ') ||
              lower.contains('bs.') ||
              lower.contains('dr.') ||
              lower.contains('bác sỹ'))) {
        doctor = line.replaceAll(RegExp(r'^(bác sĩ|bs\.|dr\.|bác sỹ)[:\s]*', caseSensitive: false), '').trim();
      }

      // 3. Nhận diện Chẩn đoán
      if (diagnosis == null &&
          (lower.contains('chẩn đoán') ||
              lower.contains('chẩn đoán:') ||
              lower.contains('kết luận:') ||
              lower.contains('diagnosis:'))) {
        diagnosis = line.replaceAll(RegExp(r'^(chẩn đoán|kết luận|diagnosis)[:\s]*', caseSensitive: false), '').trim();
      }

      // 4. Nhận diện danh sách thuốc: thường bắt đầu bằng 1. hoặc - hoặc chứa đơn vị y tế (mg, g, ml, viên, gói)
      final isMedLine = RegExp(r'^(\d+[\.\)]|\-|\*)\s+').hasMatch(line) ||
          RegExp(r'\b(\d+\s*(mg|g|ml|mcg|iu|viên|gói|ống))\b', caseSensitive: false).hasMatch(line);

      if (isMedLine) {
        final cleanMedLine = line.replaceFirst(RegExp(r'^(\d+[\.\)]|\-|\*)\s+'), '').trim();
        // Tách tên thuốc và liều dùng nếu có dấu : hoặc -
        String name = cleanMedLine;
        String dosage = '1 viên';
        String instruction = 'Uống sau bữa ăn';

        if (cleanMedLine.contains(':')) {
          final parts = cleanMedLine.split(':');
          name = parts[0].trim();
          instruction = parts.sublist(1).join(':').trim();
        } else if (cleanMedLine.contains(' - ')) {
          final parts = cleanMedLine.split(' - ');
          name = parts[0].trim();
          instruction = parts.sublist(1).join(' - ').trim();
        }

        // Bóc tách dosage nếu có dạng '100mg', '500mg'
        final dosageMatch = RegExp(r'(\d+\s*(mg|g|ml|mcg|iu))\b', caseSensitive: false).firstMatch(name);
        if (dosageMatch != null) {
          dosage = dosageMatch.group(0)!;
        }

        medicines.add(ParsedMedicineItem(
          name: name,
          dosage: dosage,
          instruction: instruction,
        ));
      }
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
