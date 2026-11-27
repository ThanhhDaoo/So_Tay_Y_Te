import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../presentation/routes/app_routes.dart';

class ParsedMedicineItem {
  final String name;
  final String dosage;
  final String instruction;

  const ParsedMedicineItem({
    required this.name,
    required this.dosage,
    required this.instruction,
  });

  ParsedMedicineItem copyWith({
    String? name,
    String? dosage,
    String? instruction,
  }) {
    return ParsedMedicineItem(
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      instruction: instruction ?? this.instruction,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'dosage': dosage,
        'instruction': instruction,
      };
}

class ParsedPrescriptionResult {
  final String rawText;
  final String? prescriptionType;
  final String? doctorName;
  final String? hospital;
  final String? diagnosis;
  final String? advice;
  final List<ParsedMedicineItem> medicines;
  final String? imagePath;

  const ParsedPrescriptionResult({
    required this.rawText,
    this.prescriptionType,
    this.doctorName,
    this.hospital,
    this.diagnosis,
    this.advice,
    required this.medicines,
    this.imagePath,
  });
}

class ParsedBloodPressureResult {
  final int systolic;
  final int diastolic;
  final int? pulse;
  final String rawText;
  final String? imagePath;
  final bool isAutoDetected;

  const ParsedBloodPressureResult({
    required this.systolic,
    required this.diastolic,
    this.pulse,
    required this.rawText,
    this.imagePath,
    this.isAutoDetected = false,
  });

  ParsedBloodPressureResult copyWith({
    int? systolic,
    int? diastolic,
    int? pulse,
    String? rawText,
    String? imagePath,
    bool? isAutoDetected,
  }) {
    return ParsedBloodPressureResult(
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      pulse: pulse ?? this.pulse,
      rawText: rawText ?? this.rawText,
      imagePath: imagePath ?? this.imagePath,
      isAutoDetected: isAutoDetected ?? this.isAutoDetected,
    );
  }
}

/// Bộ nhận diện chuyên biệt cho màn hình máy đo huyết áp điện tử (Omron, Microlife, Yuwell, Beurer...).
class BloodPressureOcrParser {
  static ParsedBloodPressureResult parse(String rawText, {String? imagePath}) {
    if (rawText.trim().isEmpty) {
      return ParsedBloodPressureResult(
        systolic: 120,
        diastolic: 80,
        pulse: 72,
        rawText: rawText,
        imagePath: imagePath,
        isAutoDetected: false,
      );
    }

    // 1. Trường hợp ghi dạng phân số "128/82" hoặc "HA: 130 / 85 mmHg"
    final slashMatch = RegExp(r'\b(9\d|[12]\d{2})\s*[\/\\]\s*([4-9]\d|1[0-4]\d)\b')
        .firstMatch(rawText);
    int? detectedSys;
    int? detectedDia;
    int? detectedPulse;

    if (slashMatch != null) {
      final s = int.tryParse(slashMatch.group(1)!);
      final d = int.tryParse(slashMatch.group(2)!);
      if (s != null && d != null && s > d) {
        detectedSys = s;
        detectedDia = d;
      }
    }

    // 2. Chuẩn hóa các ký tự màn hình LCD 7-đoạn dễ bị đọc nhầm trên dòng chứa số
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    for (final line in lines) {
      final lower = line.toLowerCase();
      // Bỏ qua dòng ngày giờ trên máy đo (VD: 11/27 08:30 hoặc 2026)
      if (RegExp(r'\b\d{1,2}:\d{2}\b').hasMatch(line) ||
          RegExp(r'\b202\d\b').hasMatch(line)) {
        continue;
      }

      if (detectedSys == null &&
          (lower.contains('sys') || lower.contains('tâm thu'))) {
        final m = RegExp(r'\b(8\d|9\d|[12]\d{2})\b').firstMatch(_normalizeLcdDigits(line));
        if (m != null) detectedSys = int.tryParse(m.group(1)!);
      } else if (detectedDia == null &&
          (lower.contains('dia') || lower.contains('tâm trương'))) {
        final m = RegExp(r'\b([4-9]\d|1[0-4]\d)\b').firstMatch(_normalizeLcdDigits(line));
        if (m != null) detectedDia = int.tryParse(m.group(1)!);
      } else if (detectedPulse == null &&
          (lower.contains('pul') ||
              lower.contains('nhịp') ||
              lower.contains('mạch') ||
              lower.contains('bpm') ||
              lower.contains('/min'))) {
        final m = RegExp(r'\b([4-9]\d|1[0-8]\d)\b').firstMatch(_normalizeLcdDigits(line));
        if (m != null) detectedPulse = int.tryParse(m.group(1)!);
      }
    }

    // 3. Nếu màn hình LCD chỉ bóc tách được 2–3 con số xếp dọc từ trên xuống (SYS -> DIA -> PUL)
    if (detectedSys == null || detectedDia == null || detectedPulse == null) {
      final candidateNumbers = <int>[];
      for (final line in lines) {
        if (RegExp(r'\b\d{1,2}:\d{2}\b').hasMatch(line) ||
            RegExp(r'\b202\d\b').hasMatch(line)) {
          continue;
        }
        final normalized = _normalizeLcdDigits(line);
        for (final match in RegExp(r'\b(\d{2,3})\b').allMatches(normalized)) {
          final val = int.tryParse(match.group(1)!);
          if (val != null && val >= 38 && val <= 250) {
            candidateNumbers.add(val);
          }
        }
      }

      if (detectedSys == null || detectedDia == null) {
        for (int i = 0; i < candidateNumbers.length - 1; i++) {
          final first = candidateNumbers[i];
          final second = candidateNumbers[i + 1];
          if (first >= 85 &&
              first <= 245 &&
              second >= 45 &&
              second <= 145 &&
              first > second + 15) {
            detectedSys ??= first;
            detectedDia ??= second;
            if (detectedPulse == null && i + 2 < candidateNumbers.length) {
              final third = candidateNumbers[i + 2];
              if (third >= 40 && third <= 185) {
                detectedPulse = third;
              }
            }
            break;
          }
        }
      } else if (detectedPulse == null) {
        for (final n in candidateNumbers) {
          if (n != detectedSys && n != detectedDia && n >= 40 && n <= 185) {
            detectedPulse = n;
            break;
          }
        }
      }
    }

    final foundValidPair =
        detectedSys != null && detectedDia != null && detectedSys > detectedDia;

    return ParsedBloodPressureResult(
      systolic: foundValidPair ? detectedSys : 120,
      diastolic: foundValidPair ? detectedDia : 80,
      pulse: detectedPulse ?? 72,
      rawText: rawText,
      imagePath: imagePath,
      isAutoDetected: foundValidPair,
    );
  }

  static String _normalizeLcdDigits(String input) {
    // Chỉ chuẩn hóa các token đứng riêng trông giống cụm chữ số màn hình LED 7-đoạn
    return input.replaceAllMapped(
      RegExp(r'(?<![a-zA-ZÀ-ỹ])[0-9OIlSB]{2,3}(?![a-zA-ZÀ-ỹ])'),
      (m) {
        final token = m.group(0)!;
        if (!RegExp(r'\d').hasMatch(token)) return token;
        return token
            .replaceAll('O', '0')
            .replaceAll('I', '1')
            .replaceAll('l', '1')
            .replaceAll('S', '5')
            .replaceAll('B', '8');
      },
    );
  }
}

extension BloodPressureOcrExtension on OcrService {
  Future<ParsedBloodPressureResult> processBloodPressureImage(String imagePath) async {
    if (this is OcrServiceImpl) {
      return (this as OcrServiceImpl).recognizeBloodPressureFromImage(imagePath);
    }
    final rxResult = await processPrescriptionImage(imagePath);
    return BloodPressureOcrParser.parse(
      rxResult?.rawText ?? '',
      imagePath: imagePath,
    );
  }

  ParsedBloodPressureResult parseBloodPressureText(
    String text, {
    String? imagePath,
  }) {
    return BloodPressureOcrParser.parse(text, imagePath: imagePath);
  }
}

abstract class OcrService {
  Future<String?> pickImage({required ImageSource source});
  Future<ParsedPrescriptionResult?> processPrescriptionImage(String imagePath);
  ParsedPrescriptionResult parseText(String text, {String? imagePath});
  Future<void> dispose();
}

class OcrServiceImpl implements OcrService {
  static const MethodChannel _nativeOcrChannel = MethodChannel('com.sotayyte/native_ocr');

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
    AppRoutes.isExternalPickerActive = true;
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 2048,
      );
      if (pickedFile == null) return null;

      // Sao chép ảnh từ thư mục cache tạm (tmp/) sang Documents bền vững để tránh bị HĐH tự dọn rác
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final ext = p.extension(pickedFile.path).isNotEmpty
            ? p.extension(pickedFile.path)
            : '.jpg';
        final permanentPath = p.join(
          docsDir.path,
          'ocr_${DateTime.now().millisecondsSinceEpoch}$ext',
        );
        final savedFile = await File(pickedFile.path).copy(permanentPath);
        return savedFile.path;
      } catch (copyErr) {
        debugPrint('OcrServiceImpl.pickImage permanent copy fallback: $copyErr');
        return pickedFile.path;
      }
    } catch (e) {
      debugPrint('OcrServiceImpl.pickImage error: $e');
      return null;
    } finally {
      AppRoutes.isExternalPickerActive = false;
    }
  }

  @override
  Future<ParsedPrescriptionResult?> processPrescriptionImage(String imagePath) async {
    try {
      // Trên iOS: dùng trực tiếp Apple Vision Framework (VNRecognizeTextRequest hỗ trợ tiếng Việt vi-VN native),
      // tránh hoàn toàn lỗi crash native của MLKit C++/ObjC trên Swift Package Manager.
      if (!kIsWeb && Platform.isIOS) {
        final recognized = await _nativeOcrChannel.invokeMethod<String>(
          'recognizeText',
          {'imagePath': imagePath},
        );
        return parseText(recognized ?? '', imagePath: imagePath);
      }

      final inputImage = InputImage.fromFile(File(imagePath));
      final recognizedText = await _recognizer.processImage(inputImage);
      return parseText(recognizedText.text, imagePath: imagePath);
    } catch (e) {
      debugPrint('OcrServiceImpl.processPrescriptionImage error: $e');
      return ParsedPrescriptionResult(
        rawText: '',
        medicines: const [],
        imagePath: imagePath,
      );
    }
  }

  Future<ParsedBloodPressureResult> recognizeBloodPressureFromImage(String imagePath) async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        final recognized = await _nativeOcrChannel.invokeMethod<String>(
          'recognizeText',
          {'imagePath': imagePath},
        );
        return BloodPressureOcrParser.parse(recognized ?? '', imagePath: imagePath);
      }

      final inputImage = InputImage.fromFile(File(imagePath));
      final recognizedText = await _recognizer.processImage(inputImage);
      return BloodPressureOcrParser.parse(recognizedText.text, imagePath: imagePath);
    } catch (e) {
      debugPrint('OcrServiceImpl.recognizeBloodPressureFromImage error: $e');
      return ParsedBloodPressureResult(
        systolic: 120,
        diastolic: 80,
        pulse: 72,
        rawText: '',
        imagePath: imagePath,
        isAutoDetected: false,
      );
    }
  }

  @override
  ParsedPrescriptionResult parseText(String text, {String? imagePath}) {
    if (text.trim().isEmpty) {
      return ParsedPrescriptionResult(
        rawText: '',
        medicines: const [],
        imagePath: imagePath,
      );
    }

    String? prescriptionType;
    String? hospital;
    bool hospitalIsAdminParent = false;
    String? doctor;
    String? diagnosis;
    String? advice;
    final medicines = <ParsedMedicineItem>[];

    final lines = text
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'\s{2,}'), '   ').trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Bước phụ: Quét tìm tên bác sĩ ở khối chữ ký cuối đơn ("Bác sĩ khám bệnh" / "Người kê đơn")
    for (int k = 0; k < lines.length; k++) {
      final low = lines[k].toLowerCase();
      if (low == 'bác sĩ khám bệnh' ||
          low == 'bác sĩ điều trị' ||
          low == 'bác sỹ khám bệnh' ||
          low == 'người kê đơn' ||
          low.startsWith('bác sĩ khám bệnh ') ||
          low.startsWith('bác sĩ kê đơn')) {
        for (int m = k + 1; m <= k + 3 && m < lines.length; m++) {
          final cand = lines[m].trim();
          final candLow = cand.toLowerCase();
          if (candLow.contains('ký') ||
              candLow.contains('ghi rõ') ||
              candLow.contains('họ tên') ||
              candLow.contains('đóng dấu') ||
              candLow.contains('tái khám') ||
              candLow.contains('lời dặn') ||
              cand.length < 4) {
            continue;
          }
          doctor = _cleanDoctorPrefix(cand);
          break;
        }
      }
    }

    bool reachedFooter = false;
    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final lower = line.toLowerCase();

      // 0. Nhận diện loại đơn thuốc (ĐƠN THUỐC BHYT, ĐƠN THUỐC NGOẠI TRÚ, PHIẾU TƯ VẤN...)
      if (prescriptionType == null &&
          (lower.contains('đơn thuốc') ||
              lower.contains('toa thuốc') ||
              lower.contains('phiếu tư vấn thuốc') ||
              lower.contains('đơn tư vấn'))) {
        final cleanedHeader = line.replaceAll(':', '').trim();
        if (cleanedHeader.length <= 45) {
          prescriptionType = cleanedHeader;
        }
      }

      // 1. Nhận diện Cơ sở y tế / Bệnh viện / Phòng khám / Nhà thuốc
      final isDirectFacility = !lower.startsWith('địa chỉ') &&
          !lower.startsWith('nơi đk') &&
          (lower.contains('bệnh viện') ||
              lower.contains('phòng khám') ||
              lower.contains('trung tâm y tế') ||
              lower.contains('trạm y tế') ||
              lower.contains('nhà thuốc') ||
              lower.startsWith('bv ') ||
              lower.startsWith('bvđk') ||
              lower.startsWith('pk ') ||
              lower.startsWith('pkđk') ||
              lower.startsWith('ttyt') ||
              lower.contains('vinmec') ||
              lower.contains('bạch mai') ||
              lower.contains('chợ rẫy') ||
              lower.contains('tâm anh') ||
              lower.contains('medlatec') ||
              lower.contains('hoàn mỹ') ||
              lower.contains('long châu') ||
              lower.contains('pharmacity') ||
              lower.contains('an khang') ||
              lower.contains('hospital') ||
              lower.contains('clinic'));

      final isAdminHealthDept = lower.startsWith('sở y tế') || lower.startsWith('bộ y tế');

      if (isDirectFacility && (hospital == null || hospitalIsAdminParent)) {
        // Nếu có nhiều cột trên dòng đầu (VD: "BỆNH VIỆN ĐẠI HỌC Y DƯỢC   Mã số: 123"), chỉ lấy cột đầu
        hospital = line.split('   ').first.trim();
        hospitalIsAdminParent = false;
        i++;
        continue;
      } else if (isAdminHealthDept && hospital == null) {
        hospital = line.split('   ').first.trim();
        hospitalIsAdminParent = true;
        i++;
        continue;
      }

      // 2. Nhận diện Bác sĩ kê đơn trực tiếp trên dòng (VD: "Bác sĩ: BS. CKII Lê Hoàng Tuấn")
      if (_isInlineDoctorLine(lower)) {
        final extractedDoc = _cleanDoctorPrefix(line);
        if (extractedDoc.isNotEmpty && extractedDoc.length >= 3) {
          doctor = extractedDoc;
          i++;
          continue;
        }
      }

      // 3. Nhận diện Chẩn đoán bệnh
      if (diagnosis == null &&
          (lower.contains('chẩn đoán') ||
              lower.startsWith('kết luận:') ||
              lower.startsWith('bệnh chính') ||
              lower.startsWith('diagnosis'))) {
        String extractedDiag = line
            .replaceAll(
              RegExp(
                r'^.*?(chẩn đoán xác định|chẩn đoán sơ bộ|chẩn đoán bệnh|chẩn đoán|kết luận|bệnh chính|diagnosis)[:\s\-]*',
                caseSensitive: false,
              ),
              '',
            )
            .trim();
        // Nếu dòng "Chẩn đoán:" đứng riêng và nội dung nằm ở dòng kế tiếp
        if (extractedDiag.isEmpty && i + 1 < lines.length && !_LooksLikeMedicineHelper.hasBullet(lines[i + 1])) {
          extractedDiag = lines[i + 1].trim();
          i++;
        }
        if (extractedDiag.isNotEmpty) {
          diagnosis = extractedDiag;
        }
        i++;
        continue;
      }

      // 4. Kiểm tra vùng chân trang (Lời dặn, Hẹn tái khám, Ngày ký, Cộng khoản) -> dừng quét thuốc
      if (_isFooterBoundary(lower)) {
        if (advice == null && (lower.startsWith('lời dặn') || lower.startsWith('dặn dò') || lower.startsWith('ghi chú'))) {
          final cleanAdv = line.replaceFirst(RegExp(r'^(lời dặn của bác sĩ|lời dặn|dặn dò|ghi chú)[:\s]*', caseSensitive: false), '').trim();
          if (cleanAdv.isNotEmpty) {
            advice = cleanAdv;
          } else if (i + 1 < lines.length) {
            advice = lines[i + 1].trim();
          }
        }
        reachedFooter = true;
      }

      if (reachedFooter) {
        i++;
        continue;
      }

      // 5. Nếu dòng hiện tại CHỈ là dòng số lượng (VD: "SL: 14 Viên", "10 Gói", "x 20 viên") -> gộp vào thuốc ngay trước đó!
      if (medicines.isNotEmpty && _LooksLikeMedicineHelper.isPureQuantityLine(line)) {
        final prev = medicines.last;
        final qtyClean = line.replaceFirst(RegExp(r'^(sl|số lượng|x)[:\s]*', caseSensitive: false), '').trim();
        final mergedDosage = prev.dosage == 'Theo đơn' || prev.dosage == '1 viên'
            ? qtyClean
            : (prev.dosage.toLowerCase().contains(qtyClean.toLowerCase()) ? prev.dosage : '${prev.dosage} • SL: $qtyClean');
        medicines[medicines.length - 1] = prev.copyWith(dosage: mergedDosage);
        i++;
        continue;
      }

      // 6. Nếu dòng hiện tại là dòng hướng dẫn uống thuốc bổ sung cho thuốc ngay trước đó
      if (medicines.isNotEmpty &&
          !_LooksLikeMedicineHelper.hasBullet(line) &&
          _LooksLikeMedicineHelper.isInstructionLine(lower)) {
        final prev = medicines.last;
        final mergedInst = prev.instruction == 'Theo chỉ dẫn bác sĩ' || prev.instruction == 'Uống sau bữa ăn'
            ? line
            : '${prev.instruction} · $line';
        medicines[medicines.length - 1] = prev.copyWith(instruction: mergedInst);
        i++;
        continue;
      }

      // 7. Bỏ qua các dòng hành chính / thông tin bệnh nhân / chỉ số sinh tồn
      if (_isAdminOrPatientLine(lower)) {
        i++;
        continue;
      }

      // 8. Nhận diện dòng Tên Thuốc
      final hasBullet = _LooksLikeMedicineHelper.hasBullet(line);
      final hasPharmaSignature = _LooksLikeMedicineHelper.hasPharmaceuticalSignature(line);

      if (hasBullet || hasPharmaSignature) {
        String rawMed = line
            .replaceFirst(RegExp(r'^(?:\(\d+\)|\d+[\.\)\/\-]|[\-\*\•\+])\s*'), '')
            .replaceFirst(RegExp(r'^0?\d+\s+(?=[A-ZÀ-Ỹ])'), '')
            .trim();

        // Tránh nhận nhầm dòng toàn số hoặc quá ngắn
        if (rawMed.length < 3 || !RegExp(r'[a-zA-ZÀ-ỹ]').hasMatch(rawMed)) {
          i++;
          continue;
        }

        String name = rawMed;
        String dosage = 'Theo đơn';
        String instruction = 'Theo chỉ dẫn bác sĩ';

        // Nếu cột phải được ghép bằng "   " chứa số lượng (VD: "Augmentin 1g   14 Viên" hoặc "Nexium 40mg   SL: 14 viên")
        if (rawMed.contains('   ')) {
          final cols = rawMed.split('   ').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
          if (cols.length >= 2) {
            final lastCol = cols.last;
            if (_LooksLikeMedicineHelper.isPureQuantityLine(lastCol)) {
              final qtyClean = lastCol.replaceFirst(RegExp(r'^(sl|số lượng|x)[:\s]*', caseSensitive: false), '').trim();
              dosage = qtyClean;
              name = cols.sublist(0, cols.length - 1).join(' ');
            } else if (_LooksLikeMedicineHelper.isInstructionLine(lastCol.toLowerCase())) {
              instruction = lastCol;
              name = cols.sublist(0, cols.length - 1).join(' ');
            }
          }
        }

        // Tách theo dấu ':' hoặc ' - ' nếu chứa hướng dẫn sử dụng trên cùng 1 dòng
        if (name.contains(':')) {
          final parts = name.split(':');
          final left = parts[0].trim();
          final right = parts.sublist(1).join(':').trim();
          if (left.length >= 2 && right.isNotEmpty) {
            name = left;
            instruction = right;
          }
        } else if (name.contains(' - ') && !name.toLowerCase().contains('bệnh viện')) {
          final parts = name.split(' - ');
          final left = parts[0].trim();
          final right = parts.sublist(1).join(' - ').trim();
          if (left.length >= 2 && right.isNotEmpty) {
            name = left;
            instruction = right;
          }
        }

        // Bóc tách hàm lượng trong tên thuốc (VD: 500mg, 40mg, 1g, 200mg/5ml, 0.5mg)
        final strengthMatch = RegExp(
          r'(\d+(?:[.,]\d+)?\s*(?:mg|mcg|g|ml|iu|ui|%)(?:\s*\/\s*\d+(?:[.,]\d+)?\s*(?:mg|mcg|g|ml))?)\b',
          caseSensitive: false,
        ).firstMatch(name);
        if (strengthMatch != null) {
          final strengthStr = strengthMatch.group(0)!.trim();
          dosage = dosage == 'Theo đơn' ? strengthStr : '$strengthStr • SL: $dosage';
        }

        // Tách số lượng nếu nằm cuối dòng tên thuốc (VD: "SL: 20 viên", "x 14 viên")
        final inlineQtyMatch = RegExp(
          r'(?:\(?(?:sl|số lượng|x)\s*:?\s*\d+\s*(?:viên|vỉ|gói|ống|lọ|chai|tuýp|hộp)\)?)',
          caseSensitive: false,
        ).firstMatch(name);
        if (inlineQtyMatch != null && !name.toLowerCase().startsWith('uống')) {
          final qtyStr = inlineQtyMatch.group(0)!.trim();
          if (dosage == 'Theo đơn') {
            dosage = qtyStr;
          } else if (!dosage.toLowerCase().contains(qtyStr.toLowerCase())) {
            dosage = '$dosage ($qtyStr)';
          }
          name = name.replaceAll(qtyStr, '').trim();
        }

        // Nhìn trước dòng tiếp theo (i+1): nếu là dòng số lượng hoặc hướng dẫn uống thì gom luôn
        while (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          final nextLower = nextLine.toLowerCase();
          if (_isFooterBoundary(nextLower) || _LooksLikeMedicineHelper.hasBullet(nextLine)) {
            break;
          }
          if (_LooksLikeMedicineHelper.isPureQuantityLine(nextLine)) {
            final qtyClean = nextLine.replaceFirst(RegExp(r'^(sl|số lượng|x)[:\s]*', caseSensitive: false), '').trim();
            dosage = dosage == 'Theo đơn' ? qtyClean : '$dosage • SL: $qtyClean';
            i++;
            continue;
          }
          if (_LooksLikeMedicineHelper.isInstructionLine(nextLower)) {
            instruction = instruction == 'Theo chỉ dẫn bác sĩ' ? nextLine : '$instruction · $nextLine';
            i++;
            continue;
          }
          break;
        }

        medicines.add(
          ParsedMedicineItem(
            name: name,
            dosage: dosage,
            instruction: instruction,
          ),
        );
      }

      i++;
    }

    return ParsedPrescriptionResult(
      rawText: text,
      prescriptionType: prescriptionType,
      hospital: hospital,
      doctorName: doctor,
      diagnosis: diagnosis ?? prescriptionType,
      advice: advice,
      medicines: medicines,
      imagePath: imagePath,
    );
  }

  String _cleanDoctorPrefix(String raw) {
    return raw
        .split('   ')
        .first
        .replaceAll(
          RegExp(
            r'^(?:bác sĩ điều trị|bác sĩ khám bệnh|bác sĩ kê đơn|người kê đơn|bác sĩ|bác sỹ|pgs\.?\s*ts\.?\s*bs\.?|gs\.?\s*ts\.?\s*bs\.?|pgs\.?\s*ts\.?|gs\.?\s*ts\.?|ths\.?\s*bs\.?|ts\.?\s*bs\.?|bs\.?\s*ck(?:i|ii|1|2)|bs\.?|dr\.?)[:\s\-]*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  bool _isInlineDoctorLine(String lower) {
    if (lower == 'bác sĩ khám bệnh' ||
        lower == 'bác sĩ điều trị' ||
        lower == 'bác sỹ khám bệnh' ||
        lower == 'người kê đơn') {
      return false;
    }
    return lower.startsWith('bác sĩ') ||
        lower.startsWith('bác sỹ') ||
        lower.startsWith('bs.') ||
        lower.startsWith('bs:') ||
        lower.startsWith('bs ') ||
        lower.startsWith('ths.bs') ||
        lower.startsWith('ts.bs') ||
        lower.startsWith('pgs.ts') ||
        lower.startsWith('gs.ts') ||
        lower.startsWith('bs.ck') ||
        lower.startsWith('bsck') ||
        lower.startsWith('dr.');
  }

  bool _isFooterBoundary(String lower) {
    return lower.startsWith('lời dặn') ||
        lower.startsWith('dặn dò') ||
        lower.startsWith('hẹn tái khám') ||
        lower.startsWith('tái khám') ||
        lower.startsWith('cộng khoản') ||
        lower.startsWith('tổng cộng:') ||
        lower.startsWith('tổng số khoản') ||
        lower == 'bác sĩ khám bệnh' ||
        lower == 'bác sĩ điều trị' ||
        lower == 'người kê đơn' ||
        lower == 'người nhận thuốc' ||
        RegExp(r'^ngày\s+\d{1,2}\s+tháng\s+\d{1,2}\s+năm\s+\d{4}').hasMatch(lower);
  }

  bool _isAdminOrPatientLine(String lower) {
    return lower.contains('cộng hòa xã hội') ||
        lower.contains('độc lập - tự do') ||
        lower.contains('đơn thuốc') ||
        lower.contains('toa thuốc') ||
        lower.contains('phiếu khám') ||
        lower.contains('phiếu tư vấn') ||
        lower.startsWith('họ và tên') ||
        lower.startsWith('họ tên') ||
        lower.startsWith('tên bệnh nhân') ||
        lower.startsWith('khách hàng:') ||
        lower.startsWith('năm sinh') ||
        lower.startsWith('ngày sinh') ||
        lower.startsWith('tuổi:') ||
        lower.startsWith('giới tính') ||
        lower.startsWith('địa chỉ') ||
        lower.startsWith('điện thoại') ||
        lower.startsWith('sđt') ||
        lower.startsWith('số thẻ bhyt') ||
        lower.startsWith('mã thẻ') ||
        lower.startsWith('mã bn') ||
        lower.startsWith('mã y tế') ||
        lower.startsWith('đối tượng') ||
        lower.startsWith('cân nặng') ||
        lower.startsWith('chiều cao') ||
        lower.startsWith('huyết áp') ||
        lower.startsWith('mạch:') ||
        lower.startsWith('nhiệt độ') ||
        lower.startsWith('nhịp thở') ||
        lower.startsWith('khoa ') ||
        lower.startsWith('phòng khám số') ||
        lower.startsWith('stt ') ||
        lower == 'thuốc điều trị:' ||
        lower == 'chỉ định dùng thuốc:' ||
        lower.contains('ký và ghi rõ') ||
        lower.contains('chữ ký');
  }

  @override
  Future<void> dispose() async {
    try {
      await _textRecognizer?.close();
    } catch (e) {
      debugPrint('OcrServiceImpl.dispose error: $e');
    } finally {
      _textRecognizer = null;
    }
  }
}

class _LooksLikeMedicineHelper {
  static bool hasBullet(String line) {
    return RegExp(r'^(?:\(\d+\)|0?\d+[\.\)\/]|[\-\*\•])\s*').hasMatch(line) ||
        RegExp(r'^0?\d+\s+[A-ZÀ-Ỹ][a-zA-ZÀ-ỹ]{2,}').hasMatch(line);
  }

  static bool isPureQuantityLine(String line) {
    final trimmed = line.trim();
    return RegExp(
      r'^(?:sl|số lượng|x)?\s*:?\s*\d+\s*(?:viên|vỉ|gói|ống|lọ|chai|tuýp|hộp|miếng|nhát|ml)\.?$',
      caseSensitive: false,
    ).hasMatch(trimmed);
  }

  static bool isInstructionLine(String lower) {
    return lower.startsWith('uống') ||
        lower.startsWith('ngày uống') ||
        lower.startsWith('ngày dùng') ||
        lower.startsWith('ngày ') ||
        lower.startsWith('sáng ') ||
        lower.startsWith('sáng:') ||
        lower.startsWith('trưa ') ||
        lower.startsWith('trưa:') ||
        lower.startsWith('chiều ') ||
        lower.startsWith('chiều:') ||
        lower.startsWith('tối ') ||
        lower.startsWith('tối:') ||
        lower.startsWith('mỗi lần') ||
        lower.startsWith('chia ') ||
        lower.startsWith('ngậm') ||
        lower.startsWith('thoa') ||
        lower.startsWith('bôi ') ||
        lower.startsWith('nhỏ ') ||
        lower.startsWith('xịt ') ||
        lower.startsWith('tiêm ') ||
        lower.startsWith('pha ') ||
        lower.startsWith('cách dùng') ||
        lower.startsWith('liều dùng') ||
        lower.contains('viên/ngày') ||
        lower.contains('viên / ngày') ||
        lower.contains('lần/ngày') ||
        lower.contains('lần / ngày') ||
        lower.contains('mỗi lần') ||
        lower.contains('trước ăn') ||
        lower.contains('sau ăn') ||
        lower.contains('trước khi ăn') ||
        lower.contains('sau khi ăn') ||
        lower.contains('trước khi đi ngủ') ||
        lower.contains('khi sốt') ||
        lower.contains('khi đau');
  }

  static bool hasPharmaceuticalSignature(String line) {
    if (isPureQuantityLine(line) || isInstructionLine(line.toLowerCase())) {
      return false;
    }
    final hasStrengthOrForm = RegExp(
      r'\b\d+(?:[.,]\d+)?\s*(?:mg|mcg|g|ml|iu|ui|%)\b|\b(?:viên nén|viên nang|viên sủi|hỗn dịch|dung dịch|siro)\b',
      caseSensitive: false,
    ).hasMatch(line);
    if (hasStrengthOrForm) return true;

    return RegExp(
      r'\b(?:paracetamol|panadol|efferalgan|hapacol|augmentin|amoxicillin|cefuroxim|cefixim|cefpodoxim|azithromycin|klacid|clarithromycin|nexium|esomeprazol|omeprazol|pantoprazol|rabeprazol|gaviscon|phosphalugel|smecta|berberin|enterogermina|oresol|alpha\s*choay|alphachymotrypsin|loratadin|desloratadin|cetirizin|fexofenadin|montelukast|salbutamol|acetylcystein|ambroxol|bromhexin|prednisolon|methylprednisolon|ibuprofen|meloxicam|celecoxib|diclofenac|amlodipin|losartan|valsartan|telmisartan|perindopril|bisoprolol|atorvastatin|rosuvastatin|metformin|gliclazid|vitamin)\b',
      caseSensitive: false,
    ).hasMatch(line);
  }
}
